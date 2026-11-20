"""ShareLink model for external sharing."""

from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class ShareLink(BaseModel):
    __tablename__ = "share_links"

    token: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    label: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)

    # Scope: which items and what filters are shared
    scope: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    # e.g. {"modules": ["schedule"], "statuses": ["Active"], "item_ids": [...], "categories": [...], "date_from": "...", "date_to": "..."}

    # Access control
    passcode_hash: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    view_limit: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)  # null = unlimited
    view_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Privacy controls: which fields to strip from viewer responses
    privacy_controls: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    # e.g. {"hide_amounts": true, "hide_contacts": true, "hide_notes": false, "hide_attachments": false, "summary_only": false}

    allow_export: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_revoked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Owner
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=False, index=True
    )
