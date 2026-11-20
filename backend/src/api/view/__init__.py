"""Viewer API router aggregator."""

from fastapi import APIRouter

from src.api.view.auth import router as auth_router
from src.api.view.schedules import router as schedules_router
from src.api.view.solicitations import router as solicitations_router
from src.api.view.events import router as events_router
from src.api.view.export import router as export_router
from src.api.view.calendar import router as calendar_router

viewer_router = APIRouter(prefix="/api/view")

viewer_router.include_router(auth_router, tags=["Viewer Auth"])
viewer_router.include_router(schedules_router, tags=["Viewer Schedules"])
viewer_router.include_router(solicitations_router, tags=["Viewer Solicitations"])
viewer_router.include_router(events_router, tags=["Viewer Events"])
viewer_router.include_router(export_router, tags=["Viewer Export"])
viewer_router.include_router(calendar_router, tags=["Viewer Calendar"])
