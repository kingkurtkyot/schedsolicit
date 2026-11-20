"""Owner offline sync endpoints."""

from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.sync import SyncPullResponse, SyncPushRequest, SyncPushResponse
from src.services import sync_service

router = APIRouter(prefix="/sync")


@router.post("/push", response_model=SyncPushResponse)
async def push_sync(
    req: SyncPushRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await sync_service.push_changes(db, current_user["user_id"], req.items)


@router.get("/pull", response_model=SyncPullResponse)
async def pull_sync(
    since: Optional[datetime] = Query(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await sync_service.pull_changes(db, current_user["user_id"], since)
