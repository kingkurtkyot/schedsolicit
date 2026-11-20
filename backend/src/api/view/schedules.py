"""Viewer scoped and stripped schedule endpoints."""

from typing import Any, Dict, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_viewer_context
from src.models.share_link import ShareLink
from src.services import share_service
from src.utils.field_stripper import strip_fields

router = APIRouter(prefix="/schedules")


@router.get("", response_model=List[Dict[str, Any]])
async def list_viewer_schedules(
    context: dict = Depends(get_viewer_context),
    db: AsyncSession = Depends(get_db),
):
    share_link_id = context["share_link_id"]
    res = await db.execute(select(ShareLink).where(ShareLink.id == share_link_id))
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")

    items = await share_service.get_scoped_items(db, link, module="schedule")
    privacy = link.privacy_controls or {}
    return strip_fields(items, privacy)


@router.get("/{schedule_id}", response_model=Dict[str, Any])
async def get_viewer_schedule(
    schedule_id: str,
    context: dict = Depends(get_viewer_context),
    db: AsyncSession = Depends(get_db),
):
    share_link_id = context["share_link_id"]
    res = await db.execute(select(ShareLink).where(ShareLink.id == share_link_id))
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")

    items = await share_service.get_scoped_items(db, link, module="schedule")
    target = next((it for it in items if it["id"] == schedule_id), None)
    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Schedule item not found or out of scope",
        )

    privacy = link.privacy_controls or {}
    return strip_fields(target, privacy)
