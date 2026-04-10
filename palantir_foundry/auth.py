"""Authentication providers for the Palantir Foundry SDK."""

from __future__ import annotations

import time
from typing import Any, Callable, Dict, Optional

import requests


class TokenProvider:
    """Abstract interface for auth token providers."""

    def get_token(self) -> str:
        raise NotImplementedError


class BearerTokenAuth(TokenProvider):
    """Simple static bearer token provider.

    Args:
        token: A long-lived Foundry API token (e.g., from the Developer Console).
    """

    def __init__(self, token: str) -> None:
        if not token:
            raise ValueError("token must be a non-empty string")
        self._token = token

    def get_token(self) -> str:
        return self._token


class OAuth2ClientCredentials(TokenProvider):
    """OAuth2 *client_credentials* flow with automatic token refresh.

    The provider fetches a new token from ``{hostname}/multipass/api/oauth2/token``
    and caches it until it is within *refresh_before_expiry* seconds of expiring.

    Args:
        hostname: Foundry base URL, e.g. ``https://my-foundry.example.com``.
        client_id: OAuth2 client ID.
        client_secret: OAuth2 client secret.
        scopes: Space-separated list of scopes to request.
        refresh_before_expiry: Seconds before expiry to refresh the token (default 60 s).
        verify_ssl: Whether to verify TLS certificates on token requests.
        _http_post: Injectable callable for testing; defaults to ``requests.post``.
    """

    _TOKEN_ENDPOINT = "/multipass/api/oauth2/token"

    def __init__(
        self,
        hostname: str,
        client_id: str,
        client_secret: str,
        scopes: str = "api:read-data api:write-data",
        refresh_before_expiry: int = 60,
        verify_ssl: bool = True,
        _http_post: Optional[Callable[..., Any]] = None,
    ) -> None:
        self._hostname = hostname.rstrip("/")
        self._client_id = client_id
        self._client_secret = client_secret
        self._scopes = scopes
        self._refresh_before_expiry = refresh_before_expiry
        self._verify_ssl = verify_ssl
        self._http_post: Callable[..., Any] = _http_post or requests.post
        self._access_token: Optional[str] = None
        self._expires_at: float = 0.0

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _fetch_token(self) -> None:
        url = f"{self._hostname}{self._TOKEN_ENDPOINT}"
        resp = self._http_post(
            url,
            data={
                "grant_type": "client_credentials",
                "client_id": self._client_id,
                "client_secret": self._client_secret,
                "scope": self._scopes,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            verify=self._verify_ssl,
            timeout=30,
        )
        if not resp.ok:
            from .exceptions import AuthenticationError

            try:
                detail = resp.json().get("error_description", resp.text)
            except Exception:
                detail = resp.text
            raise AuthenticationError(
                f"Failed to obtain OAuth2 token: {detail}", status_code=resp.status_code
            )

        data: Dict[str, Any] = resp.json()
        self._access_token = data["access_token"]
        expires_in: int = data.get("expires_in", 3600)
        self._expires_at = time.monotonic() + expires_in

    def _is_expired(self) -> bool:
        return time.monotonic() >= self._expires_at - self._refresh_before_expiry

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_token(self) -> str:
        if self._access_token is None or self._is_expired():
            self._fetch_token()
        if self._access_token is None:
            raise RuntimeError("OAuth2 token fetch succeeded but access_token was not set")
        return self._access_token
