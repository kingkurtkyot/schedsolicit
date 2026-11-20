"""Append-only audit log model."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from src.core.database import Base


class AuditLog(Base):
    """Append-only audit trail. No updates or deletes ever."""

    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    item_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    module: Mapped[str] = mapped_column(String(20), nullable=False, index=True)  # schedule | solicitation
    action: Mapped[str] = mapped_column(String(20), nullable=False)  # create, update, delete, restore, duplicate
    field: Mapped[str] = mapped_column(String(100), nullable=True)  # null for create/delete/restore
    old_value: Mapped[str] = mapped_column(Text, nullable=True)
    new_value: Mapped[str] = mapped_column(Text, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
    actor: Mapped[str] = mapped_column(String(36), nullable=False)  # user_id
    source: Mapped[str] = mapped_column(String(30), default="api", nullable=False)  # api, sync, ocr, import
