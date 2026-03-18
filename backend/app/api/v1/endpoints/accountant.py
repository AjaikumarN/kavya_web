# Accountant Module Endpoints
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import date, datetime, timedelta

from sqlalchemy import select

from app.db.postgres.connection import get_db
from app.core.security import TokenData, get_current_user
from app.middleware.permissions import require_permission, Permissions
from app.schemas.base import APIResponse, PaginationMeta
from app.services import dashboard_service, finance_service
from app.models.postgres.trip import TripExpense, ExpenseCategory

router = APIRouter()


def _role_set(user: TokenData) -> set[str]:
    return {str(r).lower() for r in (user.roles or [])}


def _is_admin_or_accountant(user: TokenData) -> bool:
    roles = _role_set(user)
    return "admin" in roles or "accountant" in roles


def _expense_category_value(expense: TripExpense) -> str:
    raw = getattr(expense, "category", None)
    return str(getattr(raw, "value", raw) or "").lower()


@router.get("/dashboard", response_model=APIResponse)
async def accountant_dashboard(db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user)):
    data = await dashboard_service.get_accountant_dashboard(db)
    return APIResponse(success=True, data=data)


@router.get("/invoices", response_model=APIResponse)
async def accountant_invoices(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=500),
    search: Optional[str] = None, status: Optional[str] = None,
    client_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.INVOICE_READ)),
):
    invoices, total = await finance_service.list_invoices(db, page, limit, search, status, client_id)
    pages = (total + limit - 1) // limit
    items = []
    for inv in invoices:
        items.append(await finance_service.get_invoice_with_details(db, inv))
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.get("/payments", response_model=APIResponse)
async def accountant_payments(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=500),
    payment_type: Optional[str] = None, client_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.PAYMENT_READ)),
):
    payments, total = await finance_service.list_payments(db, page, limit, payment_type, client_id)
    pages = (total + limit - 1) // limit
    items = [{c.key: getattr(p, c.key) for c in p.__table__.columns} for p in payments]
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.get("/ledger", response_model=APIResponse)
async def accountant_ledger(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=500),
    ledger_type: Optional[str] = None, client_id: Optional[int] = None,
    date_from: Optional[date] = None, date_to: Optional[date] = None,
    db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.LEDGER_READ)),
):
    entries, total = await finance_service.list_ledger(db, page, limit, ledger_type, client_id, date_from, date_to)
    pages = (total + limit - 1) // limit
    items = [{c.key: getattr(e, c.key) for c in e.__table__.columns} for e in entries]
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.get("/receivables", response_model=APIResponse)
async def accountant_receivables(
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.INVOICE_READ)),
):
    from sqlalchemy import select, func, case, and_
    from app.models.postgres.finance import Invoice, InvoiceStatus
    from app.models.postgres.client import Client

    today = date.today()
    d30 = today - timedelta(days=30)
    d60 = today - timedelta(days=60)
    d90 = today - timedelta(days=90)

    result = await db.execute(
        select(
            Client.id, Client.name, Client.code,
            func.sum(Invoice.amount_due).label("total_due"),
            func.count(Invoice.id).label("invoice_count"),
            func.min(Invoice.due_date).label("oldest_due"),
            func.coalesce(func.sum(case((Invoice.due_date >= d30, Invoice.amount_due), else_=0)), 0).label("aging_0_30"),
            func.coalesce(func.sum(case((and_(Invoice.due_date < d30, Invoice.due_date >= d60), Invoice.amount_due), else_=0)), 0).label("aging_31_60"),
            func.coalesce(func.sum(case((and_(Invoice.due_date < d60, Invoice.due_date >= d90), Invoice.amount_due), else_=0)), 0).label("aging_61_90"),
            func.coalesce(func.sum(case((Invoice.due_date < d90, Invoice.amount_due), else_=0)), 0).label("aging_over_90"),
        )
        .join(Invoice, Invoice.client_id == Client.id)
        .where(Invoice.is_deleted == False, Invoice.amount_due > 0, Invoice.status != InvoiceStatus.CANCELLED)
        .group_by(Client.id, Client.name, Client.code)
        .order_by(func.sum(Invoice.amount_due).desc())
    )
    items = []
    for r in result.all():
        oldest_due = r[5]
        aging_days = max(0, (today - oldest_due).days) if oldest_due else 0
        items.append({
            "client_id": r[0],
            "client_name": r[1],
            "client_code": r[2],
            "total_due": float(r[3]),
            "invoice_count": r[4],
            "oldest_due": oldest_due.isoformat() if oldest_due else None,
            "aging_days": aging_days,
            "aging_0_30": float(r[6] or 0),
            "aging_31_60": float(r[7] or 0),
            "aging_61_90": float(r[8] or 0),
            "aging_over_90": float(r[9] or 0),
        })
    return APIResponse(success=True, data=items)


