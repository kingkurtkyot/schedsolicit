"""Tests for Schedule CRUD, filtering, pagination, soft delete, and bulk actions."""

import pytest
from httpx import AsyncClient
from src.models.schedule import Schedule


@pytest.mark.asyncio
async def test_create_schedule(client: AsyncClient, owner_headers: dict):
    payload = {
        "title": "Strategy Workshop",
        "event_date": "2026-06-10",
        "start_time": "09:00:00",
        "end_time": "11:00:00",
        "location": "Room 101",
        "category": "Workshop",
        "priority": "high",
        "status": "Active",
    }
    resp = await client.post("/api/owner/schedules", json=payload, headers=owner_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == payload["title"]
    assert data["event_date"] == payload["event_date"]
    assert data["is_deleted"] is False
    assert "id" in data


@pytest.mark.asyncio
async def test_get_schedule(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    resp = await client.get(f"/api/owner/schedules/{sample_schedule.id}", headers=owner_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == sample_schedule.id
    assert data["title"] == sample_schedule.title


@pytest.mark.asyncio
async def test_list_schedules_paginated(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    resp = await client.get("/api/owner/schedules?page=1&per_page=10", headers=owner_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert data["total"] >= 1
    assert data["page"] == 1


@pytest.mark.asyncio
async def test_update_schedule(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    update_data = {"title": "Updated Strategy Workshop", "priority": "urgent"}
    resp = await client.put(
        f"/api/owner/schedules/{sample_schedule.id}",
        json=update_data,
        headers=owner_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["title"] == "Updated Strategy Workshop"
    assert data["priority"] == "urgent"


@pytest.mark.asyncio
async def test_soft_delete_and_restore(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    # 1. Soft delete
    del_resp = await client.delete(f"/api/owner/schedules/{sample_schedule.id}", headers=owner_headers)
    assert del_resp.status_code == 200
    assert del_resp.json()["is_deleted"] is True

    # 2. Check not in active list
    list_resp = await client.get("/api/owner/schedules", headers=owner_headers)
    ids = [it["id"] for it in list_resp.json()["items"]]
    assert sample_schedule.id not in ids

    # 3. Restore
    restore_resp = await client.post(f"/api/owner/schedules/{sample_schedule.id}/restore", headers=owner_headers)
    assert restore_resp.status_code == 200
    assert restore_resp.json()["is_deleted"] is False

    # 4. Check back in active list
    list_resp2 = await client.get("/api/owner/schedules", headers=owner_headers)
    ids2 = [it["id"] for it in list_resp2.json()["items"]]
    assert sample_schedule.id in ids2


@pytest.mark.asyncio
async def test_duplicate_schedule(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    resp = await client.post(f"/api/owner/schedules/{sample_schedule.id}/duplicate", headers=owner_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["id"] != sample_schedule.id
    assert data["title"] == f"Copy of {sample_schedule.title}"


@pytest.mark.asyncio
async def test_bulk_actions(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    # Bulk status change
    resp = await client.post(
        "/api/owner/schedules/bulk",
        json={
            "action": "status_change",
            "item_ids": [sample_schedule.id],
            "data": {"status": "Done"},
        },
        headers=owner_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["success_count"] == 1

    # Verify updated
    get_resp = await client.get(f"/api/owner/schedules/{sample_schedule.id}", headers=owner_headers)
    assert get_resp.json()["status"] == "Done"
