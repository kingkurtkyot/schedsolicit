"""Tests for Solicitation CRUD, given_* fulfillment tracking, and status transitions."""

import pytest
from httpx import AsyncClient
from src.models.solicitation import Solicitation


@pytest.mark.asyncio
async def test_create_solicitation(client: AsyncClient, owner_headers: dict):
    payload = {
        "title": "Hospital Bed Donation",
        "organization": "City General Hospital",
        "contact_person": "Dr. Sarah Lee",
        "amount_requested": 50000.0,
        "requested_date": "2026-07-01",
        "deadline": "2026-07-30",
        "status": "Draft",
        "priority": "urgent",
        "category": "Healthcare",
    }
    resp = await client.post("/api/owner/solicitations", json=payload, headers=owner_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == payload["title"]
    assert data["amount_requested"] == 50000.0
    assert "id" in data


@pytest.mark.asyncio
async def test_update_given_fields(client: AsyncClient, owner_headers: dict, sample_solicitation: Solicitation):
    given_payload = {
        "given_date": "2026-05-15",
        "given_amount": 1500.0,
        "given_item": "500 Illustrated Children Books",
        "given_by": "Readers United Corp",
        "given_to": "Elementary Library Rep",
        "receipt_proof": "uploads/receipts/proof_123.pdf",
    }
    resp = await client.put(
        f"/api/owner/solicitations/{sample_solicitation.id}/given",
        json=given_payload,
        headers=owner_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["given_amount"] == 1500.0
    assert data["given_item"] == "500 Illustrated Children Books"
    # Verify auto status transition to "Given"
    assert data["status"] == "Given"


@pytest.mark.asyncio
async def test_solicitation_soft_delete_and_restore(
    client: AsyncClient, owner_headers: dict, sample_solicitation: Solicitation
):
    del_resp = await client.delete(
        f"/api/owner/solicitations/{sample_solicitation.id}", headers=owner_headers
    )
    assert del_resp.status_code == 200
    assert del_resp.json()["is_deleted"] is True

    restore_resp = await client.post(
        f"/api/owner/solicitations/{sample_solicitation.id}/restore", headers=owner_headers
    )
    assert restore_resp.status_code == 200
    assert restore_resp.json()["is_deleted"] is False
