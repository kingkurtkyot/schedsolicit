"""Tests for OCR text parsing (dates, amounts, emails, phones, suggested mapping)."""

import pytest
from src.services.ocr_service import parse_fields_from_text


def test_ocr_field_parsing_receipt():
    sample_text = """
    OFFICIAL RECEIPT
    Apex Charity Foundation
    Date: 2026-05-12
    Contact: support@apexcharity.org
    Phone: (555) 234-5678
    Total Donation Amount: $12,500.00
    Thank you for your generous support!
    """
    res = parse_fields_from_text(sample_text)

    assert 12500.0 in res["extracted_amounts"]
    assert "2026-05-12" in res["extracted_dates"]
    assert "support@apexcharity.org" in res["extracted_emails"]
    assert "(555) 234-5678" in res["extracted_phones"] or any("555" in p for p in res["extracted_phones"])
    assert res["confidence"] >= 0.8
    assert res["suggested_fields"]["amount_requested"] == 12500.0


def test_ocr_field_parsing_empty_text():
    res = parse_fields_from_text("")
    assert res["confidence"] == 0.0
    assert len(res["extracted_amounts"]) == 0
    assert len(res["extracted_dates"]) == 0
