"""Package a skill folder into a `.skill` file (a zip archive).

Usage:
    python -m scripts.package_skill <path/to/skill-folder> [--output <file.skill>]

The `.skill` file is a zip of the skill directory contents (the directory's
basename becomes the skill name). Designed to run anywhere with Python and a
filesystem.
"""

from __future__ import annotations

import argparse
import os
import sys
import zipfile
from pathlib import Path


def package(skill_dir: Path, output: Path | None = None) -> Path:
    if not skill_dir.is_dir():
        raise SystemExit(f"skill folder not found: {skill_dir}")
    if not (skill_dir / "SKILL.md").is_file():
        raise SystemExit(f"not a skill folder (no SKILL.md): {skill_dir}")

    name = skill_dir.name
    out = output or skill_dir.parent / f"{name}.skill"
    out = out.resolve()

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _dirs, files in os.walk(skill_dir):
            for fn in files:
                p = Path(root) / fn
                arc = p.relative_to(skill_dir.parent)
                zf.write(p, arc)
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Package a skill folder into a .skill zip.")
    ap.add_argument("skill_dir", help="path to the skill folder (contains SKILL.md)")
    ap.add_argument("--output", default=None, help="output .skill file path")
    args = ap.parse_args(argv)
    out = package(Path(args.skill_dir).resolve(), Path(args.output).resolve() if args.output else None)
    print(f"packaged: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
