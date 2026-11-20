"""ML model storage."""

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, Integer, LargeBinary, String
from sqlalchemy.orm import Mapped, mapped_column

from src.models.base import BaseModel


class MlModel(BaseModel):
    __tablename__ = "ml_models"

    model_type: Mapped[str] = mapped_column(String(50), nullable=False)  # categorizer, defaults
    module: Mapped[str] = mapped_column(String(20), nullable=False)  # schedule | solicitation
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    model_data: Mapped[Optional[bytes]] = mapped_column(LargeBinary, nullable=True)
    training_samples: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    accuracy: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    trained_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
