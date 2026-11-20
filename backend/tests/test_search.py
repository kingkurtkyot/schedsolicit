"""Tests for FTS5 full-text search with relevance ranking, prefix search, and fallbacks."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.schedule import Schedule
from src.models.user import User
from datetime import date


@pytest.mark.asyncio
async def test_search_schedules(
    client: AsyncClient, owner_headers: dict, db_session: AsyncSession, test_user: User
):
    items = [
        Schedule(
            title="Annual Charity Gala 2026",
            description="Grand dinner and fund raising",
            location="Metropolitan Grand Ballroom",
            event_date=date(2026, 9, 20),
            notes="Black tie formal attire",
            user_id=test_user.id,
        ),
        Schedule(
            title="Youth Leadership Summit",
            description="Training student leaders for civic action",
            location="Community Center",
            event_date=date(2026, 9, 25),
            notes="Mention charity projects during intro",
            user_id=test_user.id,
        ),
        Schedule(
            title="Quarterly Budget Review",
            description="Financial statement audit",
            location="Headquarters",
            event_date=date(2026, 10, 1),
            notes="Review department allocations",
            user_id=test_user.id,
        ),
        Schedule(
            title="Blood Donation Drive",
            description="Partnership with Red Cross",
            location="Hospital Courtyard",
            event_date=date(2026, 10, 5),
            notes="Target 100 donors",
            user_id=test_user.id,
        ),
    ]
    db_session.add_all(items)
    await db_session.flush()

    # Test 1: Title query match
    res1 = await client.get("/api/owner/schedules/search?q=Charity", headers=owner_headers)
    assert res1.status_code == 200
    results1 = res1.json()
    assert len(results1) >= 1
    # Charity in title should rank first
    assert "Charity Gala" in results1[0]["title"]

    # Test 2: Prefix search
    res2 = await client.get("/api/owner/schedules/search?q=Lead", headers=owner_headers)
    assert res2.status_code == 200
    results2 = res2.json()
    assert any("Leadership" in r["title"] for r in results2)

    # Test 3: Location search
    res3 = await client.get("/api/owner/schedules/search?q=Ballroom", headers=owner_headers)
    assert res3.status_code == 200
    results3 = res3.json()
    assert any("Charity Gala" in r["title"] for r in results3)

    # Test 4: Search with no match returns empty list
    res4 = await client.get("/api/owner/schedules/search?q=NonExistentTermXYZ", headers=owner_headers)
    assert res4.status_code == 200
    assert len(res4.json()) == 0
