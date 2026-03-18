# Payment Automation Service — payment links, webhook processing, reconciliation
# Transport ERP

import hmac
import hashlib
import logging
from datetime import datetime, date
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.models.postgres.finance import Invoice, InvoiceStatus, Payment, PaymentStatus, PaymentMethod
from app.models.postgres.finance_automation import (
    PaymentLink, PaymentLinkStatus,
    FinanceAlert, FinanceAlertType, FinanceAlertSeverity,
)
from app.models.postgres.client import Client
from app.utils.generators import generate_payment_number
from app.core.config import settings

logger = logging.getLogger(__name__)

LARGE_PAYMENT_THRESHOLD = Decimal("500000")  # ₹5 lakh


async def create_payment_link_for_invoice(
    db: AsyncSession, invoice_id: int, user_id: int = None
) -> PaymentLink | None:
    """
    Group 2.1 — Auto-send Razorpay payment link for an invoice.
    Creates the link via Razorpay API and stores tracking record.
    """
    invoice = await db.get(Invoice, invoice_id)
    if not invoice or invoice.status in (InvoiceStatus.PAID, InvoiceStatus.CANCELLED):
        return None

    client = await db.get(Client, invoice.client_id)
    if not client:
        return None

    amount = float(invoice.amount_due or invoice.total_amount or 0)
    if amount <= 0:
        return None

    # Call Razorpay
    from app.services.razorpay_service import create_payment_link as rz_create
    try:
        rz_result = await rz_create(
            amount=amount,
            description=f"Invoice {invoice.invoice_number}",
            customer_name=client.name or "Customer",
            customer_phone=client.phone or "",
            customer_email=client.email or "",
            reference_id=invoice.invoice_number,
        )
    except Exception as e:
        logger.error(f"Razorpay payment link creation failed: {e}")
        alert = FinanceAlert(
            alert_type=FinanceAlertType.PAYMENT_FAILED,
            severity=FinanceAlertSeverity.WARNING,
            title=f"Payment link creation failed for {invoice.invoice_number}",
            message=str(e)[:500],
            invoice_id=invoice_id,
            client_id=invoice.client_id,
        )
        db.add(alert)
        await db.flush()
        return None

    link = PaymentLink(
        link_id=rz_result.get("link_id", ""),
        short_url=rz_result.get("short_url", ""),
        invoice_id=invoice_id,
        client_id=invoice.client_id,
        amount=Decimal(str(amount)),
        description=f"Invoice {invoice.invoice_number}",
        customer_name=client.name,
        customer_phone=client.phone,
        customer_email=client.email,
        status=PaymentLinkStatus.CREATED,
        send_count=1,
        last_sent_at=datetime.utcnow(),
        sent_via="email,sms",
        tenant_id=invoice.tenant_id,
        branch_id=invoice.branch_id,
        created_by=user_id,
    )
    db.add(link)

    # Update invoice status to SENT
    if invoice.status == InvoiceStatus.DRAFT:
        invoice.status = InvoiceStatus.SENT

    await db.flush()
    logger.info(f"Payment link created: {link.link_id} for invoice {invoice.invoice_number}")
    return link


