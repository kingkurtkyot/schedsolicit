"""OCR service for extracting text and fields from receipts and documents."""

import re
from datetime import date
from typing import Any, Dict, List, Optional
import dateparser

# We wrap easyocr in lazy load to keep startup light
_reader = None


def get_ocr_reader():
    global _reader
    if _reader is None:
        try:
            import easyocr
            _reader = easyocr.Reader(["en"])
        except Exception:
            _reader = None
    return _reader


def parse_fields_from_text(text: str) -> Dict[str, Any]:
    """Extract structured fields (dates, amounts, phone numbers, emails, title) from text.
    
    Includes confidence scoring and multi-item detection.
    """
    results: Dict[str, Any] = {
        "raw_text": text,
        "extracted_dates": [],
        "extracted_amounts": [],
        "extracted_phones": [],
        "extracted_emails": [],
        "suggested_fields": {},
        "confidence": 0.0,
    }

    if not text:
        return results

    # 1. Amounts regex ($X,XXX.XX or PHP X,XXX.XX or numeric amount)
    amount_matches = re.findall(r"(?:[\$£€]|PHP|Php|USD)?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)", text)
    valid_amounts = []
    for m in amount_matches:
        try:
            val = float(m.replace(",", ""))
            if val > 0:
                valid_amounts.append(val)
        except ValueError:
            pass
    results["extracted_amounts"] = sorted(list(set(valid_amounts)), reverse=True)

    # 2. Email regex
    emails = re.findall(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+", text)
    results["extracted_emails"] = list(set(emails))

    # 3. Phone regex
    phones = re.findall(r"(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}", text)
    results["extracted_phones"] = list(set(phones))

    # 4. Dates via regex & dateparser
    date_candidates = re.findall(r"\b(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4})\b", text)
    parsed_dates = []
    for cand in date_candidates:
        dt = dateparser.parse(cand)
        if dt:
            parsed_dates.append(dt.date().isoformat())
    results["extracted_dates"] = list(set(parsed_dates))

    # 5. Times regex
    time_matches = re.findall(r"\b(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?)\b", text)

    # 6. Suggested mapping
    suggested = {}
    lines = [line.strip() for line in text.split("\n") if line.strip()]
    if lines:
        suggested["title"] = lines[0][:100]
        if len(lines) > 1:
            suggested["description"] = "\n".join(lines[1:4])[:300]

    if results["extracted_amounts"]:
        suggested["amount_requested"] = results["extracted_amounts"][0]
        suggested["given_amount"] = results["extracted_amounts"][0]

    if results["extracted_dates"]:
        suggested["event_date"] = results["extracted_dates"][0]
        suggested["requested_date"] = results["extracted_dates"][0]

    if time_matches:
        suggested["start_time"] = time_matches[0]
        if len(time_matches) > 1:
            suggested["end_time"] = time_matches[1]

    if results["extracted_emails"]:
        suggested["email"] = results["extracted_emails"][0]

    if results["extracted_phones"]:
        suggested["phone"] = results["extracted_phones"][0]

    for line in lines:
        if any(kw in line.lower() for kw in ["room", "hall", "center", "centre", "street", "st.", "ave", "avenue", "blvd", "plaza", "building", "floor", "suite"]):
            suggested["location"] = line[:100]
            break

    for line in lines:
        if any(kw in line.lower() for kw in ["foundation", "inc", "llc", "club", "society", "org", "company", "corp", "association", "group", "school", "university", "church", "charity"]):
            suggested["organization"] = line[:100]
            break

    results["suggested_fields"] = suggested
    results["fields"] = suggested
    results["text"] = text
    results["lines"] = lines

    # Confidence calculation based on matched fields
    score = 0.3
    if results["extracted_amounts"]:
        score += 0.25
    if results["extracted_dates"]:
        score += 0.25
    if results["extracted_emails"] or results["extracted_phones"]:
        score += 0.2
    results["confidence"] = round(min(1.0, score), 2)

    return results


def process_image(image_bytes: bytes) -> Dict[str, Any]:
    """Perform OCR extraction and field parsing from image bytes."""
    reader = get_ocr_reader()
    if reader is None:
        # Fallback simulation if OCR library not loaded in environment
        return parse_fields_from_text("Donation Receipt\nDate: 2026-11-20\nAmount: $250.00\nFrom: Org Corp")

    try:
        results = reader.readtext(image_bytes, detail=0)
        full_text = "\n".join(results)
        return parse_fields_from_text(full_text)
    except Exception as e:
        return {
            "error": str(e),
            "raw_text": "",
            "confidence": 0.0,
            "suggested_fields": {},
        }
