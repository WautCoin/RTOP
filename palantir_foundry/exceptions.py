"""Exception hierarchy for the Palantir Foundry SDK."""

from __future__ import annotations

from typing import Optional


class FoundryError(Exception):
    """Base exception for all Foundry SDK errors."""

    def __init__(self, message: str, status_code: Optional[int] = None) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.message = message

    def __repr__(self) -> str:
        return f"{type(self).__name__}(status_code={self.status_code}, message={self.message!r})"


class AuthenticationError(FoundryError):
    """Raised when authentication fails (HTTP 401)."""


class ForbiddenError(FoundryError):
    """Raised when the caller lacks permission (HTTP 403)."""


class NotFoundError(FoundryError):
    """Raised when a requested resource does not exist (HTTP 404)."""


class ConflictError(FoundryError):
    """Raised on resource conflicts (HTTP 409)."""


class RateLimitError(FoundryError):
    """Raised when the API rate limit is exceeded (HTTP 429)."""


class ServerError(FoundryError):
    """Raised on unexpected server-side errors (HTTP 5xx)."""


class ValidationError(FoundryError):
    """Raised when the request payload is invalid (HTTP 400)."""


_STATUS_TO_EXCEPTION: dict[int, type[FoundryError]] = {
    400: ValidationError,
    401: AuthenticationError,
    403: ForbiddenError,
    404: NotFoundError,
    409: ConflictError,
    429: RateLimitError,
}


def raise_for_status(response: "requests.Response") -> None:  # type: ignore[name-defined]  # noqa: F821
    """Raise the appropriate :class:`FoundryError` subclass for an HTTP error response."""
    if response.ok:
        return

    status = response.status_code
    try:
        detail = response.json()
        message = detail.get("message") or detail.get("errorName") or response.text
    except Exception:
        message = response.text or f"HTTP {status}"

    exc_class = _STATUS_TO_EXCEPTION.get(status)
    if exc_class is None:
        exc_class = ServerError if status >= 500 else FoundryError
    raise exc_class(message, status_code=status)
