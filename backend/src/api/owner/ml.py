"""Owner ML categorizer and insights endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.services import ml_service

router = APIRouter(prefix="/ml")


@router.post("/{module}/retrain")
async def retrain_model(
    module: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ml_service.train_model(db, current_user["user_id"], module)


@router.get("/{module}/suggest")
async def get_suggestions(
    module: str,
    text: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    defaults = await ml_service.get_smart_defaults(db, current_user["user_id"], module)
    predicted_category = None
    if text:
        predicted_category = await ml_service.predict_category(db, current_user["user_id"], module, text)

    return {
        "smart_defaults": defaults,
        "suggested_category": predicted_category,
    }


@router.get("/{module}/insights")
async def get_insights(
    module: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ml_service.get_insights(db, current_user["user_id"], module)


@router.post("/{module}/reset")
async def reset_learning(
    module: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await ml_service.reset_learning(db, current_user["user_id"], module)
    return {"message": f"ML learning data reset for {module}"}
