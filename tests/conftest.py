"""Shared pytest fixtures for the Palantir Foundry SDK test suite."""

from __future__ import annotations

from typing import Any
from unittest.mock import MagicMock, patch

import pytest

from palantir_foundry._http import Session
from palantir_foundry.auth import BearerTokenAuth
from palantir_foundry.client import FoundryClient


HOSTNAME = "https://foundry.example.com"
TOKEN = "test-token-abc123"


@pytest.fixture
def token_provider() -> BearerTokenAuth:
    return BearerTokenAuth(TOKEN)


@pytest.fixture
def mock_requests_session():
    """Patch the underlying requests.Session used by _http.Session."""
    with patch("palantir_foundry._http.requests.Session") as MockSession:
        mock_session = MagicMock()
        MockSession.return_value = mock_session
        # Make mount() a no-op
        mock_session.mount = MagicMock()
        mock_session.verify = True
        yield mock_session


@pytest.fixture
def http_session(token_provider, mock_requests_session) -> Session:
    return Session(
        base_url=HOSTNAME,
        token_provider=token_provider,
    )


@pytest.fixture
def foundry_client(mock_requests_session) -> FoundryClient:
    return FoundryClient(hostname=HOSTNAME, token=TOKEN)


def make_response(json_data: Any = None, status_code: int = 200, content: bytes = b"") -> MagicMock:
    """Helper that builds a mock requests.Response."""
    resp = MagicMock()
    resp.status_code = status_code
    resp.ok = status_code < 400
    resp.json.return_value = json_data or {}
    resp.content = content
    resp.text = str(json_data)
    return resp
