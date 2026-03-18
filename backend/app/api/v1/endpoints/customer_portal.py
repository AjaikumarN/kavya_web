# Customer Portal API Endpoints
# Transport ERP — Phase D: Customer Self-Service Portal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.db.postgres.connection import get_db
from app.core.security import get_current_user, TokenData
from app.services import portal_service
from app.schemas.portal import PortalLoginRequest, BookingRequest

router = APIRouter()


@router.post("/login")
async def customer_login(
    payload: PortalLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Customer login by email — returns portal token."""
    if not payload.email:
        raise HTTPException(status_code=400, detail="Email is required")
    result = await portal_service.authenticate_customer(db, payload.email)
    if not result:
        raise HTTPException(status_code=401, detail="No customer account found with this email")
    return {"success": True, "data": result, "message": "Customer login successful"}


@router.get("/bookings")
async def list_bookings(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """List customer's bookings (jobs)."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")
    data = await portal_service.get_customer_bookings(
        db, client_id=current_user.user_id, skip=skip, limit=limit,
    )
    return {"success": True, "data": data}


@router.post("/bookings")
async def create_booking(
    payload: BookingRequest,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """Create a booking request (draft job)."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")
    result = await portal_service.create_customer_booking(
        db,
        client_id=current_user.user_id,
        origin_city=payload.origin_city,
        destination_city=payload.destination_city,
        origin_address=payload.origin_address,
        destination_address=payload.destination_address,
        pickup_date=payload.pickup_date,
        material_type=payload.material_type,
        quantity=payload.quantity,
        quantity_unit=payload.quantity_unit,
        vehicle_type_required=payload.vehicle_type_required,
        special_requirements=payload.special_requirements,
    )
    return {"success": True, "data": result, "message": "Booking request submitted"}


@router.get("/tracking/{job_id}")
async def get_tracking_link(
    job_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """Generate a public tracking link for a job."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")
    token = portal_service.generate_tracking_token(job_id, current_user.user_id)
    return {
        "success": True,
        "data": {
            "tracking_token": token,
            "tracking_url": f"/portal/track/{token}",
        },
    }


@router.get("/invoices")
async def list_invoices(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """List customer's invoices."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")
    data = await portal_service.get_customer_invoices(
        db, client_id=current_user.user_id, skip=skip, limit=limit,
    )
    return {"success": True, "data": data}


@router.get("/payments")
async def list_payments(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """List customer's payment history."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")
    data = await portal_service.get_customer_payments(
        db, client_id=current_user.user_id, skip=skip, limit=limit,
    )
    return {"success": True, "data": data}


@router.get("/pay/{invoice_id}")
async def get_payment_link(
    invoice_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """Generate a Razorpay payment link for an outstanding invoice."""
    if "customer" not in current_user.roles:
        raise HTTPException(status_code=403, detail="Customer portal access only")

    from app.models.postgres.finance import Invoice
    from app.models.postgres.client import Client
    from sqlalchemy import select

    inv_result = await db.execute(
        select(Invoice).where(Invoice.id == invoice_id, Invoice.client_id == current_user.user_id)
    )
    invoice = inv_result.scalar_one_or_none()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    due = float(invoice.amount_due or 0)
    if due <= 0:
        return {"success": True, "data": {"message": "No outstanding amount"}}

    client_result = await db.execute(select(Client).where(Client.id == current_user.user_id))
    client = client_result.scalar_one_or_none()

    from app.services import razorpay_service
    link = await razorpay_service.create_payment_link(
        amount=due,
        description=f"Invoice {invoice.invoice_number}",
        customer_name=client.name if client else "Customer",
        customer_phone=client.phone if client else "",
        customer_email=client.email if client else "",
        reference_id=f"INV-{invoice.id}",
    )
    return {"success": True, "data": link}
