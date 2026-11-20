"""Viewer export endpoint: only allowed if share link has allow_export=True."""

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_viewer_context
from src.models.share_link import ShareLink
from src.schemas.export import ExportFormat, ExportRequest
from src.services import export_service

router = APIRouter(prefix="/export")


@router.get("")
async def viewer_export(
    module: str = Query("schedule", description="schedule | solicitation"),
    format: ExportFormat = Query(ExportFormat.json),
    context: dict = Depends(get_viewer_context),
    db: AsyncSession = Depends(get_db),
):
    share_link_id = context["share_link_id"]
    res = await db.execute(select(ShareLink).where(ShareLink.id == share_link_id))
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")

    if not link.allow_export:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Export is disabled for this share link",
        )

    req = ExportRequest(
        module=module,
        format=format,
        title=link.label or "Shared SchedSolicit Export",
    )

    content = await export_service.generate_export(
        db=db,
        user_id=link.user_id,
        req=req,
        privacy_controls=link.privacy_controls,
    )

    media_types = {
        ExportFormat.csv: "text/csv",
        ExportFormat.json: "application/json",
        ExportFormat.xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ExportFormat.pdf: "application/pdf",
        ExportFormat.png: "image/png",
        ExportFormat.ics: "text/calendar",
    }
    media_type = media_types.get(format, "application/octet-stream")
    filename = f"shared_{module}.{format.value}"

    return Response(
        content=content,
        media_type=media_type,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
