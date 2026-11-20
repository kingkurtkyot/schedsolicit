"""Share link creation, validation, scoping, and calendar ICS export."""

import hashlib
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from fastapi import HTTPException, status
from icalendar import Calendar, Event as ICalEvent
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.rate_limiter import passcode_lockout
from src.core.security import (
    constant_time_compare,
    generate_secure_token,
    hash_password,
    verify_password,
)
from src.models.schedule import Schedule
from src.models.share_link import ShareLink
from src.models.solicitation import Solicitation
from src.models.viewer_access_log import ViewerAccessLog
from src.schemas.share_link import ShareLinkCreate


async def create_share_link(
    db: AsyncSession,
    user_id: str,
    data: ShareLinkCreate,
) -> ShareLink:
    """Generate a new secure share link."""
    token = generate_secure_token(32)
    passcode_hash = hash_password(data.passcode) if data.passcode else None

    link = ShareLink(
        token=token,
        label=data.label,
        scope=data.scope or {},
        privacy_controls=data.privacy_controls or {},
        passcode_hash=passcode_hash,
        expires_at=data.expires_at,
        view_limit=data.view_limit,
        allow_export=data.allow_export,
        user_id=str(user_id),
    )
    db.add(link)
    await db.flush()
    return link


async def get_share_links(db: AsyncSession, user_id: str) -> List[ShareLink]:
    """List all share links owned by user."""
    stmt = (
        select(ShareLink)
        .where(ShareLink.user_id == str(user_id), ShareLink.is_deleted == False)
        .order_by(desc(ShareLink.created_at))
    )
    res = await db.execute(stmt)
    return list(res.scalars().all())


async def validate_share_token(db: AsyncSession, token: str) -> ShareLink:
    """Validate share token using indexed lookup with constant-time verification.
    
    Checks:
    - Revocation
    - Expiration
    - View limit
    Increments view_count.
    """
    # 1. Fast indexed database query (O(1))
    stmt = select(ShareLink).where(
        ShareLink.token == token,
        ShareLink.is_deleted == False,
    )
    res = await db.execute(stmt)
    target_link: Optional[ShareLink] = res.scalar_one_or_none()

    # 2. Constant-time verification to prevent timing attacks
    dummy_token = "0" * 44  # Base64 length of 32 bytes
    token_to_verify = target_link.token if target_link else dummy_token
    is_valid = constant_time_compare(token_to_verify, token)

    if not target_link or not is_valid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Share link not found",
        )

    if target_link.is_revoked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This share link has been revoked",
        )

    now = datetime.now(timezone.utc)
    if target_link.expires_at:
        exp = target_link.expires_at
        if exp.tzinfo is None:
            exp = exp.replace(tzinfo=timezone.utc)
        if now > exp:
            raise HTTPException(
                status_code=status.HTTP_410_GONE,
                detail="This share link has expired",
            )

    if target_link.view_limit is not None and target_link.view_count >= target_link.view_limit:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This share link has reached its maximum view limit",
        )

    target_link.view_count += 1
    await db.flush()
    return target_link


async def check_passcode(link: ShareLink, passcode: Optional[str]) -> bool:
    """Verify passcode with lockout protection."""
    if not link.passcode_hash:
        return True

    lockout_key = f"share_{link.id}"
    passcode_lockout.assert_not_locked(lockout_key)

    if not passcode:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Passcode required for this link",
        )

    valid = verify_password(passcode, link.passcode_hash)
    if not valid:
        passcode_lockout.record_attempt(lockout_key)
        remaining = passcode_lockout.get_remaining_attempts(lockout_key)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid passcode. {remaining} attempts remaining.",
        )

    passcode_lockout.record_success(lockout_key)
    return True


async def revoke_link(db: AsyncSession, user_id: str, link_id: str) -> ShareLink:
    """Revoke a share link."""
    stmt = select(ShareLink).where(
        ShareLink.id == str(link_id),
        ShareLink.user_id == str(user_id),
    )
    res = await db.execute(stmt)
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")
    link.is_revoked = True
    await db.flush()
    return link


