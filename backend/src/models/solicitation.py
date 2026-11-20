"""Solicitation model with all fields from field_schemas.json."""

from datetime import date, datetime
from typing import Optional

from sqlalchemy import Date, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class Solicitation(BaseModel):
    __tablename__ = "solicitations"

    # Basic
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    purpose: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Contact
    organization: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    contact_person: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(254), nullable=True)

    # Request
    amount_requested: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quantity_requested: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)

    # Timing
    requested_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    deadline: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    follow_up_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)

    # Meta
    status: Mapped[Optional[str]] = mapped_column(String(20), default="Draft", nullable=True)
    priority: Mapped[Optional[str]] = mapped_column(String(20), default="medium", nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    location: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Fulfillment (given_*)
    given_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    given_amount: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    given_item: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    given_by: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    given_to: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)

    # Tracking
    source_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    receipt_proof: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    # Extensions
    custom_field_values: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    # Owner
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=False, index=True
    )
