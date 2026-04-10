"""Datasets API for Palantir Foundry.

Covers:
- Creating and retrieving datasets
- Listing / reading / writing files on a branch
- Transaction lifecycle (open → commit / abort)
- Branch management
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Iterator, List, Optional

from ._http import Session


@dataclass
class Dataset:
    rid: str
    name: str
    parent_folder_rid: str
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Dataset":
        return cls(
            rid=data["rid"],
            name=data["name"],
            parent_folder_rid=data.get("parentFolderRid", ""),
            raw=data,
        )


@dataclass
class Branch:
    dataset_rid: str
    name: str
    transaction_rid: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, dataset_rid: str, data: Dict[str, Any]) -> "Branch":
        return cls(
            dataset_rid=dataset_rid,
            name=data["branchId"],
            transaction_rid=data.get("transactionRid"),
            raw=data,
        )


@dataclass
class Transaction:
    rid: str
    dataset_rid: str
    status: str
    transaction_type: str
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, dataset_rid: str, data: Dict[str, Any]) -> "Transaction":
        return cls(
            rid=data["rid"],
            dataset_rid=dataset_rid,
            status=data.get("status", ""),
            transaction_type=data.get("type", ""),
            raw=data,
        )


@dataclass
class FileInfo:
    path: str
    size_bytes: Optional[int]
    modified: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "FileInfo":
        return cls(
            path=data["logicalPath"],
            size_bytes=data.get("sizeInBytes"),
            modified=data.get("timeModified"),
            raw=data,
        )


class DatasetsAPI:
    """High-level client for the Foundry Datasets REST API.

    Args:
        session: An authenticated :class:`palantir_foundry._http.Session`.
    """

    _BASE = "/api/v1/datasets"

    def __init__(self, session: Session) -> None:
        self._s = session

    # ------------------------------------------------------------------
    # Dataset CRUD
    # ------------------------------------------------------------------

    def create(self, name: str, parent_folder_rid: str) -> Dataset:
        """Create a new dataset in *parent_folder_rid*."""
        resp = self._s.post(
            self._BASE,
            json={"name": name, "parentFolderRid": parent_folder_rid},
        )
        return Dataset.from_dict(resp.json())

    def get(self, dataset_rid: str) -> Dataset:
        """Retrieve metadata for an existing dataset."""
        resp = self._s.get(f"{self._BASE}/{dataset_rid}")
        return Dataset.from_dict(resp.json())

    def delete(self, dataset_rid: str) -> None:
        """Delete a dataset by RID."""
        self._s.delete(f"{self._BASE}/{dataset_rid}")

    # ------------------------------------------------------------------
    # Branch management
    # ------------------------------------------------------------------

    def list_branches(self, dataset_rid: str) -> List[Branch]:
        """Return all branches for *dataset_rid*."""
        resp = self._s.get(f"{self._BASE}/{dataset_rid}/branches")
        data = resp.json()
        items = data.get("data") or data.get("branches") or []
        return [Branch.from_dict(dataset_rid, b) for b in items]

    def get_branch(self, dataset_rid: str, branch: str = "master") -> Branch:
        """Retrieve a single branch."""
        resp = self._s.get(f"{self._BASE}/{dataset_rid}/branches/{branch}")
        return Branch.from_dict(dataset_rid, resp.json())

    def create_branch(
        self,
        dataset_rid: str,
        branch: str,
        source_branch: Optional[str] = None,
        source_transaction_rid: Optional[str] = None,
    ) -> Branch:
        """Create a new branch, optionally forking from *source_branch*."""
        body: Dict[str, Any] = {"branchId": branch}
        if source_branch:
            body["sourceBranchId"] = source_branch
        if source_transaction_rid:
            body["sourceTransactionRid"] = source_transaction_rid
        resp = self._s.post(f"{self._BASE}/{dataset_rid}/branches", json=body)
        return Branch.from_dict(dataset_rid, resp.json())

    # ------------------------------------------------------------------
    # Transaction lifecycle
    # ------------------------------------------------------------------

    def open_transaction(
        self, dataset_rid: str, branch: str = "master", transaction_type: str = "APPEND"
    ) -> Transaction:
        """Open a new transaction on *branch*."""
        resp = self._s.post(
            f"{self._BASE}/{dataset_rid}/transactions",
            json={"branchId": branch, "type": transaction_type},
        )
        return Transaction.from_dict(dataset_rid, resp.json())

    def commit_transaction(self, dataset_rid: str, transaction_rid: str) -> Transaction:
        """Commit an open transaction."""
        resp = self._s.post(
            f"{self._BASE}/{dataset_rid}/transactions/{transaction_rid}/commit"
        )
        return Transaction.from_dict(dataset_rid, resp.json())

    def abort_transaction(self, dataset_rid: str, transaction_rid: str) -> Transaction:
        """Abort / roll back an open transaction."""
        resp = self._s.post(
            f"{self._BASE}/{dataset_rid}/transactions/{transaction_rid}/abort"
        )
        return Transaction.from_dict(dataset_rid, resp.json())

    def get_transaction(self, dataset_rid: str, transaction_rid: str) -> Transaction:
        """Retrieve a transaction by RID."""
        resp = self._s.get(
            f"{self._BASE}/{dataset_rid}/transactions/{transaction_rid}"
        )
        return Transaction.from_dict(dataset_rid, resp.json())

    # ------------------------------------------------------------------
    # File operations
    # ------------------------------------------------------------------

    def list_files(
        self,
        dataset_rid: str,
        branch: str = "master",
        page_size: int = 100,
    ) -> Iterator[FileInfo]:
        """Iterate over all :class:`FileInfo` objects in *branch* (auto-paginated)."""
        params: Dict[str, Any] = {"branchId": branch, "pageSize": page_size}
        while True:
            resp = self._s.get(f"{self._BASE}/{dataset_rid}/files", params=params)
            data = resp.json()
            for item in data.get("data", []):
                yield FileInfo.from_dict(item)
            next_token = data.get("nextPageToken")
            if not next_token:
                break
            params["pageToken"] = next_token

    def get_file_content(
        self,
        dataset_rid: str,
        logical_path: str,
        branch: str = "master",
    ) -> bytes:
        """Download the raw bytes of a file from *branch*."""
        resp = self._s.get(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}/content",
            params={"branchId": branch},
            headers={"Accept": "application/octet-stream"},
        )
        return resp.content

    def upload_file(
        self,
        dataset_rid: str,
        transaction_rid: str,
        logical_path: str,
        data: bytes,
    ) -> None:
        """Upload raw bytes to *logical_path* within an open transaction."""
        self._s.put(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}",
            data=data,
            params={"transactionRid": transaction_rid},
            headers={"Content-Type": "application/octet-stream"},
        )
