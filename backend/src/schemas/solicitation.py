"""Solicitation schemas."""

from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_serializer


class SolicitationBase(BaseModel):
    title: str = Field(..., max_length=200)
    purpose: Optional[str] = None
    organization: Optional[str] = Field(None, max_length=300)
    contact_person: Optional[str] = Field(None, max_length=200)
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=254)
    amount_requested: Optional[float] = None
    quantity_requested: Optional[str] = Field(None, max_length=200)
    requested_date: Optional[date] = None
    deadline: Optional[date] = None
    follow_up_date: Optional[date] = None
    status: Optional[str] = Field("Draft", max_length=20)
    priority: Optional[str] = Field("medium", max_length=20)
    category: Optional[str] = Field(None, max_length=100)
    location: Optional[str] = Field(None, max_length=300)
    notes: Optional[str] = None
    given_date: Optional[date] = None
    given_amount: Optional[float] = None
    given_item: Optional[str] = Field(None, max_length=300)
    given_by: Optional[str] = Field(None, max_length=200)
    given_to: Optional[str] = Field(None, max_length=200)
    source_date: Optional[datetime] = None
    receipt_proof: Optional[str] = Field(None, max_length=500)
    custom_field_values: Optional[Dict[str, Any]] = None


class SolicitationCreate(SolicitationBase):
    pass


class SolicitationUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    purpose: Optional[str] = None
    organization: Optional[str] = Field(None, max_length=300)
    contact_person: Optional[str] = Field(None, max_length=200)
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=254)
    amount_requested: Optional[float] = None
    quantity_requested: Optional[str] = Field(None, max_length=200)
    requested_date: Optional[date] = None
    deadline: Optional[date] = None
    follow_up_date: Optional[date] = None
    status: Optional[str] = Field(None, max_length=20)
    priority: Optional[str] = Field(None, max_length=20)
    category: Optional[str] = Field(None, max_length=100)
    location: Optional[str] = Field(None, max_length=300)
    notes: Optional[str] = None
    given_date: Optional[date] = None
    given_amount: Optional[float] = None
    given_item: Optional[str] = Field(None, max_length=300)
    given_by: Optional[str] = Field(None, max_length=200)
    given_to: Optional[str] = Field(None, max_length=200)
    source_date: Optional[datetime] = None
    receipt_proof: Optional[str] = Field(None, max_length=500)
    custom_field_values: Optional[Dict[str, Any]] = None


class SolicitationGivenUpdate(BaseModel):
    given_date: date
    given_amount: Optional[float] = None
    given_item: Optional[str] = Field(None, max_length=300)
    given_by: Optional[str] = Field(None, max_length=200)
    given_to: Optional[str] = Field(None, max_length=200)
    receipt_proof: Optional[str] = Field(None, max_length=500)


class SolicitationResponse(SolicitationBase):
    id: str
    created_at: datetime
    updated_at: datetime
    is_deleted: bool
    user_id: str

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("created_at", "updated_at", when_used="json")
    def serialize_dt(self, dt: datetime) -> str:
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.isoformat().replace("+00:00", "Z")


class SolicitationListResponse(BaseModel):
    items: List[SolicitationResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
