"""Catalog / Resource API for Palantir Foundry.

Allows browsing the Foundry resource tree (projects, folders, datasets)
and creating new folders.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Iterator, List, Optional

from ._http import Session


@dataclass
class Resource:
    rid: str
    name: str
    resource_type: str
    path: Optional[str]
    parent_rid: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Resource":
        return cls(
            rid=data["rid"],
            name=data["name"],
            resource_type=data.get("type", data.get("resourceType", "")),
            path=data.get("path"),
            parent_rid=data.get("parentRid"),
            raw=data,
        )


@dataclass
class Folder:
    rid: str
    name: str
    path: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Folder":
        return cls(
            rid=data["rid"],
            name=data["name"],
            path=data.get("path"),
            raw=data,
        )


class CatalogAPI:
    """High-level client for the Foundry Catalog / Compass resource tree.

    Args:
        session: An authenticated :class:`palantir_foundry._http.Session`.
    """

    _BASE = "/api/v1/catalog"

    def __init__(self, session: Session) -> None:
        self._s = session

    # ------------------------------------------------------------------
    # Resource lookup
    # ------------------------------------------------------------------

    def get_resource(self, rid: str) -> Resource:
        """Fetch resource metadata by RID."""
        resp = self._s.get(f"{self._BASE}/resources/{rid}")
        return Resource.from_dict(resp.json())

    def get_resource_by_path(self, path: str) -> Resource:
        """Resolve a Compass path (e.g. ``/my-project/my-folder``) to a resource."""
        resp = self._s.get(
            f"{self._BASE}/resources",
            params={"path": path},
        )
        return Resource.from_dict(resp.json())

    def list_children(
        self,
        folder_rid: str,
        page_size: int = 100,
    ) -> Iterator[Resource]:
        """Iterate over all direct children of *folder_rid* (auto-paginated)."""
        params: Dict[str, Any] = {"pageSize": page_size}
        while True:
            resp = self._s.get(
                f"{self._BASE}/resources/{folder_rid}/children",
                params=params,
            )
            data = resp.json()
            for item in data.get("data", []):
                yield Resource.from_dict(item)
            next_token = data.get("nextPageToken")
            if not next_token:
                break
            params["pageToken"] = next_token

    def search_resources(
        self,
        query: str,
        resource_types: Optional[List[str]] = None,
        page_size: int = 50,
    ) -> List[Resource]:
        """Full-text search across accessible resources.

        Args:
            query: Search text.
            resource_types: Optional list of types to filter by (e.g. ``["dataset"]``).
            page_size: Maximum number of results per page.
        """
        body: Dict[str, Any] = {"query": query, "pageSize": page_size}
        if resource_types:
            body["resourceTypes"] = resource_types
        resp = self._s.post(f"{self._BASE}/resources/search", json=body)
        data = resp.json()
        return [Resource.from_dict(r) for r in data.get("data", [])]

    # ------------------------------------------------------------------
    # Folder operations
    # ------------------------------------------------------------------

    def create_folder(self, name: str, parent_folder_rid: str) -> Folder:
        """Create a new folder inside *parent_folder_rid*."""
        resp = self._s.post(
            f"{self._BASE}/folders",
            json={"name": name, "parentFolderRid": parent_folder_rid},
        )
        return Folder.from_dict(resp.json())

    def get_folder(self, folder_rid: str) -> Folder:
        """Retrieve folder metadata by RID."""
        resp = self._s.get(f"{self._BASE}/folders/{folder_rid}")
        return Folder.from_dict(resp.json())

    def delete_folder(self, folder_rid: str) -> None:
        """Delete an empty folder."""
        self._s.delete(f"{self._BASE}/folders/{folder_rid}")
