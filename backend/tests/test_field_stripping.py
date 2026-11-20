"""CRITICAL TEST SUITE: Field Stripping Enforcement.

Proves that privacy controls strictly strip hidden fields from the server-side dictionary
so they are NEVER returned over the wire (fields absent, not just null).
"""

import pytest
from src.utils.field_stripper import strip_fields


def test_strip_hide_amounts():
    item = {
        "id": "123",
        "title": "Hospital Donation",
        "amount_requested": 50000.0,
        "given_amount": 45000.0,
        "status": "Given",
        "organization": "City Hospital",
    }
    stripped = strip_fields(item, {"hide_amounts": True})
    assert "amount_requested" not in stripped
    assert "given_amount" not in stripped
    assert "title" in stripped
    assert "organization" in stripped


def test_strip_hide_contacts():
    item = {
        "id": "123",
        "title": "Outreach",
        "organization": "Charity Corp",
        "contact_person": "Jane Doe",
        "phone": "+1-555-1234",
        "email": "jane@charity.org",
        "given_by": "Donor X",
        "given_to": "Community Y",
        "status": "Active",
    }
    stripped = strip_fields(item, {"hide_contacts": True})
    assert "organization" not in stripped
    assert "contact_person" not in stripped
    assert "phone" not in stripped
    assert "email" not in stripped
    assert "given_by" not in stripped
    assert "given_to" not in stripped
    assert "title" in stripped


def test_strip_hide_notes():
    item = {
        "id": "123",
        "title": "Event",
        "notes": "Sensitive internal donor remarks",
        "description": "Sensitive description details",
        "status": "Active",
    }
    stripped = strip_fields(item, {"hide_notes": True})
    assert "notes" not in stripped
    assert "description" not in stripped
    assert "title" in stripped


def test_strip_hide_attachments():
    item = {
        "id": "123",
        "title": "Solicitation",
        "receipt_proof": "/confidential/receipts/doc_99.pdf",
        "attachments": ["file1.pdf"],
        "status": "Active",
    }
    stripped = strip_fields(item, {"hide_attachments": True})
    assert "receipt_proof" not in stripped
    assert "attachments" not in stripped
    assert "title" in stripped


def test_strip_summary_only():
    item = {
        "id": "123",
        "title": "High Level Meeting",
        "description": "Detailed notes",
        "location": "Secret Bunker",
        "status": "Active",
        "priority": "urgent",
        "category": "Strategy",
        "event_date": "2026-05-10",
        "notes": "Top secret",
        "amount_requested": 1000000.0,
        "phone": "+1-555-9999",
    }
    stripped = strip_fields(item, {"summary_only": True})
    expected_allowed = {
        "id", "title", "status", "priority", "category", "event_date", "start_time", "end_time", "all_day", "requested_date", "deadline", "created_at", "updated_at"
    }
    for k in stripped.keys():
        assert k in expected_allowed

    assert "description" not in stripped
    assert "location" not in stripped
    assert "notes" not in stripped
    assert "amount_requested" not in stripped
    assert "phone" not in stripped


def test_combined_stripping():
    item = {
        "id": "123",
        "title": "Combined Case",
        "amount_requested": 25000.0,
        "contact_person": "Bob Ross",
        "notes": "Private note",
        "status": "Draft",
    }
    stripped = strip_fields(item, {"hide_amounts": True, "hide_contacts": True, "hide_notes": True})
    assert "amount_requested" not in stripped
    assert "contact_person" not in stripped
    assert "notes" not in stripped
    assert stripped["title"] == "Combined Case"
    assert stripped["status"] == "Draft"
