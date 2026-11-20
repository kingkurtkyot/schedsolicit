"""Tests for ShareLink creation, revocation, passcode protection, and viewer access."""

import pytest
from httpx import AsyncClient
from src.models.share_link import ShareLink


@pytest.mark.asyncio
async def test_create_and_validate_share_link(client: AsyncClient, owner_headers: dict):
    payload = {
        "label": "Public Outreach View",
        "scope": {"modules": ["schedule"], "statuses": ["Active"]},
        "privacy_controls": {"hide_amounts": True, "hide_contacts": True},
        "passcode": "SecretPass123",
        "allow_export": False,
    }
    resp = await client.post("/api/owner/share-links", json=payload, headers=owner_headers)
    assert resp.status_code == 201
    link_data = resp.json()
    token = link_data["token"]
    assert link_data["has_passcode"] is True

    # Validate with wrong passcode -> 401
    bad_auth = await client.post("/api/view/auth/validate", json={"token": token, "passcode": "WrongPass"})
    assert bad_auth.status_code == 401

    # Validate with correct passcode -> 200 + viewer JWT
    good_auth = await client.post("/api/view/auth/validate", json={"token": token, "passcode": "SecretPass123"})
    assert good_auth.status_code == 200
    assert "viewer_token" in good_auth.json()


@pytest.mark.asyncio
async def test_revoke_share_link(client: AsyncClient, owner_headers: dict, test_share_link: ShareLink):
    # Revoke
    rev_resp = await client.post(f"/api/owner/share-links/{test_share_link.id}/revoke", headers=owner_headers)
    assert rev_resp.status_code == 200
    assert rev_resp.json()["is_revoked"] is True

    # Validate attempt should now fail with 403
    val_resp = await client.post("/api/view/auth/validate", json={"token": test_share_link.token})
    assert val_resp.status_code == 403
    assert "revoked" in val_resp.json()["detail"]


@pytest.mark.asyncio
async def test_regenerate_share_link(client: AsyncClient, owner_headers: dict, test_share_link: ShareLink):
    old_token = test_share_link.token
    regen_resp = await client.post(f"/api/owner/share-links/{test_share_link.id}/regenerate", headers=owner_headers)
    assert regen_resp.status_code == 200
    new_token = regen_resp.json()["token"]
    assert new_token != old_token

    # Old token fails
    old_val = await client.post("/api/view/auth/validate", json={"token": old_token})
    assert old_val.status_code == 404

    # New token succeeds
    new_val = await client.post("/api/view/auth/validate", json={"token": new_token})
    assert new_val.status_code == 200
