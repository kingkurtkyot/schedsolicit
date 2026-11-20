"""Owner share link management endpoints."""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.dependencies import get_current_user
from src.schemas.share_link import (
    ShareLinkCreate,
    ShareLinkListResponse,
    ShareLinkResponse,
    ViewerAccessLogResponse,
)
from src.services import share_service

router = APIRouter(prefix="/share-links")


@router.get("", response_model=ShareLinkListResponse)
async def list_share_links_endpoint(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    links = await share_service.get_share_links(db, current_user["user_id"])
    response_items = []
    for l in links:
        resp = ShareLinkResponse(
            id=l.id,
            token=l.token,
            label=l.label,
            scope=l.scope,
            privacy_controls=l.privacy_controls,
            has_passcode=bool(l.passcode_hash),
            expires_at=l.expires_at,
            view_limit=l.view_limit,
            view_count=l.view_count,
            allow_export=l.allow_export,
            is_revoked=l.is_revoked,
            created_at=l.created_at,
            updated_at=l.updated_at,
            share_url=f"/view/{l.token}",
        )
        response_items.append(resp)
    return ShareLinkListResponse(items=response_items, total=len(response_items))


@router.post("", response_model=ShareLinkResponse, status_code=status.HTTP_201_CREATED)
async def create_share_link_endpoint(
    data: ShareLinkCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    link = await share_service.create_share_link(db, current_user["user_id"], data)
    return ShareLinkResponse(
        id=link.id,
        token=link.token,
        label=link.label,
        scope=link.scope,
        privacy_controls=link.privacy_controls,
        has_passcode=bool(link.passcode_hash),
        expires_at=link.expires_at,
        view_limit=link.view_limit,
        view_count=link.view_count,
        allow_export=link.allow_export,
        is_revoked=link.is_revoked,
        created_at=link.created_at,
        updated_at=link.updated_at,
        share_url=f"/view/{link.token}",
    )


@router.post("/{link_id}/revoke", response_model=ShareLinkResponse)
async def revoke_share_link_endpoint(
    link_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    link = await share_service.revoke_link(db, current_user["user_id"], link_id)
    return ShareLinkResponse(
        id=link.id,
        token=link.token,
        label=link.label,
        scope=link.scope,
        privacy_controls=link.privacy_controls,
        has_passcode=bool(link.passcode_hash),
        expires_at=link.expires_at,
        view_limit=link.view_limit,
        view_count=link.view_count,
        allow_export=link.allow_export,
        is_revoked=link.is_revoked,
        created_at=link.created_at,
        updated_at=link.updated_at,
        share_url=f"/view/{link.token}",
    )


@router.post("/{link_id}/regenerate", response_model=ShareLinkResponse)
async def regenerate_share_link_endpoint(
    link_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    link = await share_service.regenerate_link(db, current_user["user_id"], link_id)
    return ShareLinkResponse(
        id=link.id,
        token=link.token,
        label=link.label,
        scope=link.scope,
        privacy_controls=link.privacy_controls,
        has_passcode=bool(link.passcode_hash),
        expires_at=link.expires_at,
        view_limit=link.view_limit,
        view_count=link.view_count,
        allow_export=link.allow_export,
        is_revoked=link.is_revoked,
        created_at=link.created_at,
        updated_at=link.updated_at,
        share_url=f"/view/{link.token}",
    )


@router.get("/{link_id}/access-log", response_model=List[ViewerAccessLogResponse])
async def get_share_link_access_log_endpoint(
    link_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await share_service.get_access_log(db, current_user["user_id"], link_id)


@router.get("/{link_id}/qr")
async def get_qr_data(
    link_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    links = await share_service.get_share_links(db, current_user["user_id"])
    target = next((l for l in links if l.id == link_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Share link not found")
    return {"url": f"/view/{target.token}", "token": target.token}
