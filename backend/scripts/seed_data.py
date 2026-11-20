"""Seed database with 5,000 realistic records (2,500 schedules + 2,500 solicitations)."""

import asyncio
import random
import uuid
from datetime import date, datetime, time, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import async_session_factory, init_db
from src.core.security import hash_password
from src.models.user import User
from src.models.schedule import Schedule
from src.models.solicitation import Solicitation

EVENT_TITLES = [
    "Annual General Meeting", "Community Outreach Program", "Board of Directors Review",
    "Quarterly Strategy Session", "Volunteer Orientation", "Budget Planning Workshop",
    "Charity Gala Dinner", "Youth Leadership Summit", "Health & Wellness Fair",
    "Environmental Cleanup Drive", "Food Distribution Drive", "Tech Team Sprint Retrospective",
    "Sponsor Appreciation Night", "Donor Recognition Banquet", "Disaster Relief Briefing"
]

LOCATIONS = [
    "Main Auditorium", "City Conference Hall", "Community Center Room B",
    "Virtual - Zoom", "District Civic Hall", "Grand Plaza Hotel",
    "St. Jude Parish Hall", "Regional Headquarters", "Downtown Library Room 3"
]

CATEGORIES_SCHED = ["Meeting", "Outreach", "Workshop", "Conference", "Social", "Training"]
PRIORITIES = ["low", "medium", "high", "urgent"]
STATUSES_SCHED = ["Active", "Done", "Cancelled", "Past"]

SOL_TITLES = [
    "School Supplies for Elementary Students", "Medical Equipment Donation", "Community Feeding Program",
    "Disaster Relief Kits", "Youth Sports Uniforms & Gear", "Classroom Renovation Assistance",
    "Senior Citizens Grocery Subsidy", "Clean Water Filtration Project", "Winter Blanket Distribution",
    "Emergency Medicine Fund"
]

ORGS = [
    "Rotary Club Central", "Lions Club International", "Apex Foundation",
    "San Miguel Corporation", "BDO Foundation", "Red Cross Chapter 1",
    "St. Mary's Charity League", "Global Hope Initiative", "Barangay Health Workers Alliance"
]

CONTACT_PERSONS = [
    "Maria Santos", "Juan dela Cruz", "Carlos Reyes", "Patricia Gomez",
    "Elena Tan", "David Miller", "Sarah Jenkins", "Arthur Pendelton"
]

CATEGORIES_SOL = ["Education", "Healthcare", "Disaster Relief", "Community Development", "Livelihood"]
STATUSES_SOL = ["Draft", "Sent", "Pending", "Approved", "Declined", "Given", "Done", "Cancelled"]


async def seed():
    print("Initializing database...")
    await init_db()

    async with async_session_factory() as session:
        # Create default test user
        user_id = str(uuid.uuid4())
        user = User(
            id=user_id,
            username="admin",
            password_hash=hash_password("admin123"),
            display_name="System Administrator",
            email="admin@schedsolicit.org",
        )
        session.add(user)
        await session.flush()
        print(f"Created default user: admin / admin123 (ID: {user_id})")

        base_date = date(2026, 1, 1)

        # 2,500 Schedules
        print("Generating 2,500 schedules...")
        schedules = []
        for i in range(2500):
            event_d = base_date + timedelta(days=random.randint(0, 365))
            start_h = random.randint(8, 17)
            s_time = time(start_h, 0)
            e_time = time(start_h + random.randint(1, 3), 0)
            status_val = random.choices(STATUSES_SCHED, weights=[40, 30, 10, 20])[0]

            s = Schedule(
                title=f"{random.choice(EVENT_TITLES)} #{i + 1}",
                description=f"Operational agenda details for session #{i + 1}.",
                event_date=event_d,
                start_time=s_time,
                end_time=e_time,
                all_day=random.random() < 0.1,
                location=random.choice(LOCATIONS),
                category=random.choice(CATEGORIES_SCHED),
                priority=random.choice(PRIORITIES),
                status=status_val,
                notes="Standard operating procedure applies.",
                user_id=user_id,
            )
            schedules.append(s)

            if len(schedules) >= 500:
                session.add_all(schedules)
                await session.flush()
                schedules.clear()
        if schedules:
            session.add_all(schedules)
            await session.flush()

        print("2,500 schedules created.")

        # 2,500 Solicitations
        print("Generating 2,500 solicitations...")
        solicitations = []
        for i in range(2500):
            req_d = base_date + timedelta(days=random.randint(0, 300))
            deadline_d = req_d + timedelta(days=random.randint(14, 45))
            status_val = random.choices(STATUSES_SOL, weights=[15, 20, 25, 15, 10, 10, 3, 2])[0]
            amt_req = round(random.uniform(500, 50000), 2)

            given_date_val = None
            given_amount_val = None
            given_by_val = None
            given_to_val = None
            given_item_val = None

            if status_val in ["Given", "Done"]:
                given_date_val = deadline_d + timedelta(days=random.randint(1, 10))
                given_amount_val = round(amt_req * random.uniform(0.8, 1.0), 2)
                given_by_val = random.choice(ORGS)
                given_to_val = "Community Beneficiaries"
                given_item_val = "Financial Subsidy & Resource Packs"

            sol = Solicitation(
                title=f"{random.choice(SOL_TITLES)} #{i + 1}",
                purpose=f"Formal request support document ref #{i + 1}.",
                organization=random.choice(ORGS),
                contact_person=random.choice(CONTACT_PERSONS),
                phone=f"+1-555-{random.randint(100, 999):03d}-{random.randint(1000, 9999):04d}",
                email=f"contact_{i}@charitypartner.org",
                amount_requested=amt_req,
                quantity_requested=f"{random.randint(10, 500)} units",
                requested_date=req_d,
                deadline=deadline_d,
                follow_up_date=req_d + timedelta(days=7),
                status=status_val,
                priority=random.choice(PRIORITIES),
                category=random.choice(CATEGORIES_SOL),
                location=random.choice(LOCATIONS),
                notes="Review and follow up according to donor protocol.",
                given_date=given_date_val,
                given_amount=given_amount_val,
                given_item=given_item_val,
                given_by=given_by_val,
                given_to=given_to_val,
                user_id=user_id,
            )
            solicitations.append(sol)

            if len(solicitations) >= 500:
                session.add_all(solicitations)
                await session.flush()
                solicitations.clear()
        if solicitations:
            session.add_all(solicitations)
            await session.flush()

        await session.commit()
        print("2,500 solicitations created.")
        print("Seeding completed successfully! Total 5,000 records.")


if __name__ == "__main__":
    asyncio.run(seed())
