"""Compass (file-storage) API for Palantir Foundry.

Provides upload and download of arbitrary files stored in the Compass
backing store for a dataset branch, as well as listing and deleting files.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Iterator, List, Optional

from ._http import Session


@dataclass
class CompassFile:
    path: str
    size_bytes: Optional[int]
    content_type: Optional[str]
    modified: Optional[str]
    raw: Dict[str, Any] = field(default_factory=dict, repr=False)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CompassFile":
        return cls(
            path=data.get("path", data.get("logicalPath", "")),
            size_bytes=data.get("sizeInBytes"),
            content_type=data.get("contentType"),
            modified=data.get("timeModified"),
            raw=data,
        )


class CompassAPI:
    """High-level client for the Foundry Compass / file-storage REST API.

    Files are stored on a *branch* of a dataset and scoped to an open
    transaction when writing.

    Args:
        session: An authenticated :class:`palantir_foundry._http.Session`.
    """

    _BASE = "/api/v1/datasets"

    def __init__(self, session: Session) -> None:
        self._s = session

    # ------------------------------------------------------------------
    # File listing
    # ------------------------------------------------------------------

    def list_files(
        self,
        dataset_rid: str,
        branch: str = "master",
        page_size: int = 100,
        path_prefix: Optional[str] = None,
    ) -> Iterator[CompassFile]:
        """Iterate over files in *branch*, optionally filtered by *path_prefix*."""
        params: Dict[str, Any] = {"branchId": branch, "pageSize": page_size}
        if path_prefix:
            params["pathPrefix"] = path_prefix
        while True:
            resp = self._s.get(f"{self._BASE}/{dataset_rid}/files", params=params)
            data = resp.json()
            for item in data.get("data", []):
                yield CompassFile.from_dict(item)
            next_token = data.get("nextPageToken")
            if not next_token:
                break
            params["pageToken"] = next_token

    # ------------------------------------------------------------------
    # Upload / download
    # ------------------------------------------------------------------

    def upload_file(
        self,
        dataset_rid: str,
        transaction_rid: str,
        logical_path: str,
        content: bytes,
        content_type: str = "application/octet-stream",
    ) -> None:
        """Upload *content* to *logical_path* within an open transaction.

        Args:
            dataset_rid: RID of the target dataset.
            transaction_rid: RID of the open write transaction.
            logical_path: Destination path within the dataset, e.g. ``/data/file.csv``.
            content: Raw bytes to upload.
            content_type: MIME type for the upload (default ``application/octet-stream``).
        """
        self._s.put(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}",
            data=content,
            params={"transactionRid": transaction_rid},
            headers={"Content-Type": content_type, "Accept": "application/json"},
        )

    def download_file(
        self,
        dataset_rid: str,
        logical_path: str,
        branch: str = "master",
    ) -> bytes:
        """Download the raw bytes of *logical_path* from *branch*.

        Args:
            dataset_rid: RID of the source dataset.
            logical_path: Path within the dataset, e.g. ``/data/file.csv``.
            branch: Branch name (default ``"master"``).
        """
        resp = self._s.get(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}/content",
            params={"branchId": branch},
            headers={"Accept": "application/octet-stream"},
        )
        return resp.content

    # ------------------------------------------------------------------
    # File metadata
    # ------------------------------------------------------------------

    def get_file_metadata(
        self,
        dataset_rid: str,
        logical_path: str,
        branch: str = "master",
    ) -> CompassFile:
        """Retrieve metadata (size, content-type, last-modified) for a file."""
        resp = self._s.get(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}",
            params={"branchId": branch},
        )
        return CompassFile.from_dict(resp.json())

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    def delete_file(
        self,
        dataset_rid: str,
        transaction_rid: str,
        logical_path: str,
    ) -> None:
        """Mark *logical_path* as deleted within an open transaction."""
        self._s.delete(
            f"{self._BASE}/{dataset_rid}/files/{logical_path.lstrip('/')}",
            params={"transactionRid": transaction_rid},
        )
