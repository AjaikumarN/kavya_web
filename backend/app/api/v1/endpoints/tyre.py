from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import TokenData, get_current_user
from app.db.postgres.connection import get_db
from app.middleware.permissions import Permissions, require_permission
from app.models.postgres.vehicle import Vehicle, VehicleTyre
from app.schemas.base import APIResponse, PaginationMeta
from app.schemas.tyre import TyreCreate, TyreEvent, TyreUpdate

router = APIRouter()


@router.get("", response_model=APIResponse)
async def list_tyres(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=500),
    vehicle_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    _user: TokenData = Depends(require_permission(Permissions.VEHICLE_READ)),
):
    query = select(VehicleTyre, Vehicle.registration_number).join(Vehicle, Vehicle.id == VehicleTyre.vehicle_id)
    count_query = select(func.count(VehicleTyre.id))

    query = query.where(VehicleTyre.is_active == True)
    count_query = count_query.where(VehicleTyre.is_active == True)

    if vehicle_id:
        query = query.where(VehicleTyre.vehicle_id == vehicle_id)
        count_query = count_query.where(VehicleTyre.vehicle_id == vehicle_id)

    total = (await db.execute(count_query)).scalar() or 0
    offset = max(page - 1, 0) * limit
    result = await db.execute(query.order_by(VehicleTyre.id.desc()).offset(offset).limit(limit))

    items = []
    good_count = fair_count = replace_soon_count = critical_count = 0
    for tyre, reg_no in result.all():
        condition = str(tyre.condition or "good").lower()
        purchase_cost = float(tyre.purchase_cost or 0)
        current_km = float(tyre.current_km or 0)
        installed_km = float(tyre.km_at_fitment or 0)
        km_run = float(current_km - installed_km)
        # Estimate tread depth based on condition (mm)
        tread = 8.0 if condition == 'new' else (6.5 if condition == 'good' else (4.5 if condition == 'average' else 2.5))
        if condition in ('new', 'good'):
            good_count += 1
        elif condition == 'average':
            fair_count += 1
        elif condition == 'worn':
            replace_soon_count += 1
        else:
            critical_count += 1

        items.append({
            "id": tyre.id,
            "serial_number": tyre.tyre_number,
            "brand": tyre.brand,
            "model": tyre.size or "",
            "size": tyre.size,
            "purchase_date": tyre.purchase_date,
            "installed_date": (tyre.purchase_date.isoformat() if tyre.purchase_date else None),
            "cost": purchase_cost,
            "vehicle_id": tyre.vehicle_id,
            "vehicle_number": reg_no,
            "vehicle": reg_no,
            "axle_position": tyre.position,
            "position": tyre.position,
            "status": condition.upper(),
            "condition": condition,
            "total_km": current_km,
            "current_km": current_km,
            "installed_km": installed_km,
            "km_run": km_run,
            "tread_depth_mm": tread,
            "cost_per_km": float(purchase_cost / max(km_run, 1.0)) if km_run > 0 else 0,
        })

    pages = (total + limit - 1) // limit
    return APIResponse(success=True, data={
        "items": items,
        "summary": {
            "total_tyres": total,
            "good": good_count,
            "fair": fair_count,
            "replace_soon": replace_soon_count,
            "critical": critical_count,
        },
    }, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


@router.post("", response_model=APIResponse, status_code=201)
async def create_tyre(
    data: TyreCreate,
    db: AsyncSession = Depends(get_db),
    _user: TokenData = Depends(require_permission(Permissions.VEHICLE_UPDATE)),
):
    tyre = VehicleTyre(
        vehicle_id=data.vehicle_id,
        tyre_number=data.serial_number,
        position=data.axle_position,
        brand=data.brand,
        size=data.size,
        purchase_date=data.purchase_date,
        purchase_cost=data.cost or 0,
        condition=str(data.status).lower(),
        is_active=True,
    )
    db.add(tyre)
    await db.commit()
    await db.refresh(tyre)
    return APIResponse(success=True, data={"id": tyre.id}, message="Tyre created")


@router.put("/{tyre_id}", response_model=APIResponse)
async def update_tyre(
    tyre_id: int,
    data: TyreUpdate,
    db: AsyncSession = Depends(get_db),
    _user: TokenData = Depends(require_permission(Permissions.VEHICLE_UPDATE)),
):
    tyre = await db.get(VehicleTyre, tyre_id)
    if not tyre or not tyre.is_active:
        raise HTTPException(status_code=404, detail="Tyre not found")

    payload = data.model_dump(exclude_unset=True)
    field_map = {
        "serial_number": "tyre_number",
        "axle_position": "position",
        "cost": "purchase_cost",
        "status": "condition",
    }
    for key, value in payload.items():
        attr = field_map.get(key, key)
        if attr == "condition" and value is not None:
            value = str(value).lower()
        setattr(tyre, attr, value)

    await db.commit()
    return APIResponse(success=True, message="Tyre updated")


@router.delete("/{tyre_id}", response_model=APIResponse)
async def delete_tyre(
    tyre_id: int,
    db: AsyncSession = Depends(get_db),
    _user: TokenData = Depends(require_permission(Permissions.VEHICLE_UPDATE)),
):
    tyre = await db.get(VehicleTyre, tyre_id)
    if not tyre or not tyre.is_active:
        raise HTTPException(status_code=404, detail="Tyre not found")
    tyre.is_active = False
    await db.commit()
    return APIResponse(success=True, message="Tyre deleted")


@router.post("/{tyre_id}/event", response_model=APIResponse)
async def log_tyre_event(
    tyre_id: int,
    data: TyreEvent,
    db: AsyncSession = Depends(get_db),
    _user: TokenData = Depends(require_permission(Permissions.VEHICLE_UPDATE)),
):
    tyre = await db.get(VehicleTyre, tyre_id)
    if not tyre or not tyre.is_active:
        raise HTTPException(status_code=404, detail="Tyre not found")

    tyre.current_km = data.odometer
    event = str(data.event_type).upper()
    if event == "REMOVED":
        tyre.condition = "removed"
    elif event in ("SCRAPPED", "SCRAP"):
        tyre.condition = "scrapped"
        tyre.is_active = False
    elif event in ("RETREADED", "RETREADING"):
        tyre.condition = "retreading"
    else:
        tyre.condition = "mounted"

    await db.commit()
    return APIResponse(success=True, data={"tyre_id": tyre_id, "event_type": event, "odometer": data.odometer, "reason": data.reason, "logged_at": datetime.utcnow().isoformat()}, message="Tyre event logged")
