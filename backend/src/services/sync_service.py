"""Offline synchronization service with last-write-wins and conflict detection."""

from datetime import date, datetime, time, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.schedule import Schedule
from src.models.solicitation import Solicitation
from src.schemas.sync import SyncItem, SyncConflict, SyncPushResponse, SyncPullResponse
from src.services import audit_service


def coerce_sync_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Coerce JSON string dates and times into Python native objects for SQLite/SQLAlchemy."""
    cleaned = dict(data)
    date_fields = {"event_date", "requested_date", "deadline", "follow_up_date", "given_date"}
    time_fields = {"start_time", "end_time"}
    datetime_fields = {"actual_start", "actual_end", "source_date", "completed_at", "created_at", "updated_at"}

    for k, v in list(cleaned.items()):
        if v is None:
            continue
        if k in date_fields and isinstance(v, str):
            try:
                cleaned[k] = date.fromisoformat(v.split("T")[0])
            except Exception:
                pass
        elif k in time_fields and isinstance(v, str):
            try:
                cleaned[k] = time.fromisoformat(v)
            except Exception:
                pass
        elif k in datetime_fields and isinstance(v, str):
            try:
                cleaned[k] = datetime.fromisoformat(v.replace("Z", "+00:00"))
            except Exception:
                pass
    return cleaned


async def push_changes(
    db: AsyncSession,
    user_id: str,
    items: List[SyncItem],
) -> SyncPushResponse:
    """Apply client sync batch. Uses last-write-wins based on updated_at."""
    applied_count = 0
    conflicts: List[SyncConflict] = []

    for item in items:
        model_cls = Schedule if item.module == "schedule" else Solicitation
        stmt = select(model_cls).where(
            model_cls.id == item.id,
            model_cls.user_id == str(user_id),
        )
        res = await db.execute(stmt)
        existing = res.scalar_one_or_none()

        coerced_data = coerce_sync_data(item.data)

        client_dt = item.updated_at.replace(tzinfo=timezone.utc) if item.updated_at.tzinfo is None else item.updated_at
        now_utc = datetime.now(timezone.utc)
        if client_dt > (now_utc + timedelta(minutes=5)):
            client_dt = now_utc

        if existing is None:
            # Create new record
            if item.action != "delete":
                new_record = model_cls(
                    id=item.id,
                    user_id=str(user_id),
                    updated_at=client_dt,
                    **coerced_data,
                )
                db.add(new_record)
                await audit_service.log_action(
                    db=db,
                    item_id=item.id,
                    module=item.module,
                    action="create",
                    new_value=item.data,
                    actor=str(user_id),
                    source="sync",
                )
                applied_count += 1
        else:
            # Existing record: check timestamp for last-write-wins
            # If server updated_at > client updated_at, reject with conflict
            server_dt = existing.updated_at.replace(tzinfo=timezone.utc) if existing.updated_at.tzinfo is None else existing.updated_at

            if server_dt > client_dt:
                conflicts.append(
                    SyncConflict(
                        item_id=item.id,
                        module=item.module,
                        client_updated_at=client_dt,
                        server_updated_at=server_dt,
                        server_data={
                            c.name: getattr(existing, c.name)
                            for c in existing.__table__.columns
                            if not c.name.startswith("_")
                        },
                        resolution="server_wins",
                    )
                )
            else:
                # Client is newer or equal (idempotent overwrite)
                if item.action == "delete":
                    existing.is_deleted = True
                    existing.updated_at = client_dt
                    await audit_service.log_action(
                        db=db,
                        item_id=item.id,
                        module=item.module,
                        action="delete",
                        actor=str(user_id),
                        source="sync",
                    )
                else:
                    for k, v in coerced_data.items():
                        if hasattr(existing, k) and k not in ["id", "created_at", "user_id"]:
                            setattr(existing, k, v)
                    existing.updated_at = client_dt
                    await audit_service.log_action(
                        db=db,
                        item_id=item.id,
                        module=item.module,
                        action="update",
                        new_value=item.data,
                        actor=str(user_id),
                        source="sync",
                    )
                applied_count += 1

    await db.flush()
    return SyncPushResponse(applied_count=applied_count, conflicts=conflicts)


async def pull_changes(
    db: AsyncSession,
    user_id: str,
    since: Optional[datetime] = None,
) -> SyncPullResponse:
    """Pull all changes since the given timestamp."""
    now = datetime.now(timezone.utc)

    # Schedules
    sched_query = select(Schedule).where(Schedule.user_id == str(user_id))
    if since:
        sched_query = sched_query.where(Schedule.updated_at >= since)
    sched_res = await db.execute(sched_query)
    schedules = sched_res.scalars().all()

    # Solicitations
    sol_query = select(Solicitation).where(Solicitation.user_id == str(user_id))
    if since:
        sol_query = sol_query.where(Solicitation.updated_at >= since)
    sol_res = await db.execute(sol_query)
    solicitations = sol_res.scalars().all()

    deleted_ids = [s.id for s in schedules if s.is_deleted] + [s.id for s in solicitations if s.is_deleted]

    sched_dicts = [
        {c.name: getattr(s, c.name) for c in s.__table__.columns if not c.name.startswith("_")}
        for s in schedules if not s.is_deleted
    ]
    sol_dicts = [
        {c.name: getattr(s, c.name) for c in s.__table__.columns if not c.name.startswith("_")}
        for s in solicitations if not s.is_deleted
    ]

    return SyncPullResponse(
        timestamp=now,
        schedules=sched_dicts,
        solicitations=sol_dicts,
        deleted_ids=deleted_ids,
    )
