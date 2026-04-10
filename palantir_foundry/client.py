"""FoundryClient – the main entry point for the Palantir Foundry Python SDK."""

from __future__ import annotations

from typing import Optional

from .auth import BearerTokenAuth, OAuth2ClientCredentials, TokenProvider
from .catalog import CatalogAPI
from .compass import CompassAPI
from .datasets import DatasetsAPI
from ._http import Session
from .ontology import OntologyAPI


class FoundryClient:
    """Top-level client for the Palantir Foundry REST API.

    Instantiate once and reuse across your application. All sub-clients
    share the same authenticated :class:`~palantir_foundry._http.Session`.

    Args:
        hostname: Foundry base URL, e.g. ``https://my-foundry.example.com``.
        token: Static bearer token (from the Foundry Developer Console).
            Mutually exclusive with *token_provider*.
        verify_ssl: Whether to verify TLS certificates (default ``True``).
        token_provider: Custom :class:`~palantir_foundry.auth.TokenProvider`
            instance; use instead of *token* for OAuth2 or custom auth.

    Raises:
        ValueError: If neither *token* nor *token_provider* is supplied.

    Examples::

        from palantir_foundry import FoundryClient

        client = FoundryClient(
            hostname="https://my-foundry.example.com",
            token="my-api-token",
        )

        dataset = client.datasets.get("ri.foundry.main.dataset.abc123")
        print(dataset.name)
    """

    def __init__(
        self,
        hostname: str,
        token: Optional[str] = None,
        *,
        verify_ssl: bool = True,
        token_provider: Optional[TokenProvider] = None,
    ) -> None:
        if token_provider is None:
            if not token:
                raise ValueError("Either 'token' or 'token_provider' must be provided.")
            token_provider = BearerTokenAuth(token)

        self._session = Session(
            base_url=hostname,
            token_provider=token_provider,
            verify_ssl=verify_ssl,
        )

        self.datasets = DatasetsAPI(self._session)
        self.catalog = CatalogAPI(self._session)
        self.ontology = OntologyAPI(self._session)
        self.compass = CompassAPI(self._session)

    @classmethod
    def from_oauth2(
        cls,
        hostname: str,
        client_id: str,
        client_secret: str,
        scopes: str = "api:read-data api:write-data",
        verify_ssl: bool = True,
    ) -> "FoundryClient":
        """Create a client using OAuth2 client credentials flow.

        Args:
            hostname: Foundry base URL.
            client_id: OAuth2 client ID.
            client_secret: OAuth2 client secret.
            scopes: Space-separated OAuth2 scopes.
            verify_ssl: Whether to verify TLS certificates.

        Returns:
            A fully configured :class:`FoundryClient`.
        """
        provider = OAuth2ClientCredentials(
            hostname=hostname,
            client_id=client_id,
            client_secret=client_secret,
            scopes=scopes,
            verify_ssl=verify_ssl,
        )
        return cls(hostname=hostname, token_provider=provider, verify_ssl=verify_ssl)
