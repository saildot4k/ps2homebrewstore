#!/usr/bin/env python3
"""
PSU-AutomaticPacker.py

Recursively search `root` for psu.toml files. For each psu.toml found in:
    <root>/.../<folder>/psu.toml

Run:
    psu-packer.exe "<root>/.../<folder>" -o "<root>/.../<parent_of_folder>/<folder>.psu"

Features:
 - Safe handling of spaces in paths
 - Dry-run mode (shows commands instead of executing)
 - Optional explicit path to psu-packer.exe
 - Logging and exit codes for failed runs
"""

import argparse
import subprocess
import sys
from pathlib import Path
import shutil
import logging

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("psu_pack_runner")


def find_psu_toml_files(root: Path):
    """Yield Path objects for each psu.toml found under root (recursive)."""
    for p in root.rglob("psu.toml"):
        if p.is_file():
            yield p


def build_command(psupacker_exe: Path, folder_with_toml: Path, output_psu: Path):
    """
    Construct the command as a list suitable for subprocess.run:
      psu-packer.exe <folder_with_toml> -o <output_psu>
    """
    return [str(psupacker_exe), str(folder_with_toml), "-o", str(output_psu)]


def run_command(cmd, dry_run=False, env=None):
    """Run the command. Returns (success: bool, returncode: int)."""
    logger.info("Command: %s", " ".join(f'"{c}"' if " " in c else c for c in cmd))
    if dry_run:
        return True, 0

    try:
        result = subprocess.run(cmd, check=False, env=env)
        success = result.returncode == 0
        return success, result.returncode
    except FileNotFoundError:
        logger.error("Executable not found: %s", cmd[0])
        return False, 127
    except Exception as e:
        logger.error("Error running command %s: %s", cmd, e)
        return False, 1


def main():
    ap = argparse.ArgumentParser(
        description="Find psu.toml recursively and run psu-packer on the containing folder."
    )
    ap.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Root folder to start searching (default: current directory).",
    )
    ap.add_argument(
        "--psupacker",
        "-p",
        default=None,
        help="Path to psu-packer.exe (defaults to looking on PATH).",
    )
    ap.add_argument(
        "--dry-run",
        "-n",
        action="store_true",
        help="Don't execute commands; just print what would be run.",
    )
    ap.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Verbose logging.",
    )
    args = ap.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    root = Path(args.root).resolve()
    if not root.exists() or not root.is_dir():
        logger.error("Root path does not exist or is not a directory: %s", root)
        sys.exit(2)

    # Determine psu-packer.exe path
    psupacker_path = None
    if args.psupacker:
        psupacker_path = Path(args.psupacker).resolve()
        if not psupacker_path.exists():
            logger.error("Provided psupacker path does not exist: %s", psupacker_path)
            sys.exit(2)
    else:
        exe_name = "psu-packer.exe"
        found = shutil.which(exe_name)
        if found:
            psupacker_path = Path(found)
        else:
            logger.error(
                "psu-packer executable not found on PATH. Provide it via --psupacker / -p"
            )
            sys.exit(2)

    logger.info("Using psu-packer: %s", psupacker_path)

    found_any = False
    failures = []
    for toml_file in find_psu_toml_files(root):
        found_any = True
        folder_with_toml = toml_file.parent
        parent_folder = folder_with_toml.parent

        folder_name = folder_with_toml.name
        if not parent_folder or not parent_folder.exists():
            logger.error(
                "Parent folder does not exist for: %s (skipping)", folder_with_toml
            )
            failures.append((folder_with_toml, "no_parent"))
            continue

        output_psu = parent_folder / f"{folder_name}.psu"

        cmd = build_command(psupacker_path, folder_with_toml, output_psu)

        logger.info(
            "\nFound: %s\n -> Packing folder: %s\n -> Output: %s",
            toml_file,
            folder_with_toml,
            output_psu,
        )

        success, code = run_command(cmd, dry_run=args.dry_run)
        if not success:
            logger.error(
                "Failed to pack %s (exit code %s)", folder_with_toml, code
            )
            failures.append((folder_with_toml, code))
        else:
            logger.info("Success: created %s", output_psu)

    if not found_any:
        logger.info("No psu.toml files found under %s", root)

    if failures:
        logger.error("\nCompleted with failures (%d):", len(failures))
        for f, reason in failures:
            logger.error(" - %s : %s", f, reason)
        sys.exit(1)
    else:
        logger.info("\nCompleted successfully.")
        sys.exit(0)


if __name__ == "__main__":
    main()
