"""Schedule model with all fields from field_schemas.json."""

from datetime import date, datetime, time
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, String, Text, Time
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class Schedule(BaseModel):
    __tablename__ = "schedules"

    # Basic
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Timing
    event_date: Mapped[date] = mapped_column(Date, nullable=False)
    start_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    end_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    all_day: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Details
    location: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    priority: Mapped[Optional[str]] = mapped_column(String(20), default="medium", nullable=True)

    # Repeat / reminders (JSON)
    repeat_rule: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    reminder_offsets: Mapped[Optional[list]] = mapped_column(JSON, nullable=True, default=[3600])

    # Meta
    status: Mapped[Optional[str]] = mapped_column(String(20), default="Active", nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Tracking
    actual_start: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    actual_end: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    source_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Extensions
    visibility: Mapped[Optional[str]] = mapped_column(String(20), default="private", nullable=True)
    custom_field_values: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    # Owner
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=False, index=True
    )
