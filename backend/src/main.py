"""FastAPI main application entry point."""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from starlette.middleware.base import BaseHTTPMiddleware

from src.api.owner import owner_router
from src.api.view import viewer_router
from src.core.config import settings
from src.core.database import init_db
from src.core.rate_limiter import limiter


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Inject strict security headers into all responses."""

    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' *;"
        )
        return response


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: setup database and FTS5
    await init_db()
    yield
    # Shutdown logic if any


app = FastAPI(
    title="SchedSolicit API",
    description="Backend API for SchedSolicit: unified event schedules and solicitation tracking.",
    version="1.0.0",
    lifespan=lifespan,
)

# State & Rate Limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Middlewares
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routers
app.include_router(owner_router)
app.include_router(viewer_router)


@app.get("/health")
@app.get("/api/health")
@app.get("/api/owner/health")
@app.get("/api/view/health")
async def health_check():
    return {"status": "ok", "service": "SchedSolicit API"}
