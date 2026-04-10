"""Command-line interface for the Palantir Foundry Python SDK."""

from __future__ import annotations

import json
import sys
from typing import Optional

import click

from .client import FoundryClient


def _make_client(hostname: str, token: str) -> FoundryClient:
    return FoundryClient(hostname=hostname, token=token)


# ---------------------------------------------------------------------------
# Root group
# ---------------------------------------------------------------------------

@click.group()
@click.option(
    "--hostname",
    envvar="FOUNDRY_HOSTNAME",
    required=True,
    help="Foundry base URL (e.g. https://my-foundry.example.com). "
    "Can also be set via FOUNDRY_HOSTNAME environment variable.",
)
@click.option(
    "--token",
    envvar="FOUNDRY_TOKEN",
    required=True,
    help="Foundry API bearer token. Can also be set via FOUNDRY_TOKEN environment variable.",
)
@click.pass_context
def cli(ctx: click.Context, hostname: str, token: str) -> None:
    """Palantir Foundry CLI – interact with the Foundry REST API."""
    ctx.ensure_object(dict)
    ctx.obj["client"] = _make_client(hostname, token)


# ---------------------------------------------------------------------------
# datasets sub-group
# ---------------------------------------------------------------------------

@cli.group()
def datasets() -> None:
    """Commands for managing Foundry datasets."""


@datasets.command("get")
@click.argument("dataset_rid")
@click.pass_context
def datasets_get(ctx: click.Context, dataset_rid: str) -> None:
    """Get metadata for DATASET_RID."""
    client: FoundryClient = ctx.obj["client"]
    ds = client.datasets.get(dataset_rid)
    click.echo(json.dumps(ds.raw, indent=2))


@datasets.command("create")
@click.argument("name")
@click.argument("parent_folder_rid")
@click.pass_context
def datasets_create(ctx: click.Context, name: str, parent_folder_rid: str) -> None:
    """Create a new dataset NAME inside PARENT_FOLDER_RID."""
    client: FoundryClient = ctx.obj["client"]
    ds = client.datasets.create(name=name, parent_folder_rid=parent_folder_rid)
    click.echo(json.dumps(ds.raw, indent=2))


@datasets.command("list-branches")
@click.argument("dataset_rid")
@click.pass_context
def datasets_list_branches(ctx: click.Context, dataset_rid: str) -> None:
    """List branches for DATASET_RID."""
    client: FoundryClient = ctx.obj["client"]
    branches = client.datasets.list_branches(dataset_rid)
    click.echo(json.dumps([b.raw for b in branches], indent=2))


@datasets.command("list-files")
@click.argument("dataset_rid")
@click.option("--branch", default="master", show_default=True, help="Branch name.")
@click.pass_context
def datasets_list_files(ctx: click.Context, dataset_rid: str, branch: str) -> None:
    """List files in DATASET_RID on BRANCH."""
    client: FoundryClient = ctx.obj["client"]
    files = list(client.datasets.list_files(dataset_rid, branch=branch))
    click.echo(json.dumps([f.raw for f in files], indent=2))


@datasets.command("download-file")
@click.argument("dataset_rid")
@click.argument("logical_path")
@click.option("--branch", default="master", show_default=True)
@click.option("--output", "-o", default="-", help="Output file path (default: stdout).")
@click.pass_context
def datasets_download_file(
    ctx: click.Context,
    dataset_rid: str,
    logical_path: str,
    branch: str,
    output: str,
) -> None:
    """Download LOGICAL_PATH from DATASET_RID."""
    client: FoundryClient = ctx.obj["client"]
    content = client.datasets.get_file_content(dataset_rid, logical_path, branch=branch)
    if output == "-":
        sys.stdout.buffer.write(content)
    else:
        with open(output, "wb") as fh:
            fh.write(content)
        click.echo(f"Written {len(content)} bytes to {output}", err=True)


# ---------------------------------------------------------------------------
# catalog sub-group
# ---------------------------------------------------------------------------

@cli.group()
def catalog() -> None:
    """Commands for browsing the Foundry resource catalog."""


