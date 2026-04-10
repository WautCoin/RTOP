"""Tests for palantir_foundry.ontology."""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from palantir_foundry.ontology import (
    OntologyAPI,
    OntologyMetadata,
    ObjectType,
    OntologyObject,
    ActionResult,
)
from tests.conftest import make_response


@pytest.fixture
def mock_session():
    return MagicMock()


@pytest.fixture
def api(mock_session):
    return OntologyAPI(mock_session)


ONTOLOGY_RID = "ri.ontology.main.ontology.abc"
OBJECT_TYPE = "Employee"


class TestOntologyDiscovery:
    def test_list_ontologies(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {
                    "rid": ONTOLOGY_RID,
                    "apiName": "my-ontology",
                    "displayName": "My Ontology",
                }
            ]
        })

        onts = api.list_ontologies()

        assert len(onts) == 1
        assert isinstance(onts[0], OntologyMetadata)
        assert onts[0].api_name == "my-ontology"

    def test_get_ontology(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "rid": ONTOLOGY_RID,
            "apiName": "my-ontology",
            "displayName": "My Ontology",
        })

        ont = api.get_ontology(ONTOLOGY_RID)

        assert ont.rid == ONTOLOGY_RID
        mock_session.get.assert_called_once_with(f"/api/v1/ontologies/{ONTOLOGY_RID}")


class TestObjectTypes:
    def test_list_object_types(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"apiName": "Employee", "displayName": "Employee", "rid": "ri.1", "primaryKey": "id"},
                {"apiName": "Department", "displayName": "Department", "rid": "ri.2", "primaryKey": "deptId"},
            ]
        })

        types = api.list_object_types(ONTOLOGY_RID)

        assert len(types) == 2
        assert types[0].api_name == "Employee"

    def test_get_object_type(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "apiName": "Employee",
            "displayName": "Employee",
            "rid": "ri.1",
            "primaryKey": "employeeId",
        })

        obj_type = api.get_object_type(ONTOLOGY_RID, "Employee")

        assert obj_type.primary_key == "employeeId"


class TestObjectQueries:
    def test_list_objects(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"__primaryKey": "1", "properties": {"name": "Alice", "dept": "Eng"}},
                {"__primaryKey": "2", "properties": {"name": "Bob", "dept": "PM"}},
            ]
        })

        objects = list(api.list_objects(ONTOLOGY_RID, OBJECT_TYPE))

        assert len(objects) == 2
        assert objects[0].primary_key == "1"

    def test_list_objects_paginated(self, api, mock_session):
        mock_session.get.side_effect = [
            make_response({
                "data": [{"__primaryKey": "1", "properties": {}}],
                "nextPageToken": "page-2",
            }),
            make_response({
                "data": [{"__primaryKey": "2", "properties": {}}],
            }),
        ]

        objects = list(api.list_objects(ONTOLOGY_RID, OBJECT_TYPE))

        assert len(objects) == 2
        assert mock_session.get.call_count == 2

    def test_get_object(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "__primaryKey": "42",
            "properties": {"name": "Charlie"},
        })

        obj = api.get_object(ONTOLOGY_RID, OBJECT_TYPE, "42")

        assert obj.primary_key == "42"
        assert obj.object_type == OBJECT_TYPE

    def test_search_objects(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "data": [
                {"__primaryKey": "3", "properties": {"status": "active"}},
            ]
        })

        results = api.search_objects(
            ONTOLOGY_RID,
            OBJECT_TYPE,
            query={"type": "eq", "field": "status", "value": "active"},
        )

        assert len(results) == 1
        call_json = mock_session.post.call_args[1]["json"]
        assert call_json["query"]["type"] == "eq"

    def test_link_objects(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [{"__primaryKey": "dept-1", "properties": {}}]
        })

        linked = api.link_objects(ONTOLOGY_RID, OBJECT_TYPE, "42", "worksIn")

        assert len(linked) == 1


class TestActions:
    def test_apply_action(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "status": "SUCCESS",
            "edits": [{"type": "createObject", "objectType": "Employee"}],
        })

        result = api.apply_action(
            ONTOLOGY_RID,
            "createEmployee",
            {"name": "Dave", "department": "Eng"},
        )

        assert isinstance(result, ActionResult)
        assert result.status == "SUCCESS"
        assert result.action_type == "createEmployee"

    def test_list_action_types(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [{"apiName": "createEmployee"}, {"apiName": "promoteEmployee"}]
        })

        types = api.list_action_types(ONTOLOGY_RID)

        assert len(types) == 2


class TestQueries:
    def test_execute_query(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "value": {"totalCount": 42}
        })

        result = api.execute_query(ONTOLOGY_RID, "countByDept", {"dept": "Eng"})

        assert result["value"]["totalCount"] == 42
        call_json = mock_session.post.call_args[1]["json"]
        assert call_json["parameters"]["dept"] == "Eng"
