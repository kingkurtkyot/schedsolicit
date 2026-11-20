"""Viewer authentication: validate token, check passcode, issue viewer JWT."""

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.security import create_viewer_token
from src.schemas.auth import ViewerAuthRequest, ViewerTokenResponse
from src.services import share_service

router = APIRouter(prefix="/auth")


@router.post("/validate", response_model=ViewerTokenResponse)
async def validate_viewer_token(
    req: ViewerAuthRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    # 1. Validate share token (constant time, expiry, limits)
    link = await share_service.validate_share_token(db, req.token)

    # 2. Verify passcode if required
    await share_service.check_passcode(link, req.passcode)

    # 3. Log access
    client_ip = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    await share_service.log_access(db, link.id, user_agent=user_agent, client_ip=client_ip)

    # 4. Generate scoped viewer JWT
    scope_data = {
        "scope": link.scope or {},
        "privacy_controls": link.privacy_controls or {},
        "allow_export": link.allow_export,
    }
    viewer_token = create_viewer_token(link.id, scope=scope_data)

    return ViewerTokenResponse(
        viewer_token=viewer_token,
        scope=link.scope or {},
        privacy_controls=link.privacy_controls or {},
        expires_in=86400,
    )
