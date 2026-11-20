"""Schedule CRUD and business logic."""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import math
import uuid

from fastapi import HTTPException, status
from sqlalchemy import desc, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.schedule import Schedule
from src.schemas.schedule import ScheduleCreate, ScheduleUpdate
from src.schemas.common import FilterParams, PaginationParams, SortParams
from src.services import audit_service


async def list_schedules(
    db: AsyncSession,
    user_id: str,
    filters: FilterParams,
    pagination: PaginationParams,
    sort: SortParams,
) -> Dict[str, Any]:
    """List schedules with filtering, sorting, and pagination."""
    query = select(Schedule).where(
        Schedule.user_id == str(user_id),
        Schedule.is_deleted == filters.is_deleted,
    )

    if filters.status:
        query = query.where(Schedule.status == filters.status)
    if filters.priority:
        query = query.where(Schedule.priority == filters.priority)
    if filters.category:
        query = query.where(Schedule.category == filters.category)
    if filters.date_from:
        query = query.where(Schedule.event_date >= filters.date_from)
    if filters.date_to:
        query = query.where(Schedule.event_date <= filters.date_to)
    if filters.search:
        pattern = f"%{filters.search}%"
        query = query.where(
            (Schedule.title.ilike(pattern))
            | (Schedule.description.ilike(pattern))
            | (Schedule.location.ilike(pattern))
        )

    # Count total
    count_stmt = select(func.count()).select_from(query.subquery())
    count_res = await db.execute(count_stmt)
    total = count_res.scalar() or 0

    # Sorting
    sort_column = getattr(Schedule, sort.sort_by, Schedule.created_at)
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


async def get_schedule(db: AsyncSession, user_id: str, schedule_id: str) -> Schedule:
    """Retrieve a single schedule by ID."""
    stmt = select(Schedule).where(
        Schedule.id == str(schedule_id),
        Schedule.user_id == str(user_id),
    )
    res = await db.execute(stmt)
    item = res.scalar_one_or_none()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Schedule not found",
        )
    return item


async def check_overlap(
    db: AsyncSession,
    user_id: str,
    event_date: Any,
    start_time: Any,
    end_time: Any,
    exclude_id: Optional[str] = None,
) -> Optional[Schedule]:
    """Check if there is a scheduling conflict on the same date and overlapping time."""
    if not (start_time and end_time):
        return None

    stmt = select(Schedule).where(
        Schedule.user_id == str(user_id),
        Schedule.is_deleted == False,
        Schedule.event_date == event_date,
        Schedule.start_time.is_not(None),
        Schedule.end_time.is_not(None),
        Schedule.start_time < end_time,
        Schedule.end_time > start_time,
    )
    if exclude_id:
        stmt = stmt.where(Schedule.id != str(exclude_id))

    res = await db.execute(stmt)
    return res.scalar_one_or_none()


async def create_schedule(
    db: AsyncSession,
    user_id: str,
    data: ScheduleCreate,
) -> Schedule:
    """Create a new schedule and log audit action."""
    item = Schedule(
        **data.model_dump(),
        user_id=str(user_id),
    )
    db.add(item)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="schedule",
        action="create",
        new_value=data.model_dump(mode="json"),
        actor=str(user_id),
    )

    return item


async def update_schedule(
    db: AsyncSession,
    user_id: str,
    schedule_id: str,
    data: ScheduleUpdate,
) -> Schedule:
    """Update an existing schedule and record audit logs for modified fields."""
    item = await get_schedule(db, user_id, schedule_id)
    created_at_before = item.created_at  # Ensure created_at never changes

    update_dict = data.model_dump(exclude_unset=True)
    for field, new_val in update_dict.items():
        old_val = getattr(item, field)
        if old_val != new_val:
            setattr(item, field, new_val)
            await audit_service.log_action(
                db=db,
                item_id=item.id,
                module="schedule",
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


async def delete_schedule(db: AsyncSession, user_id: str, schedule_id: str) -> Schedule:
    """Soft-delete a schedule."""
    item = await get_schedule(db, user_id, schedule_id)
    if item.is_deleted:
        return item
    item.is_deleted = True
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="schedule",
        action="delete",
        actor=str(user_id),
    )
    return item


async def restore_schedule(db: AsyncSession, user_id: str, schedule_id: str) -> Schedule:
    """Restore a soft-deleted schedule."""
    item = await get_schedule(db, user_id, schedule_id)
    item.is_deleted = False
    item.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=item.id,
        module="schedule",
        action="restore",
        actor=str(user_id),
    )
    return item


async def duplicate_schedule(db: AsyncSession, user_id: str, schedule_id: str) -> Schedule:
    """Duplicate an existing schedule."""
    orig = await get_schedule(db, user_id, schedule_id)
    new_item = Schedule(
        title=f"Copy of {orig.title}",
        description=orig.description,
        event_date=orig.event_date,
        start_time=orig.start_time,
        end_time=orig.end_time,
        all_day=orig.all_day,
        location=orig.location,
        category=orig.category,
        priority=orig.priority,
        repeat_rule=orig.repeat_rule,
        reminder_offsets=orig.reminder_offsets,
        status="Active",
        notes=orig.notes,
        visibility=orig.visibility,
        custom_field_values=orig.custom_field_values,
        user_id=str(user_id),
    )
    db.add(new_item)
    await db.flush()

    await audit_service.log_action(
        db=db,
        item_id=new_item.id,
        module="schedule",
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
    """Execute bulk actions: delete, restore, status_change, tag."""
    success_count = 0
    failed_count = 0
    errors = []

    for i_id in item_ids:
        try:
            if action == "delete":
                await delete_schedule(db, user_id, i_id)
            elif action == "restore":
                await restore_schedule(db, user_id, i_id)
            elif action == "status_change":
                new_status = data.get("status") if data else None
                if not new_status:
                    raise ValueError("Status required for status_change")
                await update_schedule(db, user_id, i_id, ScheduleUpdate(status=new_status))
            elif action == "tag" or action == "category":
                new_cat = data.get("category") if data else None
                await update_schedule(db, user_id, i_id, ScheduleUpdate(category=new_cat))
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
