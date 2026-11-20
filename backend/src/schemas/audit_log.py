"""AuditLog schemas."""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class AuditLogFilter(BaseModel):
    module: Optional[str] = None
    action: Optional[str] = None
    item_id: Optional[str] = None
    actor: Optional[str] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    page: int = 1
    per_page: int = 50


class AuditLogResponse(BaseModel):
    id: str
    item_id: str
    module: str
    action: str
    field: Optional[str] = None
    old_value: Optional[str] = None
    new_value: Optional[str] = None
    timestamp: datetime
    actor: str
    source: str

    model_config = ConfigDict(from_attributes=True)


class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    per_page: int
