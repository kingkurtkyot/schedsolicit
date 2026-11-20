"""Solicitation CRUD, given_* tracking, and deadline logic."""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import math

from fastapi import HTTPException, status
from sqlalchemy import desc, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.solicitation import Solicitation
from src.schemas.solicitation import (
    SolicitationCreate,
    SolicitationUpdate,
    SolicitationGivenUpdate,
)
from src.schemas.common import FilterParams, PaginationParams, SortParams
from src.services import audit_service


async def list_solicitations(
    db: AsyncSession,
    user_id: str,
    filters: FilterParams,
    pagination: PaginationParams,
    sort: SortParams,
) -> Dict[str, Any]:
    """List solicitations with filtering, sorting, and pagination."""
    query = select(Solicitation).where(
        Solicitation.user_id == str(user_id),
        Solicitation.is_deleted == filters.is_deleted,
    )

    if filters.status:
        query = query.where(Solicitation.status == filters.status)
    if filters.priority:
        query = query.where(Solicitation.priority == filters.priority)
    if filters.category:
        query = query.where(Solicitation.category == filters.category)
    if filters.date_from:
        query = query.where(Solicitation.requested_date >= filters.date_from)
    if filters.date_to:
        query = query.where(Solicitation.requested_date <= filters.date_to)
    if filters.search:
        pattern = f"%{filters.search}%"
        query = query.where(
            (Solicitation.title.ilike(pattern))
            | (Solicitation.organization.ilike(pattern))
            | (Solicitation.contact_person.ilike(pattern))
            | (Solicitation.purpose.ilike(pattern))
        )

    # Count total
    count_stmt = select(func.count()).select_from(query.subquery())
    count_res = await db.execute(count_stmt)
    total = count_res.scalar() or 0

    sort_column = getattr(Solicitation, sort.sort_by, Solicitation.created_at)
    if sort.sort_desc:
        query = query.order_by(desc(sort_column))
    else:
        query = query.order_by(sort_column.asc())

    offset = (pagination.page - 1) * pagination.per_page
    query = query.offset(offset).limit(pagination.per_page)

    res = await db.execute(query)
    items = list(res.scalars().all())

    total_pages = math.ceil(total / pagination.per_page) if total > 0 else 1

    return {
        "items": items,
        "total": total,
        "page": pagination.page,
        "per_page": pagination.per_page,
        "total_pages": total_pages,
    }


async def get_solicitation(db: AsyncSession, user_id: str, sol_id: str) -> Solicitation:
    """Retrieve a single solicitation by ID."""
    stmt = select(Solicitation).where(
        Solicitation.id == str(sol_id),
        Solicitation.user_id == str(user_id),
    )
    res = await db.execute(stmt)
    item = res.scalar_one_or_none()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitation not found",
        )
    return item


async def create_solicitation(
    db: AsyncSession,
    user_id: str,
    data: SolicitationCreate,
) -> Solicitation:
    """Create a new solicitation and log audit action."""
    item = Solicitation(
        **data.model_dump(),
        user_id=str(user_id),
    )
    db.add(item)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="solicitation",
        action="create",
        new_value=data.model_dump(mode="json"),
        actor=str(user_id),
    )

    return item


async def update_solicitation(
    db: AsyncSession,
    user_id: str,
    sol_id: str,
    data: SolicitationUpdate,
) -> Solicitation:
    """Update a solicitation and audit changed fields."""
    item = await get_solicitation(db, user_id, sol_id)
    created_at_before = item.created_at

    update_dict = data.model_dump(exclude_unset=True)
    for field, new_val in update_dict.items():
        old_val = getattr(item, field)
        if old_val != new_val:
            setattr(item, field, new_val)
            await audit_service.log_action(
                db=db,
                item_id=item.id,
                module="solicitation",
                action="update",
                field=field,
                old_value=old_val,
                new_value=new_val,
                actor=str(user_id),
            )

    item.created_at = created_at_before
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()
    return item


