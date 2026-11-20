"""Category model for schedule/solicitation categories."""

from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class Category(BaseModel):
    __tablename__ = "categories"

    module: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    color: Mapped[str] = mapped_column(String(10), default="#2E7D32", nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_custom: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