@router.get("/expenses", response_model=APIResponse)
async def accountant_expenses(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=500),
    verified: Optional[bool] = None,
    db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.EXPENSE_READ)),
):
    from sqlalchemy import select, func
    from app.models.postgres.trip import TripExpense

    query = select(TripExpense)
    count_query = select(func.count(TripExpense.id))

    if verified is not None:
        query = query.where(TripExpense.is_verified == verified)
        count_query = count_query.where(TripExpense.is_verified == verified)

    total = (await db.execute(count_query)).scalar() or 0
    pages = (total + limit - 1) // limit
    offset = (page - 1) * limit
    result = await db.execute(query.offset(offset).limit(limit).order_by(TripExpense.expense_date.desc()))
    expenses = result.scalars().all()
    items = [{c.key: getattr(e, c.key) for c in e.__table__.columns} for e in expenses]
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.put("/expenses/{expense_id}", response_model=APIResponse)
async def accountant_update_expense(
    expense_id: int,
    payload: dict,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.EXPENSE_UPDATE)),
):
    expense = await db.get(TripExpense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    roles = _role_set(current_user)
    is_finance_owner = _is_admin_or_accountant(current_user)
    category = _expense_category_value(expense)

    if expense.is_verified and not is_finance_owner:
        raise HTTPException(status_code=403, detail="Finalized expenses cannot be edited")

    if "fleet_manager" in roles:
        if category not in {"fuel", "repair", "vehicle_maintenance"}:
            raise HTTPException(status_code=403, detail="Fleet manager can only edit fuel/maintenance expenses")

    allowed_fields = {"amount", "description", "payment_mode", "reference_number", "receipt_url", "verification_remarks", "expense_date", "category", "sub_category", "location"}
    updates = {k: v for k, v in (payload or {}).items() if k in allowed_fields}

    if "category" in updates and updates["category"] is not None:
        updates["category"] = ExpenseCategory(str(updates["category"]).lower())
    if "expense_date" in updates and updates["expense_date"]:
        if isinstance(updates["expense_date"], str):
            updates["expense_date"] = datetime.fromisoformat(updates["expense_date"].replace("Z", "+00:00")).replace(tzinfo=None)

    for key, value in updates.items():
        setattr(expense, key, value)

    await db.commit()
    return APIResponse(success=True, message="Expense updated")


@router.delete("/expenses/{expense_id}", response_model=APIResponse)
async def accountant_delete_expense(
    expense_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.EXPENSE_DELETE)),
):
    expense = await db.get(TripExpense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    roles = _role_set(current_user)
    is_finance_owner = _is_admin_or_accountant(current_user)

    if expense.is_verified and not is_finance_owner:
        raise HTTPException(status_code=403, detail="Approved expenses cannot be deleted")
    if "fleet_manager" in roles and not is_finance_owner:
        raise HTTPException(status_code=403, detail="Fleet manager cannot delete expenses")

    await db.delete(expense)
    await db.commit()
    return APIResponse(success=True, message="Expense deleted")


@router.put("/expenses/{expense_id}/approve", response_model=APIResponse)
async def accountant_approve_expense(
    expense_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.EXPENSE_APPROVE)),
):
    if not _is_admin_or_accountant(current_user):
        raise HTTPException(status_code=403, detail="Only accountant/admin can approve expenses")

    expense = await db.get(TripExpense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    expense.is_verified = True
    expense.verified_by = current_user.user_id
    expense.verified_at = datetime.utcnow()
    await finance_service.post_expense_approval_entries(db, expense, current_user.user_id)
    await db.commit()
    return APIResponse(success=True, message="Expense approved")


@router.put("/expenses/{expense_id}/reject", response_model=APIResponse)
async def accountant_reject_expense(
    expense_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.EXPENSE_APPROVE)),
):
    if not _is_admin_or_accountant(current_user):
        raise HTTPException(status_code=403, detail="Only accountant/admin can reject expenses")

    expense = await db.get(TripExpense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    expense.is_verified = False
    expense.verified_by = current_user.user_id
    expense.verified_at = datetime.utcnow()
    expense.verification_remarks = "Rejected"
    await db.commit()
    return APIResponse(success=True, message="Expense rejected")


@router.get("/banking", response_model=APIResponse)
async def accountant_banking(
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission([Permissions.PAYMENT_READ, Permissions.LEDGER_READ])),
):
    accounts = await finance_service.list_bank_accounts(db)
    items = [{c.key: getattr(a, c.key) for c in a.__table__.columns} for a in accounts]
    return APIResponse(success=True, data=items)
