"""FastAPI dependencies for authentication and authorization."""

from typing import Any, Dict, Optional
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.security import decode_token, TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH, TOKEN_TYPE_VIEWER

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """Extract and validate owner JWT from Authorization header.

    Returns dict with 'user_id' (UUID str) and full token payload.
    Raises 401 for missing/invalid tokens, 403 for non-access tokens.
    """
    token = credentials.credentials
    try:
        payload = decode_token(token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if payload.get("type") != TOKEN_TYPE_ACCESS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid token type. Owner access token required.",
        )
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject",
        )
    return {"user_id": user_id, "payload": payload}


async def get_viewer_context(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """Extract and validate viewer JWT from Authorization header.

    Returns dict with 'share_link_id', 'scope', and full payload.
    Raises 401 for missing/invalid tokens, 403 for non-viewer tokens.
    """
    token = credentials.credentials
    try:
        payload = decode_token(token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired viewer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if payload.get("type") != TOKEN_TYPE_VIEWER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid token type. Viewer token required.",
        )
    return {
        "share_link_id": payload.get("sub"),
        "scope": payload.get("scope", {}),
        "payload": payload,
    }
