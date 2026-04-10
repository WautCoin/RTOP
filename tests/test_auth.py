"""Tests for palantir_foundry.auth."""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from palantir_foundry.auth import BearerTokenAuth, OAuth2ClientCredentials
from palantir_foundry.exceptions import AuthenticationError


class TestBearerTokenAuth:
    def test_get_token_returns_token(self):
        auth = BearerTokenAuth("my-token")
        assert auth.get_token() == "my-token"

    def test_empty_token_raises(self):
        with pytest.raises(ValueError, match="non-empty"):
            BearerTokenAuth("")


class TestOAuth2ClientCredentials:
    def _make_provider(self, http_post=None):
        return OAuth2ClientCredentials(
            hostname="https://foundry.example.com",
            client_id="client-id",
            client_secret="client-secret",
            scopes="api:read-data",
            _http_post=http_post,
        )

    def _success_response(self, token="access-token-xyz", expires_in=3600):
        resp = MagicMock()
        resp.ok = True
        resp.json.return_value = {"access_token": token, "expires_in": expires_in}
        return resp

    def _error_response(self, status=401, description="invalid_client"):
        resp = MagicMock()
        resp.ok = False
        resp.status_code = status
        resp.json.return_value = {"error_description": description}
        resp.text = description
        return resp

    def test_fetches_token_on_first_call(self):
        mock_post = MagicMock(return_value=self._success_response())
        provider = self._make_provider(http_post=mock_post)

        token = provider.get_token()

        assert token == "access-token-xyz"
        mock_post.assert_called_once()
        call_kwargs = mock_post.call_args
        assert "grant_type" in call_kwargs[1]["data"]

    def test_caches_token_until_expiry(self):
        mock_post = MagicMock(return_value=self._success_response(expires_in=3600))
        provider = self._make_provider(http_post=mock_post)

        token1 = provider.get_token()
        token2 = provider.get_token()

        assert token1 == token2
        mock_post.assert_called_once()

    def test_refreshes_token_when_expired(self):
        mock_post = MagicMock(
            side_effect=[
                self._success_response("first-token", expires_in=1),
                self._success_response("second-token", expires_in=3600),
            ]
        )
        provider = self._make_provider(http_post=mock_post)
        provider._refresh_before_expiry = 0

        provider.get_token()
        # Force expiry
        provider._expires_at = 0.0
        token = provider.get_token()

        assert token == "second-token"
        assert mock_post.call_count == 2

    def test_raises_auth_error_on_failure(self):
        mock_post = MagicMock(return_value=self._error_response())
        provider = self._make_provider(http_post=mock_post)

        with pytest.raises(AuthenticationError, match="invalid_client"):
            provider.get_token()

    def test_token_endpoint_url(self):
        mock_post = MagicMock(return_value=self._success_response())
        provider = self._make_provider(http_post=mock_post)
        provider.get_token()

        url = mock_post.call_args[0][0]
        assert url.endswith("/multipass/api/oauth2/token")