@catalog.command("get")
@click.argument("rid")
@click.pass_context
def catalog_get(ctx: click.Context, rid: str) -> None:
    """Get resource metadata for RID."""
    client: FoundryClient = ctx.obj["client"]
    resource = client.catalog.get_resource(rid)
    click.echo(json.dumps(resource.raw, indent=2))


@catalog.command("ls")
@click.argument("folder_rid")
@click.pass_context
def catalog_ls(ctx: click.Context, folder_rid: str) -> None:
    """List children of FOLDER_RID."""
    client: FoundryClient = ctx.obj["client"]
    children = list(client.catalog.list_children(folder_rid))
    click.echo(json.dumps([r.raw for r in children], indent=2))


@catalog.command("search")
@click.argument("query")
@click.option(
    "--type",
    "resource_type",
    default=None,
    help="Filter by resource type, e.g. 'dataset'.",
)
@click.pass_context
def catalog_search(ctx: click.Context, query: str, resource_type: Optional[str]) -> None:
    """Search resources matching QUERY."""
    client: FoundryClient = ctx.obj["client"]
    types = [resource_type] if resource_type else None
    results = client.catalog.search_resources(query, resource_types=types)
    click.echo(json.dumps([r.raw for r in results], indent=2))


@catalog.command("mkdir")
@click.argument("name")
@click.argument("parent_folder_rid")
@click.pass_context
def catalog_mkdir(ctx: click.Context, name: str, parent_folder_rid: str) -> None:
    """Create a new folder NAME inside PARENT_FOLDER_RID."""
    client: FoundryClient = ctx.obj["client"]
    folder = client.catalog.create_folder(name=name, parent_folder_rid=parent_folder_rid)
    click.echo(json.dumps(folder.raw, indent=2))


# ---------------------------------------------------------------------------
# ontology sub-group
# ---------------------------------------------------------------------------

@cli.group()
def ontology() -> None:
    """Commands for querying the Foundry Ontology."""


@ontology.command("list")
@click.pass_context
def ontology_list(ctx: click.Context) -> None:
    """List all available ontologies."""
    client: FoundryClient = ctx.obj["client"]
    onts = client.ontology.list_ontologies()
    click.echo(json.dumps([o.raw for o in onts], indent=2))


@ontology.command("object-types")
@click.argument("ontology_rid")
@click.pass_context
def ontology_object_types(ctx: click.Context, ontology_rid: str) -> None:
    """List object types in ONTOLOGY_RID."""
    client: FoundryClient = ctx.obj["client"]
    types = client.ontology.list_object_types(ontology_rid)
    click.echo(json.dumps([t.raw for t in types], indent=2))


@ontology.command("objects")
@click.argument("ontology_rid")
@click.argument("object_type")
@click.option("--limit", default=20, show_default=True, help="Max objects to list.")
@click.pass_context
def ontology_objects(
    ctx: click.Context, ontology_rid: str, object_type: str, limit: int
) -> None:
    """List objects of OBJECT_TYPE in ONTOLOGY_RID."""
    client: FoundryClient = ctx.obj["client"]
    objs = []
    for obj in client.ontology.list_objects(ontology_rid, object_type, page_size=limit):
        objs.append(obj.raw)
        if len(objs) >= limit:
            break
    click.echo(json.dumps(objs, indent=2))


@ontology.command("apply-action")
@click.argument("ontology_rid")
@click.argument("action_type")
@click.argument("parameters_json")
@click.pass_context
def ontology_apply_action(
    ctx: click.Context, ontology_rid: str, action_type: str, parameters_json: str
) -> None:
    """Apply ACTION_TYPE with PARAMETERS_JSON (a JSON object string)."""
    client: FoundryClient = ctx.obj["client"]
    try:
        params = json.loads(parameters_json)
    except json.JSONDecodeError as exc:
        raise click.BadParameter(f"Invalid JSON: {exc}") from exc
    result = client.ontology.apply_action(ontology_rid, action_type, params)
    click.echo(json.dumps(result.raw, indent=2))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    cli(auto_envvar_prefix="FOUNDRY")


if __name__ == "__main__":
    main()
