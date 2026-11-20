"""Tests for offline sync (push, pull, conflict detection, idempotent operations)."""

import uuid
from datetime import datetime, timezone, timedelta
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_sync_push_new_items(client: AsyncClient, owner_headers: dict):
    now = datetime.now(timezone.utc)
    item_id = str(uuid.uuid4())
    payload = {
        "items": [
            {
                "id": item_id,
                "module": "schedule",
                "action": "upsert",
                "data": {
                    "title": "Offline Created Event",
                    "event_date": "2026-08-01",
                    "status": "Active",
                },
                "updated_at": now.isoformat(),
            }
        ]
    }
    resp = await client.post("/api/owner/sync/push", json=payload, headers=owner_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["applied_count"] == 1
    assert len(data["conflicts"]) == 0

    # Verify item exists
    get_resp = await client.get(f"/api/owner/schedules/{item_id}", headers=owner_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["title"] == "Offline Created Event"


@pytest.mark.asyncio
async def test_sync_push_idempotent(client: AsyncClient, owner_headers: dict):
    now = datetime.now(timezone.utc)
    item_id = str(uuid.uuid4())
    payload = {
        "items": [
            {
                "id": item_id,
                "module": "schedule",
                "action": "upsert",
                "data": {
                    "title": "Idempotent Event",
                    "event_date": "2026-08-02",
                    "status": "Active",
                },
                "updated_at": now.isoformat(),
            }
        ]
    }
    # Push 1
    resp1 = await client.post("/api/owner/sync/push", json=payload, headers=owner_headers)
    assert resp1.status_code == 200
    assert resp1.json()["applied_count"] == 1

    # Push 2 with identical content
    resp2 = await client.post("/api/owner/sync/push", json=payload, headers=owner_headers)
    assert resp2.status_code == 200
    assert resp2.json()["applied_count"] == 1


@pytest.mark.asyncio
async def test_sync_conflict_last_write_wins(client: AsyncClient, owner_headers: dict):
    # Create item
    item_id = str(uuid.uuid4())
    t1 = datetime.now(timezone.utc)
    resp1 = await client.post(
        "/api/owner/sync/push",
        json={
            "items": [
                {
                    "id": item_id,
                    "module": "schedule",
                    "action": "upsert",
                    "data": {"title": "Base Title", "event_date": "2026-08-05", "status": "Active"},
                    "updated_at": t1.isoformat(),
                }
            ]
        },
        headers=owner_headers,
    )
    assert resp1.status_code == 200

    # Advance server time via update
    await client.put(
        f"/api/owner/schedules/{item_id}",
        json={"title": "Server Updated Title"},
        headers=owner_headers,
    )

    # Client tries to push older update (t1 - 10 min)
    older_time = t1 - timedelta(minutes=10)
    conflict_resp = await client.post(
        "/api/owner/sync/push",
        json={
            "items": [
                {
                    "id": item_id,
                    "module": "schedule",
                    "action": "upsert",
                    "data": {"title": "Stale Client Update", "event_date": "2026-08-05"},
                    "updated_at": older_time.isoformat(),
                }
            ]
        },
        headers=owner_headers,
    )
    assert conflict_resp.status_code == 200
    res_data = conflict_resp.json()
    assert len(res_data["conflicts"]) == 1
    assert res_data["conflicts"][0]["item_id"] == item_id
    assert res_data["conflicts"][0]["resolution"] == "server_wins"


@pytest.mark.asyncio
async def test_sync_pull(client: AsyncClient, owner_headers: dict):
    resp = await client.get("/api/owner/sync/pull", headers=owner_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "timestamp" in data
    assert "schedules" in data
    assert "solicitations" in data
