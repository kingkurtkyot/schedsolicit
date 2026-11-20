"""Common schema definitions for pagination, filtering, sorting, and bulk actions."""

from datetime import date, datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    per_page: int = Field(default=20, ge=1, le=10000)


class FilterParams(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    category: Optional[str] = None
    date_from: Optional[date] = None
    date_to: Optional[date] = None
    search: Optional[str] = None
    is_deleted: bool = False


class SortParams(BaseModel):
    sort_by: str = "created_at"
    sort_desc: bool = True


class BulkActionRequest(BaseModel):
    action: str = Field(..., description="delete, restore, status_change, tag")
    item_ids: List[str] = Field(..., min_length=1)
    data: Optional[Dict[str, Any]] = None


class BulkActionResponse(BaseModel):
    success_count: int
    failed_count: int
    errors: List[str] = []
