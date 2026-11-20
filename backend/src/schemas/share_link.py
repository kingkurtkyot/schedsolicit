"""ShareLink schemas."""

from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ShareLinkCreate(BaseModel):
    label: Optional[str] = Field(None, max_length=200)
    scope: Optional[Dict[str, Any]] = None
    privacy_controls: Optional[Dict[str, Any]] = None
    passcode: Optional[str] = None
    expires_at: Optional[datetime] = None
    view_limit: Optional[int] = None
    allow_export: bool = False


class ShareLinkResponse(BaseModel):
    id: str
    token: str
    label: Optional[str] = None
    scope: Optional[Dict[str, Any]] = None
    privacy_controls: Optional[Dict[str, Any]] = None
    has_passcode: bool = False
    expires_at: Optional[datetime] = None
    view_limit: Optional[int] = None
    view_count: int = 0
    allow_export: bool = False
    is_revoked: bool = False
    created_at: datetime
    updated_at: datetime
    share_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ShareLinkListResponse(BaseModel):
    items: List[ShareLinkResponse]
    total: int


class ViewerAccessLogResponse(BaseModel):
    id: str
    share_link_id: str
    accessed_at: datetime
    user_agent: Optional[str] = None
    ip_hash: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
