"""Offline sync schemas."""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, model_validator


class SyncItem(BaseModel):
    id: str
    module: str = Field(default="schedule")  # schedule | solicitation
    action: str = "upsert"  # upsert | delete
    data: Dict[str, Any] = Field(default_factory=dict)
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    @model_validator(mode="before")
    @classmethod
    def normalize_aliases(cls, values: Any) -> Any:
        if isinstance(values, dict):
            # Accept entity_type as module
            if "module" not in values and "entity_type" in values:
                values["module"] = values["entity_type"]
            # Accept entity_id as id
            if "id" not in values and "entity_id" in values:
                values["id"] = values["entity_id"]
            # Accept operation as action
            if "action" not in values and "operation" in values:
                values["action"] = values["operation"]
            # Accept payload as data
            if "data" not in values and "payload" in values:
                values["data"] = values["payload"]
            # Fallback updated_at if missing
            if "updated_at" not in values:
                values["updated_at"] = values.get("created_at") or datetime.now(timezone.utc)
        return values


class SyncPushRequest(BaseModel):
    items: List[SyncItem]


class SyncConflict(BaseModel):
    item_id: str
    module: str
    client_updated_at: datetime
    server_updated_at: datetime
    server_data: Dict[str, Any]
    resolution: str = "server_wins"


class SyncPushResponse(BaseModel):
    applied_count: int
    conflicts: List[SyncConflict] = []


class SyncPullResponse(BaseModel):
    timestamp: datetime
    schedules: List[Dict[str, Any]]
    solicitations: List[Dict[str, Any]]
    deleted_ids: List[str] = []
