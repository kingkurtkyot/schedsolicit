"""Tests for server-side export in CSV and JSON formats."""

import json
import pytest
from httpx import AsyncClient
from src.models.schedule import Schedule


@pytest.mark.asyncio
async def test_export_json(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    req_payload = {
        "module": "schedule",
        "format": "json",
        "title": "Test JSON Export",
    }
    resp = await client.post("/api/owner/export", json=req_payload, headers=owner_headers)
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("application/json")
    data = json.loads(resp.text)
    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["title"] == sample_schedule.title


@pytest.mark.asyncio
async def test_export_csv(client: AsyncClient, owner_headers: dict, sample_schedule: Schedule):
    req_payload = {
        "module": "schedule",
        "format": "csv",
        "title": "Test CSV Export",
    }
    resp = await client.post("/api/owner/export", json=req_payload, headers=owner_headers)
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("text/csv")
    csv_text = resp.text
    assert "title" in csv_text
    assert sample_schedule.title in csv_text
