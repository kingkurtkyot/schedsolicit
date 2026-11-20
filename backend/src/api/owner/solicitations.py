"""Owner solicitations endpoints."""

from datetime import date
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.common import BulkActionRequest, BulkActionResponse, FilterParams, PaginationParams, SortParams
from src.schemas.solicitation import (
    SolicitationCreate,
    SolicitationGivenUpdate,
    SolicitationListResponse,
    SolicitationResponse,
    SolicitationUpdate,
)
from src.services import solicitation_service, search_service

router = APIRouter(prefix="/solicitations")


@router.get("", response_model=SolicitationListResponse)
async def list_solicitations_endpoint(
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

    return await solicitation_service.list_solicitations(
        db, current_user["user_id"], filters, pagination, sort
    )


@router.get("/search")
async def search_solicitations(
    q: str = Query(..., min_length=1),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await search_service.search_items(
        db, current_user["user_id"], module="solicitation", query=q
    )


@router.post("", response_model=SolicitationResponse, status_code=status.HTTP_201_CREATED)
async def create_solicitation_endpoint(
    data: SolicitationCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.create_solicitation(db, current_user["user_id"], data)


@router.get("/{sol_id}", response_model=SolicitationResponse)
async def get_solicitation_endpoint(
    sol_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.get_solicitation(db, current_user["user_id"], sol_id)


@router.put("/{sol_id}", response_model=SolicitationResponse)
async def update_solicitation_endpoint(
    sol_id: str,
    data: SolicitationUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.update_solicitation(db, current_user["user_id"], sol_id, data)


@router.put("/{sol_id}/given", response_model=SolicitationResponse)
async def update_given_fields_endpoint(
    sol_id: str,
    data: SolicitationGivenUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.update_given_fields(db, current_user["user_id"], sol_id, data)


@router.delete("/{sol_id}", response_model=SolicitationResponse)
async def delete_solicitation_endpoint(
    sol_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.delete_solicitation(db, current_user["user_id"], sol_id)


@router.post("/{sol_id}/restore", response_model=SolicitationResponse)
async def restore_solicitation_endpoint(
    sol_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.restore_solicitation(db, current_user["user_id"], sol_id)


@router.post("/{sol_id}/duplicate", response_model=SolicitationResponse, status_code=status.HTTP_201_CREATED)
async def duplicate_solicitation_endpoint(
    sol_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.duplicate_solicitation(db, current_user["user_id"], sol_id)


@router.post("/bulk", response_model=BulkActionResponse)
async def bulk_solicitation_action(
    req: BulkActionRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await solicitation_service.bulk_action(
        db, current_user["user_id"], req.action, req.item_ids, req.data
    )
