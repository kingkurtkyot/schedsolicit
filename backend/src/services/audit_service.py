"""Append-only audit logging service."""

import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.audit_log import AuditLog
from src.schemas.audit_log import AuditLogFilter


async def log_action(
    db: AsyncSession,
    item_id: str,
    module: str,
    action: str,
    field: Optional[str] = None,
    old_value: Optional[Any] = None,
    new_value: Optional[Any] = None,
    actor: str = "system",
    source: str = "api",
) -> AuditLog:
    """Write an append-only audit log entry."""
    str_old = json.dumps(old_value, default=str) if old_value is not None else None
    str_new = json.dumps(new_value, default=str) if new_value is not None else None

    entry = AuditLog(
        item_id=str(item_id),
        module=module,
        action=action,
        field=field,
        old_value=str_old,
        new_value=str_new,
        actor=str(actor),
        source=source,
        timestamp=datetime.now(timezone.utc),
    )
    db.add(entry)
    await db.flush()
    return entry


async def get_item_timeline(db: AsyncSession, item_id: str) -> List[AuditLog]:
    """Retrieve chronological audit timeline for a specific item."""
    stmt = (
        select(AuditLog)
        .where(AuditLog.item_id == str(item_id))
        .order_by(AuditLog.timestamp.asc())
    )
    res = await db.execute(stmt)
    return list(res.scalars().all())


async def get_global_activity(
    db: AsyncSession,
    filters: AuditLogFilter,
) -> Dict[str, Any]:
    """Retrieve filtered, paginated global activity logs."""
    query = select(AuditLog)

    if filters.module:
        query = query.where(AuditLog.module == filters.module)
    if filters.action:
        query = query.where(AuditLog.action == filters.action)
    if filters.item_id:
        query = query.where(AuditLog.item_id == filters.item_id)
    if filters.actor:
        query = query.where(AuditLog.actor == filters.actor)
    if filters.date_from:
        query = query.where(AuditLog.timestamp >= filters.date_from)
    if filters.date_to:
        query = query.where(AuditLog.timestamp <= filters.date_to)

    # Count total
    count_query = select(AuditLog.id)
    if filters.module:
        count_query = count_query.where(AuditLog.module == filters.module)
    if filters.action:
        count_query = count_query.where(AuditLog.action == filters.action)
    if filters.item_id:
        count_query = count_query.where(AuditLog.item_id == filters.item_id)
    if filters.actor:
        count_query = count_query.where(AuditLog.actor == filters.actor)
    if filters.date_from:
        count_query = count_query.where(AuditLog.timestamp >= filters.date_from)
    if filters.date_to:
        count_query = count_query.where(AuditLog.timestamp <= filters.date_to)

    count_res = await db.execute(count_query)
    total = len(count_res.scalars().all())

    query = query.order_by(desc(AuditLog.timestamp))
    offset = (filters.page - 1) * filters.per_page
    query = query.offset(offset).limit(filters.per_page)

    res = await db.execute(query)
    items = list(res.scalars().all())

    return {
        "items": items,
        "total": total,
        "page": filters.page,
        "per_page": filters.per_page,
    }
