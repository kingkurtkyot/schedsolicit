"""CustomField model for user-defined fields per module."""

from typing import Optional

from sqlalchemy import Boolean, Integer, String
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class CustomField(BaseModel):
    __tablename__ = "custom_fields"

    module: Mapped[str] = mapped_column(String(20), nullable=False, index=True)  # schedule | solicitation
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    field_type: Mapped[str] = mapped_column(String(30), nullable=False)  # text, number, date, dropdown, checkbox
    options: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)  # dropdown options etc
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
