"""Owner schedules endpoints."""

from datetime import date
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.common import BulkActionRequest, BulkActionResponse, FilterParams, PaginationParams, SortParams
from src.schemas.schedule import (
    ScheduleCreate,
    ScheduleListResponse,
    ScheduleResponse,
    ScheduleUpdate,
)
from src.services import schedule_service, search_service

router = APIRouter(prefix="/schedules")


@router.get("", response_model=ScheduleListResponse)
async def list_schedules_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    priority: Optional[str] = None,
    category: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    search: Optional[str] = None,
    is_deleted: bool = False,
    sort_by: str = "created_at",
    sort_desc: bool = True,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    filters = FilterParams(
        status=status,
        priority=priority,
        category=category,
        date_from=date_from,
        date_to=date_to,
        search=search,
        is_deleted=is_deleted,
    )
    pagination = PaginationParams(page=page, per_page=per_page)
    sort = SortParams(sort_by=sort_by, sort_desc=sort_desc)

    return await schedule_service.list_schedules(
        db, current_user["user_id"], filters, pagination, sort
    )


@router.get("/search")
async def search_schedules(
    q: str = Query(..., min_length=1),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await search_service.search_items(
        db, current_user["user_id"], module="schedule", query=q
    )


@router.post("", response_model=ScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_schedule_endpoint(
    data: ScheduleCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.create_schedule(db, current_user["user_id"], data)


@router.get("/{schedule_id}", response_model=ScheduleResponse)
async def get_schedule_endpoint(
    schedule_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.get_schedule(db, current_user["user_id"], schedule_id)


@router.put("/{schedule_id}", response_model=ScheduleResponse)
async def update_schedule_endpoint(
    schedule_id: str,
    data: ScheduleUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.update_schedule(db, current_user["user_id"], schedule_id, data)


@router.delete("/{schedule_id}", response_model=ScheduleResponse)
async def delete_schedule_endpoint(
    schedule_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.delete_schedule(db, current_user["user_id"], schedule_id)


@router.post("/{schedule_id}/restore", response_model=ScheduleResponse)
async def restore_schedule_endpoint(
    schedule_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.restore_schedule(db, current_user["user_id"], schedule_id)


@router.post("/{schedule_id}/duplicate", response_model=ScheduleResponse, status_code=status.HTTP_201_CREATED)
async def duplicate_schedule_endpoint(
    schedule_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.duplicate_schedule(db, current_user["user_id"], schedule_id)


@router.post("/bulk", response_model=BulkActionResponse)
async def bulk_schedule_action(
    req: BulkActionRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await schedule_service.bulk_action(
        db, current_user["user_id"], req.action, req.item_ids, req.data
    )
