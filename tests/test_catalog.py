"""Tests for palantir_foundry.catalog."""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from palantir_foundry.catalog import CatalogAPI, Resource, Folder
from tests.conftest import make_response


@pytest.fixture
def mock_session():
    return MagicMock()


@pytest.fixture
def api(mock_session):
    return CatalogAPI(mock_session)


FOLDER_RID = "ri.compass.main.folder.xyz"
DATASET_RID = "ri.foundry.main.dataset.abc"


class TestResourceLookup:
    def test_get_resource(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "rid": DATASET_RID,
            "name": "my-dataset",
            "type": "dataset",
            "path": "/Projects/my-dataset",
        })

        resource = api.get_resource(DATASET_RID)

        assert isinstance(resource, Resource)
        assert resource.rid == DATASET_RID
        assert resource.resource_type == "dataset"

    def test_get_resource_by_path(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "rid": FOLDER_RID,
            "name": "my-folder",
            "type": "folder",
            "path": "/Projects/my-folder",
        })

        resource = api.get_resource_by_path("/Projects/my-folder")

        assert resource.rid == FOLDER_RID
        mock_session.get.assert_called_once_with(
            "/api/v1/catalog/resources",
            params={"path": "/Projects/my-folder"},
        )

    def test_list_children_single_page(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"rid": "ri.1", "name": "child-1", "type": "dataset"},
                {"rid": "ri.2", "name": "child-2", "type": "folder"},
            ]
        })

        children = list(api.list_children(FOLDER_RID))

        assert len(children) == 2
        assert children[0].name == "child-1"
        assert children[1].resource_type == "folder"

    def test_list_children_paginated(self, api, mock_session):
        mock_session.get.side_effect = [
            make_response({
                "data": [{"rid": "ri.1", "name": "a", "type": "dataset"}],
                "nextPageToken": "token-2",
            }),
            make_response({
                "data": [{"rid": "ri.2", "name": "b", "type": "dataset"}],
            }),
        ]

        children = list(api.list_children(FOLDER_RID))

        assert len(children) == 2
        assert mock_session.get.call_count == 2

    def test_search_resources(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "data": [
                {"rid": DATASET_RID, "name": "found-dataset", "type": "dataset"},
            ]
        })

        results = api.search_resources("found-dataset", resource_types=["dataset"])

        assert len(results) == 1
        assert results[0].name == "found-dataset"
        call_json = mock_session.post.call_args[1]["json"]
        assert call_json["resourceTypes"] == ["dataset"]


class TestFolderOperations:
    def test_create_folder(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "rid": "ri.compass.main.folder.new",
            "name": "new-folder",
            "path": "/Projects/new-folder",
        })

        folder = api.create_folder("new-folder", FOLDER_RID)

        assert isinstance(folder, Folder)
        assert folder.name == "new-folder"
        call_json = mock_session.post.call_args[1]["json"]
        assert call_json["parentFolderRid"] == FOLDER_RID

    def test_get_folder(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "rid": FOLDER_RID,
            "name": "my-folder",
        })

        folder = api.get_folder(FOLDER_RID)

        assert folder.rid == FOLDER_RID

    def test_delete_folder(self, api, mock_session):
        mock_session.delete.return_value = make_response(status_code=204)

        api.delete_folder(FOLDER_RID)

        mock_session.delete.assert_called_once_with(f"/api/v1/catalog/folders/{FOLDER_RID}")
