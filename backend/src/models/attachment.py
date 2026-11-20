"""Attachment model."""

from typing import Optional

from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class Attachment(BaseModel):
    __tablename__ = "attachments"

    item_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    module: Mapped[str] = mapped_column(String(20), nullable=False)  # schedule | solicitation
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    file_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    purpose: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # receipt, proof, document
    ocr_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
