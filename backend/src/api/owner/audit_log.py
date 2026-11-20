"""Owner audit log endpoints."""

from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.audit_log import AuditLogFilter, AuditLogListResponse, AuditLogResponse
from src.services import audit_service

router = APIRouter(prefix="/audit-log")


@router.get("", response_model=AuditLogListResponse)
async def get_global_activity_endpoint(
    module: Optional[str] = None,
    action: Optional[str] = None,
    item_id: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    filters = AuditLogFilter(
        module=module,
        action=action,
        item_id=item_id,
        date_from=date_from,
        date_to=date_to,
        page=page,
        per_page=per_page,
    )
    return await audit_service.get_global_activity(db, filters)


@router.get("/{item_id}", response_model=List[AuditLogResponse])
async def get_item_timeline_endpoint(
    item_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await audit_service.get_item_timeline(db, item_id)