async def regenerate_link(db: AsyncSession, user_id: str, link_id: str) -> ShareLink:
    """Regenerate token for an existing share link."""
    stmt = select(ShareLink).where(
        ShareLink.id == str(link_id),
        ShareLink.user_id == str(user_id),
    )
    res = await db.execute(stmt)
    link = res.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Share link not found")

    link.token = generate_secure_token(32)
    link.is_revoked = False
    link.view_count = 0
    await db.flush()
    return link


async def log_access(
    db: AsyncSession,
    share_link_id: str,
    user_agent: Optional[str] = None,
    client_ip: Optional[str] = None,
) -> None:
    """Log viewer access with IP hash."""
    ip_hash = hashlib.sha256(client_ip.encode()).hexdigest() if client_ip else None
    log = ViewerAccessLog(
        share_link_id=str(share_link_id),
        user_agent=user_agent[:500] if user_agent else None,
        ip_hash=ip_hash,
    )
    db.add(log)
    await db.flush()


async def get_access_log(
    db: AsyncSession,
    user_id: str,
    link_id: str,
) -> List[ViewerAccessLog]:
    """Retrieve access log for a share link."""
    # Verify ownership
    stmt = select(ShareLink).where(
        ShareLink.id == str(link_id),
        ShareLink.user_id == str(user_id),
    )
    res = await db.execute(stmt)
    if not res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Share link not found")

    log_stmt = (
        select(ViewerAccessLog)
        .where(ViewerAccessLog.share_link_id == str(link_id))
        .order_by(desc(ViewerAccessLog.accessed_at))
        .limit(100)
    )
    log_res = await db.execute(log_stmt)
    return list(log_res.scalars().all())


async def get_scoped_items(
    db: AsyncSession,
    share_link: ShareLink,
    module: str,
) -> List[Dict[str, Any]]:
    """Fetch items allowed by the share link scope."""
    scope = share_link.scope or {}
    allowed_modules = scope.get("modules", ["schedule", "solicitation"])
    if module not in allowed_modules:
        return []

    model_cls = Schedule if module == "schedule" else Solicitation
    query = select(model_cls).where(
        model_cls.user_id == share_link.user_id,
        model_cls.is_deleted == False,
    )

    # Scope filters
    if "item_ids" in scope and scope["item_ids"]:
        query = query.where(model_cls.id.in_(scope["item_ids"]))
    if "statuses" in scope and scope["statuses"]:
        query = query.where(model_cls.status.in_(scope["statuses"]))
    if "categories" in scope and scope["categories"]:
        query = query.where(model_cls.category.in_(scope["categories"]))

    date_field = Schedule.event_date if module == "schedule" else Solicitation.requested_date
    if "date_from" in scope and scope["date_from"]:
        query = query.where(date_field >= scope["date_from"])
    if "date_to" in scope and scope["date_to"]:
        query = query.where(date_field <= scope["date_to"])

    res = await db.execute(query)
    items = res.scalars().all()

    return [
        {c.name: getattr(it, c.name) for c in it.__table__.columns if not c.name.startswith("_")}
        for it in items
    ]


async def generate_ics_feed(db: AsyncSession, share_link: ShareLink) -> str:
    """Generate an iCalendar (.ics) string for scoped schedules."""
    items = await get_scoped_items(db, share_link, module="schedule")
    cal = Calendar()
    cal.add("prodid", "-//SchedSolicit//EN")
    cal.add("version", "2.0")
    cal.add("x-wr-calname", share_link.label or "SchedSolicit Calendar")

    for item in items:
        event = ICalEvent()
        event.add("summary", item.get("title", "Event"))
        if item.get("description"):
            event.add("description", item["description"])
        if item.get("location"):
            event.add("location", item["location"])

        e_date = item.get("event_date")
        s_time = item.get("start_time")
        e_time = item.get("end_time")

        if e_date:
            if s_time:
                dt_start = datetime.combine(e_date, s_time)
                event.add("dtstart", dt_start)
                if e_time:
                    dt_end = datetime.combine(e_date, e_time)
                    event.add("dtend", dt_end)
            else:
                event.add("dtstart", e_date)

        event.add("uid", f"{item['id']}@schedsolicit")
        cal.add_component(event)

    return cal.to_ical().decode("utf-8")
