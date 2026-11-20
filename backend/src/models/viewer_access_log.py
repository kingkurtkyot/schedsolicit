"""Viewer access log for tracking share link usage."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from src.core.database import Base


class ViewerAccessLog(Base):
    __tablename__ = "viewer_access_logs"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    share_link_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("share_links.id"), nullable=False, index=True
    )
    accessed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    user_agent: Mapped[str] = mapped_column(String(500), nullable=True)
    ip_hash: Mapped[str] = mapped_column(String(64), nullable=True)
