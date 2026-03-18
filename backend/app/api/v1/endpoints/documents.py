# Document Management Endpoints
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from typing import Optional

from app.db.postgres.connection import get_db
from app.core.security import TokenData, get_current_user
from app.schemas.base import APIResponse, PaginationMeta
from app.models.postgres.document import Document, EntityType, DocumentType
from app.services import s3_service

router = APIRouter()


@router.get("", response_model=APIResponse)
async def list_documents(
    page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=500),
    search: Optional[str] = None, entity_type: Optional[str] = None,
    db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user),
):
    query = select(Document).where(Document.is_deleted == False)
    count_query = select(func.count(Document.id)).where(Document.is_deleted == False)

    if search:
        sf = or_(Document.title.ilike(f"%{search}%"), Document.document_number.ilike(f"%{search}%"))
        query = query.where(sf)
        count_query = count_query.where(sf)

    if entity_type:
        query = query.where(Document.entity_type == EntityType(entity_type))
        count_query = count_query.where(Document.entity_type == EntityType(entity_type))

    total = (await db.execute(count_query)).scalar() or 0
    pages = (total + limit - 1) // limit
    offset = (page - 1) * limit
    result = await db.execute(query.offset(offset).limit(limit).order_by(Document.id.desc()))
    docs = result.scalars().all()
    items = [{c.key: getattr(d, c.key) for c in d.__table__.columns} for d in docs]
    return APIResponse(success=True, data=items, pagination=PaginationMeta(page=page, limit=limit, total=total, pages=pages))


# ── Lookup endpoints (must be before /{doc_id} to avoid path conflicts) ──
@router.get("/lookup/entities", response_model=APIResponse)
async def lookup_entities(
    entity_type: str = Query("vehicle"),
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """Lookup entities (vehicles, drivers, trips, clients) for document linking."""
    items = []
    if entity_type == "vehicle":
        from app.models.postgres.vehicle import Vehicle
        q = select(Vehicle.id, Vehicle.registration_number, Vehicle.make, Vehicle.model).where(Vehicle.is_deleted == False)
        if search:
            q = q.where(Vehicle.registration_number.ilike(f"%{search}%"))
        result = await db.execute(q.order_by(Vehicle.registration_number).limit(50))
        items = [{"id": r.id, "name": f"{r.registration_number} ({r.make} {r.model})"} for r in result.all()]
    elif entity_type == "driver":
        from app.models.postgres.driver import Driver
        q = select(Driver.id, Driver.first_name, Driver.last_name, Driver.phone, Driver.employee_code).where(Driver.is_deleted == False)
        if search:
            q = q.where(Driver.first_name.ilike(f"%{search}%"))
        result = await db.execute(q.order_by(Driver.first_name).limit(50))
        items = [{"id": r.id, "name": f"{r.first_name} {r.last_name or ''} ({r.employee_code})".strip()} for r in result.all()]
    elif entity_type == "trip":
        from app.models.postgres.trip import Trip
        q = select(Trip.id, Trip.trip_number, Trip.origin, Trip.destination).where(Trip.is_deleted == False)
        if search:
            q = q.where(Trip.trip_number.ilike(f"%{search}%"))
        result = await db.execute(q.order_by(Trip.id.desc()).limit(50))
        items = [{"id": r.id, "name": f"{r.trip_number} ({r.origin} → {r.destination})"} for r in result.all()]
    elif entity_type == "client":
        from app.models.postgres.client import Client
        q = select(Client.id, Client.name, Client.code).where(Client.is_deleted == False)
        if search:
            q = q.where(Client.name.ilike(f"%{search}%"))
        result = await db.execute(q.order_by(Client.name).limit(50))
        items = [{"id": r.id, "name": f"{r.name} ({r.code})"} for r in result.all()]
    return APIResponse(success=True, data={"items": items})


@router.get("/lookup/compliance-categories", response_model=APIResponse)
async def lookup_compliance_categories(current_user: TokenData = Depends(get_current_user)):
    categories = [
        {"value": "registration", "label": "Vehicle Registration"},
        {"value": "insurance", "label": "Insurance"},
        {"value": "fitness", "label": "Fitness Certificate"},
        {"value": "pollution", "label": "PUC / Pollution"},
        {"value": "permit", "label": "Permit"},
        {"value": "tax", "label": "Road Tax"},
        {"value": "license", "label": "Driver License"},
        {"value": "other", "label": "Other"},
    ]
    return APIResponse(success=True, data={"items": categories})


@router.get("/{doc_id}", response_model=APIResponse)
async def get_document(doc_id: int, db: AsyncSession = Depends(get_db), current_user: TokenData = Depends(get_current_user)):
    result = await db.execute(select(Document).where(Document.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return APIResponse(success=True, data={c.key: getattr(doc, c.key) for c in doc.__table__.columns})


@router.post("/upload", response_model=APIResponse, status_code=201)
async def upload_document(
    file: UploadFile = File(...),
    entity_type: str = Form("vehicle"),
    entity_id: int = Form(0),
    title: Optional[str] = Form(None),
    document_type: str = Form("other"),
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    """Upload a document file to S3/local storage."""
    from app.utils.generators import generate_number
    content = await file.read()
    folder = f"documents/{entity_type}"
    result = await s3_service.upload_file(content, file.filename, folder, file.content_type)

    doc = Document(
        doc_number=generate_number("DOC", 4),
        title=title or file.filename,
        document_type=DocumentType(document_type) if document_type in [e.value for e in DocumentType] else DocumentType.OTHER,
        entity_type=EntityType(entity_type) if entity_type in [e.value for e in EntityType] else EntityType.VEHICLE,
        entity_id=entity_id,
        file_url=result.get("url", ""),
        file_name=file.filename,
        file_size=len(content),
        file_type=file.content_type,
        uploaded_by=current_user.user_id,
    )
    db.add(doc)
    await db.commit()
    await db.refresh(doc)

    return APIResponse(
        success=True,
        data={"id": doc.id, "url": result.get("url"), "source": result.get("source")},
        message="Document uploaded successfully",
    )


@router.delete("/{doc_id}", response_model=APIResponse)
async def delete_document(
    doc_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: TokenData = Depends(get_current_user),
):
    result = await db.execute(select(Document).where(Document.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.is_deleted = True
    await db.commit()
    if doc.file_key:
        await s3_service.delete_file(doc.file_key)
    return APIResponse(success=True, message="Document deleted")
