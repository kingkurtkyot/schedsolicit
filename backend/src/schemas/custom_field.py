"""CustomField and Category schemas."""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CustomFieldCreate(BaseModel):
    module: str = Field(..., description="schedule or solicitation")
    name: str = Field(..., max_length=100)
    field_type: str = Field(..., description="text, number, date, dropdown, checkbox")
    options: Optional[Dict[str, Any]] = None
    sort_order: int = 0
    is_active: bool = True


class CustomFieldResponse(CustomFieldCreate):
    id: str
    user_id: str

    model_config = ConfigDict(from_attributes=True)


class CategoryCreate(BaseModel):
    module: str = Field(..., description="schedule or solicitation")
    name: str = Field(..., max_length=100)
    color: str = Field(default="#2E7D32", max_length=10)
    sort_order: int = 0
    is_custom: bool = True


class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=10)
    sort_order: Optional[int] = None
    is_custom: Optional[bool] = None


class CategoryResponse(CategoryCreate):
    id: str
    user_id: str

    model_config = ConfigDict(from_attributes=True)
