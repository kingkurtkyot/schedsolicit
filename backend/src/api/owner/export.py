"""Owner export endpoints."""

from fastapi import APIRouter, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.export import ExportFormat, ExportRequest
from src.services import export_service

router = APIRouter(prefix="/export")


@router.post("")
async def generate_export_endpoint(
    req: ExportRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    content = await export_service.generate_export(db, current_user["user_id"], req)

    media_types = {
        ExportFormat.csv: "text/csv",
        ExportFormat.json: "application/json",
        ExportFormat.xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ExportFormat.pdf: "application/pdf",
        ExportFormat.png: "image/png",
        ExportFormat.ics: "text/calendar",
    }
    media_type = media_types.get(req.format, "application/octet-stream")
    filename = f"{req.module}_export.{req.format.value}"

    return Response(
        content=content,
        media_type=media_type,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
