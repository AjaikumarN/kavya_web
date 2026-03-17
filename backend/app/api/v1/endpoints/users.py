# User Management Endpoints
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from typing import Optional

from app.db.postgres.connection import get_db
from app.core.security import TokenData, get_current_user
from app.middleware.permissions import require_permission, Permissions
from app.schemas.base import APIResponse, PaginationMeta
from app.schemas.user import UserCreate, UserUpdate
from app.services import user_service
from app.models.postgres.user import User

router = APIRouter()


@router.get("", response_model=APIResponse)
async def list_users(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.USER_READ)),
):
    users, total = await user_service.list_users(db, page, limit, search)
    pages = (total + limit - 1) // limit
    items = []
    for u in users:
        roles = await user_service.get_user_roles(db, u.id)
        items.append({
            "id": u.id, "email": u.email, "first_name": u.first_name,
            "last_name": u.last_name, "phone": u.phone, "roles": roles,
            "is_active": u.is_active,
            "last_login": str(u.last_login) if u.last_login else None,
            "created_at": str(u.created_at) if u.created_at else None,
        })
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.get("/{user_id}", response_model=APIResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user)):
    user = await user_service.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    roles = await user_service.get_user_roles(db, user.id)
    return APIResponse(success=True, data={
        "id": user.id, "email": user.email, "first_name": user.first_name,
        "last_name": user.last_name, "phone": user.phone, "roles": roles,
        "is_active": user.is_active, "created_at": str(user.created_at) if user.created_at else None,
    })


@router.post("", response_model=APIResponse, status_code=201)
async def create_user(
    data: UserCreate, db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.USER_CREATE)),
):
    from app.services.auth_service import get_user_by_email
    existing = await get_user_by_email(db, data.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    normalized_phone = (data.phone or "").strip() or None
    if normalized_phone:
        existing_phone = await db.execute(select(User.id).where(User.phone == normalized_phone))
        if existing_phone.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Phone number already registered")

    try:
        user = await user_service.create_user(db, data.model_dump())
    except IntegrityError as exc:
        msg = str(exc).lower()
        if "ix_users_phone" in msg or "users_phone_key" in msg:
            raise HTTPException(status_code=400, detail="Phone number already registered")
        raise HTTPException(status_code=400, detail="Unable to create user due to conflicting data")
    return APIResponse(success=True, data={"id": user.id, "email": user.email}, message="User created")


@router.put("/{user_id}", response_model=APIResponse)
async def update_user(
    user_id: int, data: UserUpdate, db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.USER_UPDATE)),
):
    payload = data.model_dump(exclude_unset=True)
    normalized_phone = None
    if "phone" in payload:
        normalized_phone = (payload.get("phone") or "").strip() or None
        if normalized_phone:
            existing_phone = await db.execute(select(User.id).where(User.phone == normalized_phone, User.id != user_id))
            if existing_phone.scalar_one_or_none():
                raise HTTPException(status_code=400, detail="Phone number already registered")

    try:
        user = await user_service.update_user(db, user_id, payload)
    except IntegrityError as exc:
        msg = str(exc).lower()
        if "ix_users_phone" in msg or "users_phone_key" in msg:
            raise HTTPException(status_code=400, detail="Phone number already registered")
        raise HTTPException(status_code=400, detail="Unable to update user due to conflicting data")
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return APIResponse(success=True, message="User updated")


@router.delete("/{user_id}", response_model=APIResponse)
async def delete_user(
    user_id: int, db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
    _perm=Depends(require_permission(Permissions.USER_DELETE)),
):
    if user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    success = await user_service.delete_user(db, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return APIResponse(success=True, message="User deactivated")
