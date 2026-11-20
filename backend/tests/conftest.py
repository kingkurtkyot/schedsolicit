"""Pytest fixtures and test environment configuration."""

import asyncio
from datetime import date, datetime, time, timezone
from typing import AsyncGenerator
import uuid

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from src.core.database import Base, get_db, setup_fts5
from src.core.security import create_access_token, create_viewer_token, hash_password
from src.main import app
from src.models.schedule import Schedule
from src.models.share_link import ShareLink
from src.models.solicitation import Solicitation
from src.models.user import User

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test_schedsolicit.db"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestingSessionLocal = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_test_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with TestingSessionLocal() as session:
        await setup_fts5(session)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        username=f"testuser_{user_id[:8]}",
        password_hash=hash_password("Secret123!"),
        display_name="Test Owner",
        email=f"user_{user_id[:8]}@example.com",
    )
    db_session.add(user)
    await db_session.flush()
    return user


@pytest_asyncio.fixture
def owner_token(test_user: User) -> str:
    return create_access_token(test_user.id)


@pytest_asyncio.fixture
def owner_headers(owner_token: str) -> dict:
    return {"Authorization": f"Bearer {owner_token}"}


@pytest_asyncio.fixture
async def test_share_link(db_session: AsyncSession, test_user: User) -> ShareLink:
    link = ShareLink(
        token=f"token_{uuid.uuid4().hex[:16]}",
        label="Test Shared Scope",
        scope={"modules": ["schedule", "solicitation"]},
        privacy_controls={"hide_amounts": True, "hide_contacts": True},
        allow_export=True,
        user_id=test_user.id,
    )
    db_session.add(link)
    await db_session.flush()
    return link


@pytest_asyncio.fixture
def viewer_token(test_share_link: ShareLink) -> str:
    return create_viewer_token(
        share_link_id=test_share_link.id,
        scope={"scope": test_share_link.scope, "privacy_controls": test_share_link.privacy_controls},
    )


@pytest_asyncio.fixture
def viewer_headers(viewer_token: str) -> dict:
    return {"Authorization": f"Bearer {viewer_token}"}


@pytest_asyncio.fixture
async def sample_schedule(db_session: AsyncSession, test_user: User) -> Schedule:
    sched = Schedule(
        title="Quarterly Review Meeting",
        description="Comprehensive quarterly progress assessment.",
        event_date=date(2026, 4, 15),
        start_time=time(10, 0),
        end_time=time(12, 0),
        all_day=False,
        location="Boardroom A",
        category="Meeting",
        priority="high",
        status="Active",
        notes="Prepare financial slides",
        user_id=test_user.id,
    )
    db_session.add(sched)
    await db_session.flush()
    return sched


@pytest_asyncio.fixture
async def sample_solicitation(db_session: AsyncSession, test_user: User) -> Solicitation:
    sol = Solicitation(
        title="Community Library Books Donation",
        organization="Readers United Corp",
        contact_person="Alice Walker",
        phone="+1-555-0192",
        email="alice@readersunited.org",
        purpose="Supply 500 books to children in need",
        amount_requested=1500.0,
        requested_date=date(2026, 5, 1),
        deadline=date(2026, 5, 20),
        status="Draft",
        priority="urgent",
        category="Education",
        location="Community Library",
        notes="High donor responsiveness expected",
        user_id=test_user.id,
    )
    db_session.add(sol)
    await db_session.flush()
    return sol
