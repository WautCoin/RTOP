"""Shared HTTP session wrapper with retry logic and auth header injection."""

from __future__ import annotations

from typing import Any, Dict, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .exceptions import raise_for_status

_DEFAULT_RETRY = Retry(
    total=3,
    backoff_factor=0.5,
    status_forcelist=[500, 502, 503, 504],
    allowed_methods=["GET", "PUT", "POST", "DELETE", "PATCH", "HEAD", "OPTIONS"],
    raise_on_status=False,
)


class Session:
    """Thin wrapper around :class:`requests.Session` that injects auth and handles errors.

    Args:
        base_url: Foundry hostname, e.g. ``https://my-foundry.example.com``.
        token_provider: Callable that returns the current bearer token string.
        verify_ssl: Whether to verify TLS certificates.
        retry: Custom :class:`urllib3.util.retry.Retry` policy; uses sensible defaults if *None*.
    """

    def __init__(
        self,
        base_url: str,
        token_provider: "TokenProvider",  # type: ignore[name-defined]  # noqa: F821
        *,
        verify_ssl: bool = True,
        retry: Optional[Retry] = None,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._token_provider = token_provider
        self._verify_ssl = verify_ssl
        self._session = self._build_session(retry or _DEFAULT_RETRY)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_session(self, retry: Retry) -> requests.Session:
        session = requests.Session()
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("https://", adapter)
        session.mount("http://", adapter)
        session.verify = self._verify_ssl
        return session

    def _headers(self, extra: Optional[Dict[str, str]] = None) -> Dict[str, str]:
        token = self._token_provider.get_token()
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        if extra:
            headers.update(extra)
        return headers

    def _url(self, path: str) -> str:
        return f"{self._base_url}/{path.lstrip('/')}"

    # ------------------------------------------------------------------
    # Public HTTP verbs
    # ------------------------------------------------------------------

    def get(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs: Any,
    ) -> requests.Response:
        resp = self._session.get(
            self._url(path),
            params=params,
            headers=self._headers(headers),
            **kwargs,
        )
        raise_for_status(resp)
        return resp

    def post(
        self,
        path: str,
        json: Optional[Any] = None,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs: Any,
    ) -> requests.Response:
        resp = self._session.post(
            self._url(path),
            json=json,
            params=params,
            headers=self._headers(headers),
            **kwargs,
        )
        raise_for_status(resp)
        return resp

    def put(
        self,
        path: str,
        json: Optional[Any] = None,
        data: Optional[Any] = None,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs: Any,
    ) -> requests.Response:
        resp = self._session.put(
            self._url(path),
            json=json,
            data=data,
            params=params,
            headers=self._headers(headers),
            **kwargs,
        )
        raise_for_status(resp)
        return resp

    def delete(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs: Any,
    ) -> requests.Response:
        resp = self._session.delete(
            self._url(path),
            params=params,
            headers=self._headers(headers),
            **kwargs,
        )
        raise_for_status(resp)
        return resp

    def patch(
        self,
        path: str,
        json: Optional[Any] = None,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs: Any,
    ) -> requests.Response:
        resp = self._session.patch(
            self._url(path),
            json=json,
            params=params,
            headers=self._headers(headers),
            **kwargs,
        )
        raise_for_status(resp)
        return resp
