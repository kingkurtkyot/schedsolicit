"""Schedule schemas."""

from datetime import date, datetime, time, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_serializer


class ScheduleBase(BaseModel):
    title: str = Field(..., max_length=200)
    description: Optional[str] = None
    event_date: date
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    all_day: bool = False
    location: Optional[str] = Field(None, max_length=300)
    category: Optional[str] = Field(None, max_length=100)
    priority: Optional[str] = Field("medium", max_length=20)
    repeat_rule: Optional[Dict[str, Any]] = None
    reminder_offsets: Optional[List[int]] = [3600]
    status: Optional[str] = Field("Active", max_length=20)
    notes: Optional[str] = None
    actual_start: Optional[datetime] = None
    actual_end: Optional[datetime] = None
    source_date: Optional[datetime] = None
    visibility: Optional[str] = Field("private", max_length=20)
    custom_field_values: Optional[Dict[str, Any]] = None


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    event_date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    all_day: Optional[bool] = None
    location: Optional[str] = Field(None, max_length=300)
    category: Optional[str] = Field(None, max_length=100)
    priority: Optional[str] = Field(None, max_length=20)
    repeat_rule: Optional[Dict[str, Any]] = None
    reminder_offsets: Optional[List[int]] = None
    status: Optional[str] = Field(None, max_length=20)
    notes: Optional[str] = None
    actual_start: Optional[datetime] = None
    actual_end: Optional[datetime] = None
    source_date: Optional[datetime] = None
    visibility: Optional[str] = Field(None, max_length=20)
    custom_field_values: Optional[Dict[str, Any]] = None


class ScheduleResponse(ScheduleBase):
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


class ScheduleListResponse(BaseModel):
    items: List[ScheduleResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
