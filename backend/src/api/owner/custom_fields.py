"""Owner custom fields and categories endpoints."""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.models.category import Category
from src.models.custom_field import CustomField
from src.schemas.custom_field import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    CustomFieldCreate,
    CustomFieldResponse,
)

router = APIRouter()


# Custom Fields
@router.get("/custom-fields", response_model=List[CustomFieldResponse])
async def list_custom_fields(
    module: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(CustomField).where(CustomField.user_id == current_user["user_id"])
    if module:
        stmt = stmt.where(CustomField.module == module)
    stmt = stmt.order_by(CustomField.sort_order.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())


@router.post("/custom-fields", response_model=CustomFieldResponse, status_code=status.HTTP_201_CREATED)
async def create_custom_field(
    data: CustomFieldCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cf = CustomField(
        **data.model_dump(),
        user_id=current_user["user_id"],
    )
    db.add(cf)
    await db.flush()
    return cf


@router.delete("/custom-fields/{cf_id}")
async def delete_custom_field(
    cf_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(CustomField).where(
        CustomField.id == cf_id,
        CustomField.user_id == current_user["user_id"],
    )
    res = await db.execute(stmt)
    cf = res.scalar_one_or_none()
    if not cf:
        raise HTTPException(status_code=404, detail="Custom field not found")
    await db.delete(cf)
    return {"message": "Custom field deleted"}


# Categories
@router.get("/categories", response_model=List[CategoryResponse])
async def list_categories(
    module: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Category).where(Category.user_id == current_user["user_id"])
    if module:
        stmt = stmt.where(Category.module == module)
    stmt = stmt.order_by(Category.sort_order.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    data: CategoryCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cat = Category(
        **data.model_dump(),
        user_id=current_user["user_id"],
    )
    db.add(cat)
    await db.flush()
    return cat


@router.put("/categories/{cat_id}", response_model=CategoryResponse)
async def update_category(
    cat_id: str,
    data: CategoryUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Category).where(
        Category.id == cat_id,
        Category.user_id == current_user["user_id"],
    )
    res = await db.execute(stmt)
    cat = res.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")

    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(cat, k, v)
    await db.flush()
    return cat


@router.delete("/categories/{cat_id}")
async def delete_category(
    cat_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Category).where(
        Category.id == cat_id,
        Category.user_id == current_user["user_id"],
    )
    res = await db.execute(stmt)
    cat = res.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    await db.delete(cat)
    return {"message": "Category deleted"}