async def update_given_fields(
    db: AsyncSession,
    user_id: str,
    sol_id: str,
    data: SolicitationGivenUpdate,
) -> Solicitation:
    """Update given_* fields and auto-transition status to 'Given'."""
    item = await get_solicitation(db, user_id, sol_id)
    created_at_before = item.created_at

    updates = data.model_dump()
    for field, new_val in updates.items():
        old_val = getattr(item, field)
        if old_val != new_val:
            setattr(item, field, new_val)
            await audit_service.log_action(
                db=db,
                item_id=item.id,
                module="solicitation",
                action="update",
                field=field,
                old_value=old_val,
                new_value=new_val,
                actor=str(user_id),
            )

    # Auto transition to Given if not already Done
    if item.status not in ["Given", "Done"]:
        old_status = item.status
        item.status = "Given"
        await audit_service.log_action(
            db=db,
            item_id=item.id,
            module="solicitation",
            action="update",
            field="status",
            old_value=old_status,
            new_value="Given",
            actor=str(user_id),
        )

    item.created_at = created_at_before
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()
    return item


async def delete_solicitation(db: AsyncSession, user_id: str, sol_id: str) -> Solicitation:
    """Soft delete solicitation."""
    item = await get_solicitation(db, user_id, sol_id)
    if item.is_deleted:
        return item
    item.is_deleted = True
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="solicitation",
        action="delete",
        actor=str(user_id),
    )
    return item


async def restore_solicitation(db: AsyncSession, user_id: str, sol_id: str) -> Solicitation:
    """Restore soft-deleted solicitation."""
    item = await get_solicitation(db, user_id, sol_id)
    item.is_deleted = False
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="solicitation",
        action="restore",
        actor=str(user_id),
    )
    return item


async def duplicate_solicitation(db: AsyncSession, user_id: str, sol_id: str) -> Solicitation:
    """Duplicate solicitation."""
    orig = await get_solicitation(db, user_id, sol_id)
    new_item = Solicitation(
        title=f"Copy of {orig.title}",
        purpose=orig.purpose,
        organization=orig.organization,
        contact_person=orig.contact_person,
        phone=orig.phone,
        email=orig.email,
        amount_requested=orig.amount_requested,
        quantity_requested=orig.quantity_requested,
        requested_date=orig.requested_date,
        deadline=orig.deadline,
        follow_up_date=orig.follow_up_date,
        status="Draft",
        priority=orig.priority,
        category=orig.category,
        location=orig.location,
        notes=orig.notes,
        custom_field_values=orig.custom_field_values,
        user_id=str(user_id),
    )
    db.add(new_item)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=new_item.id,
        module="solicitation",
        action="duplicate",
        old_value={"original_id": orig.id},
        actor=str(user_id),
    )
    return new_item


async def bulk_action(
    db: AsyncSession,
    user_id: str,
    action: str,
    item_ids: List[str],
    data: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Execute bulk actions for solicitations."""
    success_count = 0
    failed_count = 0
    errors = []

    for i_id in item_ids:
        try:
            if action == "delete":
                await delete_solicitation(db, user_id, i_id)
            elif action == "restore":
                await restore_solicitation(db, user_id, i_id)
            elif action == "status_change":
                new_status = data.get("status") if data else None
                if not new_status:
                    raise ValueError("Status required for status_change")
                await update_solicitation(db, user_id, i_id, SolicitationUpdate(status=new_status))
            elif action == "tag" or action == "category":
                new_cat = data.get("category") if data else None
                await update_solicitation(db, user_id, i_id, SolicitationUpdate(category=new_cat))
            else:
                raise ValueError(f"Unknown bulk action: {action}")
            success_count += 1
        except Exception as e:
            failed_count += 1
            errors.append(f"Item {i_id}: {str(e)}")

    return {
        "success_count": success_count,
        "failed_count": failed_count,
        "errors": errors,
    }
