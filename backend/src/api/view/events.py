"""Viewer Server-Sent Events (SSE) stream for real-time updates."""

import asyncio
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_viewer_context
from src.models.share_link import ShareLink

router = APIRouter(prefix="/events")


@router.get("")
async def sse_events(
    context: dict = Depends(get_viewer_context),
    db: AsyncSession = Depends(get_db),
):
    share_link_id = context["share_link_id"]
    res = await db.execute(select(ShareLink).where(ShareLink.id == share_link_id))
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")

    async def event_generator():
        try:
            init_msg = json.dumps({"event": "connected", "timestamp": datetime.now(timezone.utc).isoformat()})
            yield f"data: {init_msg}\n\n"

            for _ in range(5):
                await asyncio.sleep(5)
                ping = json.dumps({"event": "ping", "timestamp": datetime.now(timezone.utc).isoformat()})
                yield f"data: {ping}\n\n"
        except asyncio.CancelledError:
            pass

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
