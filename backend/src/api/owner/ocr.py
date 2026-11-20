"""Owner OCR receipt/document processing endpoints."""

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from src.core.dependencies import get_current_user
from src.services import ocr_service

router = APIRouter(prefix="/ocr")


@router.post("/process")
async def process_ocr_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File uploaded is not an image",
        )

    content = await file.read()
    return ocr_service.process_image(content)