async def process_razorpay_webhook(db: AsyncSession, event: str, payload: dict) -> dict:
    """
    Group 2.2 — Process Razorpay webhook events.
    Handles: payment_link.paid, payment.captured, payment.failed, refund.processed
    """
    result = {"processed": False, "event": event}

    if event == "payment_link.paid":
        link_entity = payload.get("payment_link", {}).get("entity", {})
        link_id = link_entity.get("id")
        rz_payment_id = link_entity.get("payments", [{}])[0].get("payment_id") if link_entity.get("payments") else None
        amount_paise = link_entity.get("amount_paid", 0)
        amount = Decimal(str(amount_paise)) / 100

        # Find our payment link record
        link_result = await db.execute(
            select(PaymentLink).where(PaymentLink.link_id == link_id)
        )
        link = link_result.scalar_one_or_none()
        if link:
            link.status = PaymentLinkStatus.PAID
            link.razorpay_payment_id = rz_payment_id
            link.paid_at = datetime.utcnow()

            # Auto-create payment record
            if link.invoice_id:
                payment = Payment(
                    payment_number=generate_payment_number(),
                    payment_date=date.today(),
                    payment_type="received",
                    invoice_id=link.invoice_id,
                    client_id=link.client_id,
                    amount=amount,
                    currency="INR",
                    payment_method=PaymentMethod.UPI,
                    transaction_ref=rz_payment_id or link_id,
                    status=PaymentStatus.COMPLETED,
                    net_amount=amount,
                    remarks=f"Razorpay payment via link {link_id}",
                    tenant_id=link.tenant_id,
                    branch_id=link.branch_id,
                )
                db.add(payment)
                await db.flush()

                # Update invoice
                from app.services.finance_service import recalculate_invoice_on_payment
                await recalculate_invoice_on_payment(db, link.invoice_id)

                # Large payment alert
                if amount >= LARGE_PAYMENT_THRESHOLD:
                    alert = FinanceAlert(
                        alert_type=FinanceAlertType.LARGE_PAYMENT,
                        severity=FinanceAlertSeverity.INFO,
                        title=f"Large payment received: ₹{amount}",
                        message=f"Payment via Razorpay link {link_id} for invoice {link.invoice_id}",
                        payment_id=payment.id,
                        client_id=link.client_id,
                        tenant_id=link.tenant_id,
                    )
                    db.add(alert)

            result["processed"] = True

    elif event == "payment.captured":
        payment_entity = payload.get("payment", {}).get("entity", {})
        rz_payment_id = payment_entity.get("id")
        amount_paise = payment_entity.get("amount", 0)
        amount = Decimal(str(amount_paise)) / 100
        notes = payment_entity.get("notes", {})
        invoice_number = notes.get("invoice_number")

        if invoice_number:
            inv_result = await db.execute(
                select(Invoice).where(Invoice.invoice_number == invoice_number)
            )
            invoice = inv_result.scalar_one_or_none()
            if invoice:
                payment = Payment(
                    payment_number=generate_payment_number(),
                    payment_date=date.today(),
                    payment_type="received",
                    invoice_id=invoice.id,
                    client_id=invoice.client_id,
                    amount=amount,
                    payment_method=PaymentMethod.UPI,
                    transaction_ref=rz_payment_id,
                    status=PaymentStatus.COMPLETED,
                    net_amount=amount,
                    remarks=f"Razorpay payment {rz_payment_id}",
                    tenant_id=invoice.tenant_id,
                    branch_id=invoice.branch_id,
                )
                db.add(payment)
                await db.flush()
                from app.services.finance_service import recalculate_invoice_on_payment
                await recalculate_invoice_on_payment(db, invoice.id)
                result["processed"] = True

    elif event == "payment.failed":
        payment_entity = payload.get("payment", {}).get("entity", {})
        rz_payment_id = payment_entity.get("id")
        error = payload.get("payment", {}).get("entity", {}).get("error_description", "Unknown error")

        alert = FinanceAlert(
            alert_type=FinanceAlertType.PAYMENT_FAILED,
            severity=FinanceAlertSeverity.WARNING,
            title=f"Payment failed: {rz_payment_id}",
            message=f"Error: {error[:500]}",
        )
        db.add(alert)
        result["processed"] = True

    await db.flush()
    return result


def verify_razorpay_webhook_signature(body: bytes, signature: str) -> bool:
    """Verify Razorpay webhook signature using HMAC-SHA256."""
    secret = settings.RAZORPAY_KEY_SECRET
    if not secret:
        return False
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


async def list_payment_links(
    db: AsyncSession, invoice_id: int = None, status: str = None,
    page: int = 1, limit: int = 20,
) -> tuple:
    """List payment links with optional filters."""
    query = select(PaymentLink).where(PaymentLink.is_deleted == False)
    count_query = select(func.count(PaymentLink.id)).where(PaymentLink.is_deleted == False)

    if invoice_id:
        query = query.where(PaymentLink.invoice_id == invoice_id)
        count_query = count_query.where(PaymentLink.invoice_id == invoice_id)
    if status:
        query = query.where(PaymentLink.status == PaymentLinkStatus[status.upper()])
        count_query = count_query.where(PaymentLink.status == PaymentLinkStatus[status.upper()])

    total = (await db.execute(count_query)).scalar() or 0
    offset = (page - 1) * limit
    result = await db.execute(query.offset(offset).limit(limit).order_by(PaymentLink.id.desc()))
    return result.scalars().all(), total


async def resend_payment_link(db: AsyncSession, link_id: int) -> PaymentLink | None:
    """Group 2.3 — Resend payment link (increment send_count)."""
    link = await db.get(PaymentLink, link_id)
    if not link or link.status in (PaymentLinkStatus.PAID, PaymentLinkStatus.CANCELLED):
        return None

    link.send_count = (link.send_count or 0) + 1
    link.last_sent_at = datetime.utcnow()
    link.status = PaymentLinkStatus.SENT
    await db.flush()

    # In production: re-send link via WhatsApp/Email
    logger.info(f"Resent payment link {link.link_id} (count: {link.send_count})")
    return link
