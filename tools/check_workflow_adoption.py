"""Validate Base's full contract, then project only its generated router.

No Base code is copied or patched. Snapshot/dashboard remain upstream bytes.
The one project-specific generated output uses the template named in the adapter.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

ROUTER = ".agents/skills/tetris-workflow-router/SKILL.md"


def relative_path(value: str) -> str:
    if not value or ":" in value or "\\" in value or PurePosixPath(value).is_absolute() or ".." in PurePosixPath(value).parts:
        raise ValueError(f"Unsafe relative path: {value}")
    return value


def local_source(root: Path, value: str) -> Path:
    path = (root / relative_path(value)).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError(f"Source outside repository: {value}")
    return path


def git(root: Path, *args: str) -> str:
    return subprocess.run(["git", "-C", str(root), *args], check=True,
                          capture_output=True, encoding="utf-8").stdout.strip()


def project_artifacts(root: Path, upstream: dict[Path, bytes], router: bytes) -> dict[Path, bytes]:
    target = root / ROUTER
    if target not in upstream:
        raise ValueError("Base generator no longer exposes the expected router; review adoption")
    return {**upstream, target: router}


def sync_outputs(outputs: dict[Path, bytes], *, write: bool) -> list[Path]:
    mismatches = [path for path, data in outputs.items() if not path.is_file() or path.read_bytes() != data]
    if write:
        for path in mismatches:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(outputs[path])
    return mismatches


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--base-repository", type=Path, required=True)
    parser.add_argument("--protected-base", required=True, help="Externally verified trusted project baseline SHA")
    parser.add_argument("--external-approval", choices=("true", "false"), default="false")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    options = parser.parse_args()
    root, base = options.project_root.resolve(), options.base_repository.resolve()
    try:
        adapter = json.loads((root / "skills/PROJECT_BASE_ADAPTER.json").read_text(encoding="utf-8"))
        adoption = adapter["shared_overrides"]["workflow_adoption"]
        revision = adoption["source_commit"]
        if not re.fullmatch(r"[0-9a-f]{40}", revision):
            raise ValueError("Adopted Base source must be an exact SHA, not a moving ref")
        if git(base, "rev-parse", "HEAD") != revision:
            raise ValueError("Base checkout does not match adopted source; use a separate verified checkout")
        if git(base, "status", "--porcelain", "--untracked-files=normal"):
            raise ValueError("Base source checkout is dirty; do not execute modified validators")
        for path in adoption["reference_paths"]:
            git(base, "cat-file", "-e", f"{revision}:{relative_path(path)}")
        route_ids = {entry["skill_id"] for entry in adapter["routing"]["base_routes"]}
        if set(adoption["route_skill_ids"]) != route_ids:
            raise ValueError("Operational source mapping must cover exactly the selected Base routes")
        for skill_id in adoption["route_skill_ids"]:
            if not re.fullmatch(r"[a-z0-9-]+", skill_id):
                raise ValueError("Invalid operational Skill ID")
            git(base, "cat-file", "-e", f"{revision}:skills/{skill_id}/SKILL.md")
        # Import only after verifying the execution checkout, without writing to it.
        sys.dont_write_bytecode = True
        sys.path.insert(0, str(base / "tools"))
        import check_approved_project_operating_contract as approved

        approval = json.loads((root / "docs/operations/TETRIS_CURRENT_APPROVED_PROTECTED_CHANGE_SET.json").read_text(encoding="utf-8"))
        errors = approved.validate_project_contract(
            project_root=root, base_repository=base, protected_base=options.protected_base,
            approval_document=approval, externally_approved=options.external_approval == "true",
            check_generated=False,
        )
        if errors:
            raise ValueError("\n".join(errors))
        upstream = approved.contract.build_artifacts(root, base, prevalidated=True)
        template = local_source(root, adoption["router_template"]).read_bytes()
        outputs = project_artifacts(root, upstream, template)
        mismatches = sync_outputs(outputs, write=options.write)
        if mismatches and options.check:
            raise ValueError("Generated drift: " + ", ".join(str(path.relative_to(root)) for path in mismatches))
        print(f"Workflow adoption valid: Base {revision}; release {adapter['base_release']['version']} preserved")
        print(f"Generated outputs: {len(outputs)} checked; {len(mismatches) if options.write else 0} updated")
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Workflow adoption failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
