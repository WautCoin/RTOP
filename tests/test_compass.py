"""Tests for palantir_foundry.compass."""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from palantir_foundry.compass import CompassAPI, CompassFile
from tests.conftest import make_response


@pytest.fixture
def mock_session():
    return MagicMock()


@pytest.fixture
def api(mock_session):
    return CompassAPI(mock_session)


DATASET_RID = "ri.foundry.main.dataset.compass-test"
TXN_RID = "ri.foundry.main.transaction.txn-1"


class TestListFiles:
    def test_list_files_single_page(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"path": "/data/a.parquet", "sizeInBytes": 512, "contentType": "application/octet-stream"},
                {"path": "/data/b.parquet", "sizeInBytes": 1024},
            ]
        })

        files = list(api.list_files(DATASET_RID))

        assert len(files) == 2
        assert isinstance(files[0], CompassFile)
        assert files[0].path == "/data/a.parquet"
        assert files[0].size_bytes == 512

    def test_list_files_with_prefix(self, api, mock_session):
        mock_session.get.return_value = make_response({"data": []})

        list(api.list_files(DATASET_RID, path_prefix="/data/"))

        call_params = mock_session.get.call_args[1]["params"]
        assert call_params["pathPrefix"] == "/data/"

    def test_list_files_paginated(self, api, mock_session):
        mock_session.get.side_effect = [
            make_response({
                "data": [{"path": "/a.csv", "sizeInBytes": 1}],
                "nextPageToken": "tok-2",
            }),
            make_response({
                "data": [{"path": "/b.csv", "sizeInBytes": 2}],
            }),
        ]

        files = list(api.list_files(DATASET_RID))

        assert len(files) == 2
        assert mock_session.get.call_count == 2


class TestUploadDownload:
    def test_upload_file(self, api, mock_session):
        mock_session.put.return_value = make_response(status_code=200)

        api.upload_file(DATASET_RID, TXN_RID, "/data/file.csv", b"col1,col2\n1,2\n")

        mock_session.put.assert_called_once()
        call_kwargs = mock_session.put.call_args[1]
        assert call_kwargs["data"] == b"col1,col2\n1,2\n"
        assert call_kwargs["params"]["transactionRid"] == TXN_RID

    def test_upload_file_strips_leading_slash(self, api, mock_session):
        mock_session.put.return_value = make_response(status_code=200)
        api.upload_file(DATASET_RID, TXN_RID, "/leading/slash.csv", b"data")
        path_called = mock_session.put.call_args[0][0]
        assert "//leading" not in path_called

    def test_download_file(self, api, mock_session):
        mock_session.get.return_value = make_response(content=b"raw bytes here")

        content = api.download_file(DATASET_RID, "/data/file.parquet", branch="master")

        assert content == b"raw bytes here"
        call_params = mock_session.get.call_args[1]["params"]
        assert call_params["branchId"] == "master"

    def test_download_file_strips_leading_slash(self, api, mock_session):
        mock_session.get.return_value = make_response(content=b"data")
        api.download_file(DATASET_RID, "/my/file.csv")
        path_called = mock_session.get.call_args[0][0]
        assert "//my" not in path_called


class TestFileMetadata:
    def test_get_file_metadata(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "path": "/data/file.csv",
            "sizeInBytes": 2048,
            "contentType": "text/csv",
            "timeModified": "2024-01-15T10:00:00Z",
        })

        meta = api.get_file_metadata(DATASET_RID, "/data/file.csv", branch="dev")

        assert isinstance(meta, CompassFile)
        assert meta.size_bytes == 2048
        assert meta.content_type == "text/csv"


class TestDeleteFile:
    def test_delete_file(self, api, mock_session):
        mock_session.delete.return_value = make_response(status_code=204)

        api.delete_file(DATASET_RID, TXN_RID, "/data/old-file.csv")

        mock_session.delete.assert_called_once()
        call_params = mock_session.delete.call_args[1]["params"]
        assert call_params["transactionRid"] == TXN_RID
