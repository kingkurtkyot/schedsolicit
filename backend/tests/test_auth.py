"""Tests for Owner Authentication endpoints."""

import pytest
from httpx import AsyncClient
from src.models.user import User


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, test_user: User):
    resp = await client.post(
        "/api/owner/auth/login",
        json={"username": test_user.username, "password": "Secret123!"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_invalid_credentials(client: AsyncClient, test_user: User):
    resp = await client.post(
        "/api/owner/auth/login",
        json={"username": test_user.username, "password": "WrongPassword!"},
    )
    assert resp.status_code == 401
    assert "Incorrect username or password" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_refresh_token_flow(client: AsyncClient, test_user: User):
    # 1. Login to get refresh token
    login_resp = await client.post(
        "/api/owner/auth/login",
        json={"username": test_user.username, "password": "Secret123!"},
    )
    refresh_token = login_resp.json()["refresh_token"]

    # 2. Refresh
    resp = await client.post(
        "/api/owner/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_refresh_with_invalid_token(client: AsyncClient):
    resp = await client.post(
        "/api/owner/auth/refresh",
        json={"refresh_token": "invalid.jwt.token"},
    )
    assert resp.status_code == 401
