"""Tests for append-only audit trail logging, timeline, and immutable created_at."""

from datetime import datetime, timezone
import pytest
from httpx import AsyncClient
from src.models.schedule import Schedule


@pytest.mark.asyncio
async def test_audit_log_on_create_and_update(client: AsyncClient, owner_headers: dict):
    # 1. Create schedule
    create_payload = {
        "title": "Audit Test Event",
        "event_date": "2026-11-15",
        "status": "Active",
    }
    create_resp = await client.post("/api/owner/schedules", json=create_payload, headers=owner_headers)
    assert create_resp.status_code == 201
    item_id = create_resp.json()["id"]
    orig_created_at = create_resp.json()["created_at"]

    # 2. Update schedule
    update_payload = {"title": "Updated Audit Title", "priority": "urgent"}
    update_resp = await client.put(f"/api/owner/schedules/{item_id}", json=update_payload, headers=owner_headers)
    assert update_resp.status_code == 200
    # Ensure created_at never changes on update
    assert update_resp.json()["created_at"].rstrip("Z") == orig_created_at.rstrip("Z")

    # 3. Retrieve item audit timeline
    timeline_resp = await client.get(f"/api/owner/audit-log/{item_id}", headers=owner_headers)
    assert timeline_resp.status_code == 200
    timeline = timeline_resp.json()
    assert len(timeline) >= 2  # create action + update actions
    actions = [entry["action"] for entry in timeline]
    assert "create" in actions
    assert "update" in actions
