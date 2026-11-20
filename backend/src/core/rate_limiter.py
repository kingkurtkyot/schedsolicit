"""Rate limiting with slowapi and passcode lockout."""

import time
from collections import defaultdict
from typing import Dict, Tuple

from fastapi import Request, HTTPException, status
from slowapi import Limiter
from slowapi.util import get_remote_address

from src.core.config import settings

limiter = Limiter(key_func=get_remote_address, default_limits=[settings.RATE_LIMIT_DEFAULT])


class PasscodeLockout:
    """Track passcode attempts and enforce lockout after too many failures.

    10 attempts → 15 minute lockout (configurable via settings).
    """

    def __init__(self):
        self._attempts: Dict[str, list] = defaultdict(list)
        self._lockouts: Dict[str, float] = {}

    def _clean_old_attempts(self, key: str) -> None:
        """Remove attempts older than the lockout window."""
        cutoff = time.time() - (settings.PASSCODE_LOCKOUT_MINUTES * 60)
        self._attempts[key] = [t for t in self._attempts[key] if t > cutoff]

    def check_locked(self, key: str) -> bool:
        """Check if the key is currently locked out."""
        lockout_until = self._lockouts.get(key)
        if lockout_until and time.time() < lockout_until:
            return True
        if lockout_until and time.time() >= lockout_until:
            del self._lockouts[key]
            self._attempts[key] = []
        return False

    def record_attempt(self, key: str) -> None:
        """Record a failed attempt. Lock out if threshold reached."""
        self._clean_old_attempts(key)
        self._attempts[key].append(time.time())
        if len(self._attempts[key]) >= settings.PASSCODE_MAX_ATTEMPTS:
            self._lockouts[key] = time.time() + (settings.PASSCODE_LOCKOUT_MINUTES * 60)

    def record_success(self, key: str) -> None:
        """Clear attempts on successful validation."""
        self._attempts.pop(key, None)
        self._lockouts.pop(key, None)

    def get_remaining_attempts(self, key: str) -> int:
        """Return how many attempts remain before lockout."""
        self._clean_old_attempts(key)
        return max(0, settings.PASSCODE_MAX_ATTEMPTS - len(self._attempts[key]))

    def get_lockout_remaining_seconds(self, key: str) -> int:
        """Return seconds remaining in lockout, 0 if not locked."""
        lockout_until = self._lockouts.get(key)
        if lockout_until and time.time() < lockout_until:
            return int(lockout_until - time.time())
        return 0

    def assert_not_locked(self, key: str) -> None:
        """Raise 429 if the key is locked out."""
        if self.check_locked(key):
            remaining = self.get_lockout_remaining_seconds(key)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Too many attempts. Try again in {remaining} seconds.",
            )


passcode_lockout = PasscodeLockout()
