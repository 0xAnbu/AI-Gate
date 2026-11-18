"""Session manifest loading and validation.

Each capture session is described by a YAML manifest. The manifest is the
reproducibility contract of the dataset: it records the client, the model, the
network isolation parameters, the capture settings and the labels. A manifest
that does not match the versioned JSON Schema is rejected before it can be
used as experimental data.

The schema is packaged next to this module as ``manifest-v1.schema.json`` and
can be reused by external tools and CI without importing AIGate.
"""

from __future__ import annotations

import json
from importlib.resources import files
from pathlib import Path
from typing import Any

import jsonschema
import yaml

SCHEMA_PACKAGE = "aigate.capture"
SCHEMA_NAME = "manifest-v1.schema.json"


def load_schema() -> dict[str, Any]:
    """Return the version 1 manifest schema as a dictionary."""
    resource = files(SCHEMA_PACKAGE).joinpath(SCHEMA_NAME)
    return json.loads(resource.read_text(encoding="utf-8"))


def validate_manifest(manifest: dict[str, Any]) -> None:
    """Validate a manifest in memory.

    Raises:
        jsonschema.ValidationError: if the manifest does not match the schema.
    """
    schema = load_schema()
    jsonschema.Draft202012Validator(schema).validate(manifest)


def load_manifest(path: str | Path) -> dict[str, Any]:
    """Load a YAML manifest from disk and validate it.

    Returns:
        The parsed manifest.

    Raises:
        ValueError: if the file does not contain a YAML mapping.
        jsonschema.ValidationError: if the manifest does not match the schema.
    """
    with Path(path).open(encoding="utf-8") as handle:
        manifest = yaml.safe_load(handle)

    if not isinstance(manifest, dict):
        raise ValueError(f"{path}: manifest must be a YAML mapping")

    validate_manifest(manifest)
    return manifest
