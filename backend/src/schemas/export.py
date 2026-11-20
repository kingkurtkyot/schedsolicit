"""Export schemas."""

from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ExportFormat(str, Enum):
    csv = "csv"
    json = "json"
    xlsx = "xlsx"
    pdf = "pdf"
    png = "png"
    ics = "ics"


class ExportRequest(BaseModel):
    module: str = Field(..., description="schedule | solicitation")
    format: ExportFormat = ExportFormat.json
    item_ids: Optional[List[str]] = None
    filter: Optional[Dict[str, Any]] = None
    fields: Optional[List[str]] = None
    layout: Optional[str] = "table"
    content_level: Optional[str] = "full"  # full, summary, privacy_filtered
    title: Optional[str] = "SchedSolicit Export"
