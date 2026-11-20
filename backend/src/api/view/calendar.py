"""Viewer calendar ICS feed endpoint."""

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.models.share_link import ShareLink
from src.services import share_service

router = APIRouter(prefix="/calendar")


@router.get(".ics")
@router.get("/{token}.ics")
async def get_calendar_ics(
    token: str,
    db: AsyncSession = Depends(get_db),
):
    link = await share_service.validate_share_token(db, token)
    ics_text = await share_service.generate_ics_feed(db, link)

    return Response(
        content=ics_text,
        media_type="text/calendar",
        headers={"Content-Disposition": f'inline; filename="{link.label or "calendar"}.ics"'},
    )
