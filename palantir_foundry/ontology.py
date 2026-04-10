"""Ontology API for Palantir Foundry (OSDK-style interface).

Covers:
- Listing ontologies and object types
- Querying objects with filters and ordering
- Fetching individual objects
- Applying actions
- Running searches (full-text)
- Executing queries
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Iterator, List, Optional

from ._http import Session


@dataclass
class OntologyMetadata:
    rid: str
    api_name: str
    display_name: str
    description: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "OntologyMetadata":
        return cls(
            rid=data["rid"],
            api_name=data.get("apiName", ""),
            display_name=data.get("displayName", ""),
            description=data.get("description"),
            raw=data,
        )


@dataclass
class ObjectType:
    api_name: str
    display_name: str
    rid: str
    primary_key: str
    description: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ObjectType":
        return cls(
            api_name=data.get("apiName", ""),
            display_name=data.get("displayName", ""),
            rid=data.get("rid", ""),
            primary_key=data.get("primaryKey", ""),
            description=data.get("description"),
            raw=data,
        )


@dataclass
class OntologyObject:
    object_type: str
    primary_key: str
    properties: Dict[str, Any]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, object_type: str, data: Dict[str, Any]) -> "OntologyObject":
        return cls(
            object_type=object_type,
            primary_key=str(data.get("__primaryKey", "")),
            properties=data.get("properties", data),
            raw=data,
        )


@dataclass
class ActionResult:
    action_type: str
    status: str
    edits: List[Dict[str, Any]]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, action_type: str, data: Dict[str, Any]) -> "ActionResult":
        return cls(
            action_type=action_type,
            status=data.get("status", "SUCCESS"),
            edits=data.get("edits", []),
            raw=data,
        )


class OntologyAPI:
    """High-level client for the Foundry Ontology REST API.

    Args:
        session: An authenticated :class:`palantir_foundry._http.Session`.
    """

    _BASE = "/api/v1/ontologies"

    def __init__(self, session: Session) -> None:
        self._s = session

    # ------------------------------------------------------------------
    # Ontology discovery
    # ------------------------------------------------------------------

    def list_ontologies(self) -> List[OntologyMetadata]:
        """Return all ontologies visible to the caller."""
        resp = self._s.get(self._BASE)
        data = resp.json()
        items = data.get("data", data if isinstance(data, list) else [])
        return [OntologyMetadata.from_dict(o) for o in items]

    def get_ontology(self, ontology_rid: str) -> OntologyMetadata:
        """Fetch a single ontology by RID."""
        resp = self._s.get(f"{self._BASE}/{ontology_rid}")
        return OntologyMetadata.from_dict(resp.json())

    # ------------------------------------------------------------------
    # Object types
    # ------------------------------------------------------------------

    def list_object_types(self, ontology_rid: str) -> List[ObjectType]:
        """List all object types registered in *ontology_rid*."""
        resp = self._s.get(f"{self._BASE}/{ontology_rid}/objectTypes")
        data = resp.json()
        items = data.get("data", [])
        return [ObjectType.from_dict(o) for o in items]

    def get_object_type(self, ontology_rid: str, object_type: str) -> ObjectType:
        """Fetch metadata for a specific object type."""
        resp = self._s.get(f"{self._BASE}/{ontology_rid}/objectTypes/{object_type}")
        return ObjectType.from_dict(resp.json())

    # ------------------------------------------------------------------
    # Object queries
    # ------------------------------------------------------------------

    def list_objects(
        self,
        ontology_rid: str,
        object_type: str,
        order_by: Optional[str] = None,
        page_size: int = 100,
        select: Optional[List[str]] = None,
    ) -> Iterator[OntologyObject]:
        """Iterate over all objects of *object_type* (auto-paginated).

        Args:
            ontology_rid: RID of the ontology.
            object_type: API name of the object type.
            order_by: Optional field name to sort by.
            page_size: Number of objects per page.
            select: Optional list of property names to include.
        """
        params: Dict[str, Any] = {"pageSize": page_size}
        if order_by:
            params["orderBy"] = order_by
        if select:
            params["select"] = ",".join(select)

        while True:
            resp = self._s.get(
                f"{self._BASE}/{ontology_rid}/objects/{object_type}",
                params=params,
            )
            data = resp.json()
            for item in data.get("data", []):
                yield OntologyObject.from_dict(object_type, item)
            next_token = data.get("nextPageToken")
            if not next_token:
                break
            params["pageToken"] = next_token

    def get_object(
        self, ontology_rid: str, object_type: str, primary_key: str
    ) -> OntologyObject:
        """Fetch a single object by primary key."""
        resp = self._s.get(
            f"{self._BASE}/{ontology_rid}/objects/{object_type}/{primary_key}"
        )
        return OntologyObject.from_dict(object_type, resp.json())

    def search_objects(
        self,
        ontology_rid: str,
        object_type: str,
        query: Dict[str, Any],
        order_by: Optional[Dict[str, Any]] = None,
        page_size: int = 100,
        select: Optional[List[str]] = None,
    ) -> List[OntologyObject]:
        """Search objects using a structured filter query.

        Args:
            ontology_rid: RID of the ontology.
            object_type: API name of the object type.
            query: Foundry filter payload (e.g. ``{"type": "eq", "field": "status", "value": "active"}``).
            order_by: Optional ordering payload.
            page_size: Max results to return.
            select: Optional list of property names to include.
        """
        body: Dict[str, Any] = {"query": query, "pageSize": page_size}
        if order_by:
            body["orderBy"] = order_by
        if select:
            body["select"] = select
        resp = self._s.post(
            f"{self._BASE}/{ontology_rid}/objects/{object_type}/search",
            json=body,
        )
        data = resp.json()
        return [OntologyObject.from_dict(object_type, o) for o in data.get("data", [])]

    def link_objects(
        self,
        ontology_rid: str,
        object_type: str,
        primary_key: str,
        link_type: str,
        page_size: int = 100,
    ) -> List[OntologyObject]:
        """List objects linked via *link_type* from a given object."""
        resp = self._s.get(
            f"{self._BASE}/{ontology_rid}/objects/{object_type}/{primary_key}/links/{link_type}",
            params={"pageSize": page_size},
        )
        data = resp.json()
        return [OntologyObject.from_dict(link_type, o) for o in data.get("data", [])]

    # ------------------------------------------------------------------
    # Actions
    # ------------------------------------------------------------------

    def apply_action(
        self,
        ontology_rid: str,
        action_type: str,
        parameters: Dict[str, Any],
    ) -> ActionResult:
        """Apply an action defined in the ontology.

        Args:
            ontology_rid: RID of the ontology.
            action_type: API name of the action type.
            parameters: Key-value map of action parameters.
        """
        resp = self._s.post(
            f"{self._BASE}/{ontology_rid}/actions/{action_type}/apply",
            json={"parameters": parameters},
        )
        return ActionResult.from_dict(action_type, resp.json())

    def list_action_types(self, ontology_rid: str) -> List[Dict[str, Any]]:
        """List all action types registered in *ontology_rid*."""
        resp = self._s.get(f"{self._BASE}/{ontology_rid}/actionTypes")
        data = resp.json()
        return data.get("data", [])

    # ------------------------------------------------------------------
    # Queries
    # ------------------------------------------------------------------

    def execute_query(
        self,
        ontology_rid: str,
        query_type: str,
        parameters: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Execute a pre-defined query function on the ontology.

        Args:
            ontology_rid: RID of the ontology.
            query_type: API name of the query type.
            parameters: Key-value map of query input parameters.
        """
        resp = self._s.post(
            f"{self._BASE}/{ontology_rid}/queries/{query_type}/execute",
            json={"parameters": parameters},
        )
        return resp.json()
