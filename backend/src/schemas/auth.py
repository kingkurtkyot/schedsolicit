"""Authentication schemas."""

from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    refresh_token: str


class ViewerAuthRequest(BaseModel):
    token: str
    passcode: Optional[str] = None


class ViewerTokenResponse(BaseModel):
    valid: bool = True
    viewer_token: str
    token_type: str = "bearer"
    scope: dict
    privacy_controls: dict
    expires_in: int
