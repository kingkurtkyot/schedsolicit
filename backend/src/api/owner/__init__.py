"""Owner API router aggregator."""

from fastapi import APIRouter

from src.api.owner.auth import router as auth_router
from src.api.owner.schedules import router as schedules_router
from src.api.owner.solicitations import router as solicitations_router
from src.api.owner.custom_fields import router as custom_fields_router
from src.api.owner.audit_log import router as audit_router
from src.api.owner.sharing import router as sharing_router
from src.api.owner.sync import router as sync_router
from src.api.owner.export import router as export_router
from src.api.owner.ml import router as ml_router
from src.api.owner.ocr import router as ocr_router

owner_router = APIRouter(prefix="/api/owner")

owner_router.include_router(auth_router, tags=["Owner Auth"])
owner_router.include_router(schedules_router, tags=["Owner Schedules"])
owner_router.include_router(solicitations_router, tags=["Owner Solicitations"])
owner_router.include_router(custom_fields_router, tags=["Owner Custom Fields"])
owner_router.include_router(audit_router, tags=["Owner Audit Log"])
owner_router.include_router(sharing_router, tags=["Owner Sharing"])
owner_router.include_router(sync_router, tags=["Owner Sync"])
owner_router.include_router(export_router, tags=["Owner Export"])
owner_router.include_router(ml_router, tags=["Owner ML"])
owner_router.include_router(ocr_router, tags=["Owner OCR"])
