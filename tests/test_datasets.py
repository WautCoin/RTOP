"""Tests for palantir_foundry.datasets."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from palantir_foundry.datasets import DatasetsAPI, Dataset, Branch, Transaction, FileInfo
from palantir_foundry.exceptions import NotFoundError
from tests.conftest import make_response, HOSTNAME, TOKEN


@pytest.fixture
def mock_session():
    return MagicMock()


@pytest.fixture
def api(mock_session):
    return DatasetsAPI(mock_session)


DATASET_RID = "ri.foundry.main.dataset.abc123"


class TestDatasetsCreate:
    def test_create_returns_dataset(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "rid": DATASET_RID,
            "name": "my-dataset",
            "parentFolderRid": "ri.foundry.main.folder.xyz",
        })

        ds = api.create("my-dataset", "ri.foundry.main.folder.xyz")

        assert isinstance(ds, Dataset)
        assert ds.rid == DATASET_RID
        assert ds.name == "my-dataset"
        mock_session.post.assert_called_once_with(
            "/api/v1/datasets",
            json={"name": "my-dataset", "parentFolderRid": "ri.foundry.main.folder.xyz"},
        )

    def test_get_returns_dataset(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "rid": DATASET_RID,
            "name": "my-dataset",
            "parentFolderRid": "ri.foundry.main.folder.xyz",
        })

        ds = api.get(DATASET_RID)

        assert ds.rid == DATASET_RID
        mock_session.get.assert_called_once_with(f"/api/v1/datasets/{DATASET_RID}")

    def test_delete_calls_delete(self, api, mock_session):
        mock_session.delete.return_value = make_response(status_code=204)
        api.delete(DATASET_RID)
        mock_session.delete.assert_called_once_with(f"/api/v1/datasets/{DATASET_RID}")


class TestBranches:
    def test_list_branches(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"branchId": "master", "transactionRid": None},
                {"branchId": "dev", "transactionRid": "ri.foundry.main.transaction.1"},
            ]
        })

        branches = api.list_branches(DATASET_RID)

        assert len(branches) == 2
        assert branches[0].name == "master"
        assert branches[1].name == "dev"

    def test_create_branch(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "branchId": "feature/x",
            "transactionRid": None,
        })

        branch = api.create_branch(DATASET_RID, "feature/x", source_branch="master")

        assert branch.name == "feature/x"
        mock_session.post.assert_called_once()
        call_json = mock_session.post.call_args[1]["json"]
        assert call_json["sourceBranchId"] == "master"

    def test_get_branch(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "branchId": "master",
            "transactionRid": "ri.foundry.main.transaction.42",
        })

        branch = api.get_branch(DATASET_RID, "master")

        assert branch.name == "master"
        assert branch.transaction_rid == "ri.foundry.main.transaction.42"


class TestTransactions:
    def test_open_transaction(self, api, mock_session):
        mock_session.post.return_value = make_response({
            "rid": "ri.foundry.main.transaction.99",
            "status": "OPEN",
            "type": "APPEND",
        })

        txn = api.open_transaction(DATASET_RID, branch="master")

        assert txn.rid == "ri.foundry.main.transaction.99"
        assert txn.status == "OPEN"

    def test_commit_transaction(self, api, mock_session):
        txn_rid = "ri.foundry.main.transaction.99"
        mock_session.post.return_value = make_response({
            "rid": txn_rid,
            "status": "COMMITTED",
            "type": "APPEND",
        })

        txn = api.commit_transaction(DATASET_RID, txn_rid)

        assert txn.status == "COMMITTED"
        mock_session.post.assert_called_once_with(
            f"/api/v1/datasets/{DATASET_RID}/transactions/{txn_rid}/commit"
        )

    def test_abort_transaction(self, api, mock_session):
        txn_rid = "ri.foundry.main.transaction.99"
        mock_session.post.return_value = make_response({
            "rid": txn_rid,
            "status": "ABORTED",
            "type": "APPEND",
        })

        txn = api.abort_transaction(DATASET_RID, txn_rid)

        assert txn.status == "ABORTED"


class TestFileOperations:
    def test_list_files_single_page(self, api, mock_session):
        mock_session.get.return_value = make_response({
            "data": [
                {"logicalPath": "/data/file1.csv", "sizeInBytes": 1024},
                {"logicalPath": "/data/file2.csv", "sizeInBytes": 2048},
            ]
        })

        files = list(api.list_files(DATASET_RID))

        assert len(files) == 2
        assert files[0].path == "/data/file1.csv"
        assert files[0].size_bytes == 1024

    def test_list_files_paginated(self, api, mock_session):
        mock_session.get.side_effect = [
            make_response({
                "data": [{"logicalPath": "/a.csv", "sizeInBytes": 1}],
                "nextPageToken": "page2",
            }),
            make_response({
                "data": [{"logicalPath": "/b.csv", "sizeInBytes": 2}],
            }),
        ]

        files = list(api.list_files(DATASET_RID))

        assert len(files) == 2
        assert mock_session.get.call_count == 2

    def test_get_file_content(self, api, mock_session):
        mock_session.get.return_value = make_response(content=b"hello,world\n")

        content = api.get_file_content(DATASET_RID, "/data/file.csv")

        assert content == b"hello,world\n"

    def test_upload_file(self, api, mock_session):
        mock_session.put.return_value = make_response(status_code=200)

        api.upload_file(DATASET_RID, "ri.txn.1", "/data/file.csv", b"a,b,c\n")

        mock_session.put.assert_called_once()
        call_kwargs = mock_session.put.call_args[1]
        assert call_kwargs["data"] == b"a,b,c\n"
