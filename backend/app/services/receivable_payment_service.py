# Receivable Payment Service
# Transport ERP — UPI / NEFT / RTGS / Cheque / Cash payment recording for client invoices.
#
# Uses the existing finance_service.create_ledger_entry for the double-entry ledger post.
# All DB operations run within the session provided by get_db (auto-commit / rollback).

from datetime import date as date_type, datetime
from decimal import Decimal
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.postgres.client import Client
from app.models.postgres.finance import (
    Invoice,
    InvoicePaymentStatus,
    InvoiceStatus,
    Payment,
    PaymentMethod,
    PaymentStatus,
)
from app.models.postgres.user import User
from app.schemas.payment_schemas import RecordPaymentRequest
from app.services import finance_service
from app.utils.generators import generate_payment_number


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 1 — Client UPI info
# ─────────────────────────────────────────────────────────────────────────────

async def get_client_payment_info(db: AsyncSession, client_id: int) -> dict:
    result = await db.execute(
        select(Client).where(Client.id == client_id, Client.is_deleted == False)
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    upi_id: Optional[str] = getattr(client, "upi_id", None)
    phone: Optional[str] = client.phone

    if not upi_id and not phone:
        return {"upi_available": False, "name": client.name}

    return {
        "upi_available": True,
        "upi_id": upi_id,
        "phone": phone,
        "name": client.name,
    }


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 2 — Record receivable payment  (all steps in one session = one txn)
# ─────────────────────────────────────────────────────────────────────────────

async def record_receivable_payment(
    db: AsyncSession,
    data: RecordPaymentRequest,
    user_id: int,
) -> dict:
    # ── Step 0: Load and validate invoice ───────────────────────────────────
    inv_result = await db.execute(
        select(Invoice).where(Invoice.id == data.invoice_id, Invoice.is_deleted == False)
    )
    invoice = inv_result.scalar_one_or_none()
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invoice {data.invoice_id} not found",
        )

    # Confirm client is active
    cl_result = await db.execute(
        select(Client).where(Client.id == invoice.client_id, Client.is_deleted == False)
    )
    if not cl_result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invoice's client is not active",
        )

    # ── Step 1: Business-rule validations ───────────────────────────────────
    pay_status = getattr(invoice, "payment_status", None)
    already_paid = (
        pay_status == InvoicePaymentStatus.PAID
        or invoice.status == InvoiceStatus.PAID
    )
    if already_paid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="This invoice is already fully paid",
        )

    total = Decimal(str(invoice.total_amount or 0))
    paid_so_far = Decimal(str(invoice.amount_paid or 0))
    outstanding = total - paid_so_far
    amount = Decimal(str(data.amount_paid))

    if amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="amount_paid must be greater than 0",
        )

    if amount > outstanding:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"amount_paid ₹{amount} exceeds outstanding balance ₹{outstanding} "
                f"for invoice {invoice.invoice_number}"
            ),
        )

    if data.payment_mode == "UPI" and not data.reference_number and not data.upi_txn_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="UPI payments require either a reference number or a UPI transaction ID",
        )

    if data.payment_mode in ("NEFT", "RTGS") and not data.reference_number:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"{data.payment_mode} payments require a UTR reference number",
        )

    # ── Step 2: Duplicate reference check ───────────────────────────────────
    if data.reference_number:
        dup = await db.execute(
            select(Payment).where(
                Payment.invoice_id == data.invoice_id,
                Payment.transaction_ref == data.reference_number,
                Payment.is_deleted == False,
            )
        )
        if dup.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    f"Reference number '{data.reference_number}' is already recorded "
                    f"for invoice {invoice.invoice_number}"
                ),
            )

    # ── Step 3: Create payment record ────────────────────────────────────────
    payment = Payment(
        payment_number=generate_payment_number(),
        payment_date=data.payment_date,
        payment_type="received",
        invoice_id=data.invoice_id,
        client_id=invoice.client_id,
        amount=amount,
        currency="INR",
        payment_method=PaymentMethod(data.payment_mode),
        transaction_ref=data.reference_number,
        upi_txn_id=data.upi_txn_id,
        remarks=data.notes,
        status=PaymentStatus.COMPLETED,
        net_amount=amount,
        created_by=user_id,
    )
    db.add(payment)
    await db.flush()  # get payment.id, still within session txn

    # ── Step 4: Update invoice amounts and statuses ──────────────────────────
    invoice.amount_paid = paid_so_far + amount
    invoice.amount_due = max(Decimal("0"), total - invoice.amount_paid)

    if invoice.amount_paid >= total:
        invoice.payment_status = InvoicePaymentStatus.PAID
        invoice.status = InvoiceStatus.PAID
        invoice.paid_at = datetime.utcnow()
        new_status = "PAID"
    elif invoice.amount_paid > 0:
        invoice.payment_status = InvoicePaymentStatus.PARTIAL
        invoice.status = InvoiceStatus.PARTIALLY_PAID
        new_status = "PARTIAL"
    else:
        invoice.payment_status = InvoicePaymentStatus.UNPAID
        new_status = "UNPAID"

    invoice.last_payment_at = datetime.utcnow()
    await db.flush()

    # ── Step 5: Double-entry ledger post (via existing finance_service) ──────
    entry_date = (
        data.payment_date
        if isinstance(data.payment_date, date_type)
        else date_type.today()
    )
    narration_base = (
        f"Payment received via {data.payment_mode} for {invoice.invoice_number}"
        + (f" — Ref: {data.reference_number}" if data.reference_number else "")
    )

    # Debit: Bank Account (ASSET — increases on receipt)
    await finance_service.create_ledger_entry(
        db,
        {
            "entry_date": entry_date,
            "ledger_type": "asset",
            "account_name": "Bank Account",
            "account_code": "1001",
            "invoice_id": data.invoice_id,
            "payment_id": payment.id,
            "client_id": invoice.client_id,
            "debit": float(amount),
            "credit": 0.0,
            "narration": narration_base,
            "reference_type": "payment",
            "reference_number": payment.payment_number,
        },
        user_id,
    )

    # Credit: Accounts Receivable (ASSET reducing — decreases when payment received)
    await finance_service.create_ledger_entry(
        db,
        {
            "entry_date": entry_date,
            "ledger_type": "receivable",
            "account_name": "Accounts Receivable",
            "account_code": "1200",
            "invoice_id": data.invoice_id,
            "payment_id": payment.id,
            "client_id": invoice.client_id,
            "debit": 0.0,
            "credit": float(amount),
            "narration": narration_base,
            "reference_type": "payment",
            "reference_number": payment.payment_number,
        },
        user_id,
    )

    return {
        "success": True,
        "payment_id": payment.id,
        "invoice_id": data.invoice_id,
        "new_status": new_status,
        "outstanding_balance": float(invoice.amount_due or 0),
    }


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 3 — Payment history for an invoice
# ─────────────────────────────────────────────────────────────────────────────

async def get_invoice_payments(db: AsyncSession, invoice_id: int) -> list:
    result = await db.execute(
        select(Payment).where(
            Payment.invoice_id == invoice_id,
            Payment.is_deleted == False,
            Payment.payment_type == "received",
        ).order_by(Payment.id.desc())
    )
    payments = result.scalars().all()

    rows = []
    for p in payments:
        # Fetch creator name lazily
        creator_name = None
        if p.created_by:
            u = await db.execute(
                select(User.first_name, User.last_name).where(User.id == p.created_by)
            )
            row = u.one_or_none()
            if row:
                creator_name = f"{row[0] or ''} {row[1] or ''}".strip() or None

        method_val = (
            p.payment_method.value
            if hasattr(p.payment_method, "value")
            else str(p.payment_method)
        )
        rows.append(
            {
                "payment_id": p.id,
                "amount_paid": float(p.amount or 0),
                "payment_mode": method_val,
                "reference_number": p.transaction_ref,
                "payment_date": p.payment_date.isoformat() if p.payment_date else None,
                "recorded_by_name": creator_name,
            }
        )

    return rows
