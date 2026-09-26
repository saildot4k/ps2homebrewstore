#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SAS-TIMESTAMPS
  - Fixed UTC base (matches web API): 2099-01-01 07:59:59Z == 12/31/2098 23:59:59 PST
  - CSV dry-run outputs
  - Dash-ignoring, effective-name ordering (e.g., BOOT → SYS_BOOT)
  - EXACT integer-based lex rank for within-day ordering (no floats)
  - NO hash nudge (preserve strict alphabetical order)
  - Recursively generates psu.toml next to any title.cfg

Windows-only: uses SetFileTime via ctypes to set ctime/mtime/atime.
"""

import argparse
import ctypes
import os
import sys
from datetime import datetime, timezone

# =========================
# ===== USER CONFIG =======
# =========================
SECONDS_BETWEEN_ITEMS = 1

# One day per category (86,400 seconds) → each category maps to a single December day.
SLOTS_PER_CATEGORY   = 86_400

# Comma-separated lists of names (no prefixes) to be treated as if they belong to these categories.
# Edit these to add your own folder names (case-insensitive). Whitespace is ignored.
UNPREFIXED_IN_CATEGORY_CSV = {
    "APP_":      "OSDXMB, XEBPLUS",
    "APPS":      "",  # exact "APPS" is its own name
    "PS1_":      "",
    "EMU_":      "",
    "GME_":      "",
    "DST_":      "",
    "DBG_":      "",
    "RAA_":      "RESTART, POWEROFF",
    "RTE_":      "NEUTRINO",
    "SYS_":      "BOOT",
    "ZZY_":      "EXPLOITS",
    "ZZZ_":      "BM, MATRIXTEAM, OPL",
}

# Category order (newest → oldest).
CATEGORY_ORDER = [
    "APP_",
    "APPS",
    "PS1_",
    "EMU_",
    "GME_",
    "DST_",
    "DBG_",
    "RAA_",
    "RTE_",
    "DEFAULT",   # non-matching fallbacks
    "SYS_",
    "ZZY_",
    "ZZZ_",
]

# =========================
# ===== END CONFIG  =======
# =========================

def _parse_csv(s: str):
    return {x.strip().upper() for x in s.split(",") if x.strip()} if s else set()

UNPREFIXED_MAP = {k: _parse_csv(v) for k, v in UNPREFIXED_IN_CATEGORY_CSV.items()}

# --- Windows FILETIME helpers (ctypes) ---
_EPOCH_AS_FILETIME = 11644473600  # seconds between 1601-01-01 and 1970-01-01
_HUNDREDS_OF_NS = 10_000_000

kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)

CreateFileW = kernel32.CreateFileW
CreateFileW.argtypes = [
    ctypes.c_wchar_p,
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.c_void_p,
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.c_void_p
]
CreateFileW.restype = ctypes.c_void_p

SetFileTime = kernel32.SetFileTime
SetFileTime.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
SetFileTime.restype = ctypes.c_int

CloseHandle = kernel32.CloseHandle
CloseHandle.argtypes = [ctypes.c_void_p]
CloseHandle.restype = ctypes.c_int

GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 0x00000001
FILE_SHARE_WRITE = 0x00000002
FILE_SHARE_DELETE = 0x00000004
OPEN_EXISTING = 3
FILE_FLAG_BACKUP_SEMANTICS = 0x02000000  # needed to open directories

class FILETIME(ctypes.Structure):
    _fields_ = [("dwLowDateTime", ctypes.c_uint32),
                ("dwHighDateTime", ctypes.c_uint32)]

def _dt_to_filetime(dt_utc: datetime) -> FILETIME:
    unix_seconds = dt_utc.timestamp()
    ft = int((unix_seconds + _EPOCH_AS_FILETIME) * _HUNDREDS_OF_NS)
    return FILETIME(ft & 0xFFFFFFFF, ft >> 32)

def _set_times_windows(path: str, dt_utc: datetime) -> None:
    handle = CreateFileW(
        path,
        GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        None,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS,
        None
    )
    if handle == ctypes.c_void_p(-1).value or handle is None:
        raise OSError(f"Failed to open handle for: {path} (WinError {ctypes.get_last_error()})")
    try:
        ft = _dt_to_filetime(dt_utc)
        if not SetFileTime(handle,
                           ctypes.byref(ft),
                           ctypes.byref(ft),
                           ctypes.byref(ft)):
            raise OSError(f"SetFileTime failed for: {path} (WinError {ctypes.get_last_error()})")
    finally:
        CloseHandle(handle)

# --- Category + name → slot mapping ---
# Sorting charset (we keep '-' in the set, but we strip dashes from payload for ordering)
CHARSET = tuple(" 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_-.")
CHAR_INDEX = {ch: i for i, ch in enumerate(CHARSET)}
MAX_CODE = len(CHARSET) - 1
BASE = MAX_CODE + 1  # base for integer rank

CATEGORY_BLOCK_SECONDS = SLOTS_PER_CATEGORY * SECONDS_BETWEEN_ITEMS
CATEGORY_INDEX = {name: idx for idx, name in enumerate(CATEGORY_ORDER)}

def _effective_category_key(eff: str) -> str:
    if eff.startswith("APP_"): return "APP_"
    if eff == "APPS": return "APPS"
    if eff.startswith("PS1_"): return "PS1_"
    if eff.startswith("EMU_"): return "EMU_"
    if eff.startswith("GME_"): return "GME_"
    if eff.startswith("DST_"): return "DST_"
    if eff.startswith("DBG_"): return "DBG_"
    if eff.startswith("RAA_"): return "RAA_"
    if eff.startswith("RTE_"): return "RTE_"
    if eff.startswith("SYS_") or eff == "SYS": return "SYS_"
    if eff.startswith("ZZY_"): return "ZZY_"
    if eff.startswith("ZZZ_"): return "ZZZ_"
    return "DEFAULT"

def _category_label_for_effective(eff: str) -> str:
    key = _effective_category_key(eff)
    return "DEFAULT" if key == "DEFAULT" else (key if key == "APPS" else f"{key}*")

def _payload_for_effective(eff: str) -> str:
    """Use only the part after the category key, ignoring dashes for ordering."""
    key = _effective_category_key(eff)
    if key == "APPS": return "APPS"
    if key == "DEFAULT": return eff.replace("-", "")
    payload = eff[len(key):] if eff.startswith(key) else eff
    return payload.replace("-", "")

# ---- EXACT integer lex rank (strict lexicographic order, dash-ignored) ----
# We compute a fixed-length base-B integer where each character is a "digit".
# Shorter strings are padded with 0 digits (a true terminator) so a shorter string
# with a given prefix is always ranked before any longer extension.
RANK_WIDTH = 48  # number of characters considered; large enough for your names

def _lex_rank(payload: str) -> int:
    s = payload.upper()
    if len(s) > RANK_WIDTH:
        s = s[:RANK_WIDTH]
    rank = 0
    for ch in s:
        code = CHAR_INDEX.get(ch, MAX_CODE)  # unknown chars -> max code (push to the end)
        rank = rank * BASE + (code + 1)      # +1 so that padding 0 stays strictly smaller than any real char
    # pad remaining positions with 0 (true terminator)
    for _ in range(RANK_WIDTH - len(s)):
        rank = rank * BASE  # append 0 digit
    return rank  # 0 .. BASE**RANK_WIDTH - 1

def _slot_from_rank(rank: int) -> int:
    # Map integer rank to slot 0..SLOTS_PER_CATEGORY-1 without floats:
    # slot = floor( rank * SLOTS / (BASE**RANK_WIDTH) )
    denom = pow(BASE, RANK_WIDTH)
    # Use integer multiplication then floor division for exactness.
    slot = (rank * SLOTS_PER_CATEGORY) // denom
    # prevent edge-case overflow
    if slot >= SLOTS_PER_CATEGORY:
        slot = SLOTS_PER_CATEGORY - 1
    return slot

def _normalize_name_for_rules(name: str) -> str:
    """
    Return the EFFECTIVE (possibly prefixed) name for all logic.
    We do not strip dashes here; dashes are ignored later during ordering only.
    """
    n = name.strip().upper()

    # 1) User-configured "no-prefix" names
    for cat_key, names in UNPREFIXED_MAP.items():
        if n in names:
            return "APPS" if cat_key == "APPS" else f"{cat_key}{n}"

    # 2) Built-in defaults
    if n in ("OSDXMB", "XEBPLUS"):
        return "APP_" + n
    if n in ("RESTART", "POWEROFF"):
        return "RAA_" + n
    if n == "NEUTRINO":
        return "RTE_" + n
    if n == "BOOT":
        return "SYS_BOOT"
    if n == "EXPLOITS":
        return "ZZY_EXPLOITS"
    if n in ("BM", "MATRIXTEAM", "OPL"):
        return "ZZZ_" + n

    # 3) Otherwise, leave as-is
    return n

def _category_priority_index(effective: str) -> int:
    key = _effective_category_key(effective)
    return CATEGORY_INDEX[key]

def _slot_index_within_category(effective: str) -> int:
    """
    Compute within-category slot using the EFFECTIVE name. Dashes ignored; underscores kept.
    Uses exact integer lex rank → exact integer slot.
    """
    payload = _payload_for_effective(effective)
    rank = _lex_rank(payload)
    slot = _slot_from_rank(rank)
    return slot

def _deterministic_offset_seconds(folder_name: str):
    eff = _normalize_name_for_rules(folder_name)
    cat_idx = _category_priority_index(eff)
    slot    = _slot_index_within_category(eff)

    # No tie-breaker nudge — strict lex order.
    nudge = 0

    cat_offset  = cat_idx * CATEGORY_BLOCK_SECONDS
    name_offset = (slot * SECONDS_BETWEEN_ITEMS) + nudge
    return cat_offset + name_offset, cat_idx, slot, eff

# --- Timestamp planner (FIXED UTC BASE) ---
FIXED_BASE_UTC = datetime(2099, 1, 1, 7, 59, 59, tzinfo=timezone.utc)

def _base_datetime_utc() -> datetime:
    return FIXED_BASE_UTC

def _planned_timestamp_for_folder(folder_name: str):
    base_utc = _base_datetime_utc()
    offset_sec, cat_idx, slot_idx, eff = _deterministic_offset_seconds(folder_name)
    ts_utc = datetime.fromtimestamp(base_utc.timestamp() - offset_sec, tz=timezone.utc)
    return ts_utc, eff, _category_label_for_effective(eff), cat_idx, slot_idx, offset_sec

# --- Walk and set ---
def _set_folder_and_contents_times(root_folder: str, dt_utc: datetime, verbose=False):
    for dirpath, dirnames, filenames in os.walk(root_folder):
        for fname in filenames:
            fpath = os.path.join(dirpath, fname)
            try:
                _set_times_windows(fpath, dt_utc)
                if verbose: print(f"Set file  : {fpath}")
            except Exception as e:
                print(f"[WARN] Could not set times for file {fpath}: {e}", file=sys.stderr)
        for dname in dirnames:
            dpath = os.path.join(dirpath, dname)
            try:
                _set_times_windows(dpath, dt_utc)
                if verbose: print(f"Set dir   : {dpath}")
            except Exception as e:
                print(f"[WARN] Could not set times for dir  {dpath}: {e}", file=sys.stderr)
    try:
        _set_times_windows(root_folder, dt_utc)
        if verbose: print(f"Set ROOT  : {root_folder}")
    except Exception as e:
        print(f"[WARN] Could not set times for ROOT {root_folder}: {e}", file=sys.stderr)

# --- Dry-run writer (CSV) ---
def _write_dryrun_csv(plan, base_path: str, verbose=False) -> str:
    cwd = os.getcwd()
    out_path = os.path.join(cwd, "SAS-TIMESTAMPS-dryrun.csv")
    plan_sorted = sorted(plan, key=lambda x: x[1], reverse=True)

    with open(out_path, "w", encoding="utf-8", newline="") as f:
        f.write("Order,Category,CatIndex,Slot,OffsetSec,Name,EffectiveName,Payload,LocalTime,UTC,FullPath\n")
        for idx, (name, ts_utc, eff, cat_lbl, cat_idx, slot_idx, offset_sec) in enumerate(plan_sorted, start=1):
            payload = _payload_for_effective(eff)
            local_str = ts_utc.astimezone().strftime("%m/%d/%Y %H:%M:%S %Z")
            utc_str = ts_utc.strftime("%Y-%m-%d %H:%M:%S UTC")
            full = os.path.join(base_path, name)
            f.write(f"{idx},{cat_lbl},{cat_idx},{slot_idx},{offset_sec},"
                    f"{name},{eff},{payload},{local_str},{utc_str},{full}\n")

    if verbose:
        print(f"[DRY-RUN] Wrote plan to: {out_path}")
        print(f"[DRY-RUN] {len(plan_sorted)} root folders listed (newest → oldest).")
    return out_path

# --- PSU TOML writer & scanner ---
def _write_psu_toml(dir_path: str, folder_name: str, ts_utc: datetime, dry_run=False, verbose=False):
    ts_str = ts_utc.strftime("%Y-%m-%d %H:%M:%S")
    toml = (
        "[config]\n"
        f"name = \"{folder_name}\"\n"
        "exclude = [ \"psu.toml\" ]\n"
        f"timestamp = \"{ts_str}\"\n"
    )
    out_path = os.path.join(dir_path, "psu.toml")
    if dry_run:
        return out_path, toml
    try:
        with open(out_path, "w", encoding="utf-8", newline="") as f:
            f.write(toml)
        if verbose:
            print(f"[PSU] Wrote: {out_path}")
    except Exception as e:
        print(f"[WARN] Could not write {out_path}: {e}", file=sys.stderr)
    return out_path, toml

def _scan_and_generate_psu(base_path: str, dry_run=False, verbose=False):
    findings = []
    for dirpath, dirnames, filenames in os.walk(base_path):
        if "title.cfg" in filenames:
            folder_name = os.path.basename(dirpath)
            ts_utc, _, _, _, _, _ = _planned_timestamp_for_folder(folder_name)
            psu_path, _ = _write_psu_toml(dirpath, folder_name, ts_utc, dry_run=dry_run, verbose=verbose)
            findings.append((dirpath, folder_name, ts_utc, psu_path))
    return findings

def _write_psu_dryrun_csv(findings, verbose=False) -> str:
    cwd = os.getcwd()
    out_path = os.path.join(cwd, "SAS-PSU-dryrun.csv")
    findings_sorted = sorted(findings, key=lambda x: x[2], reverse=True)

    with open(out_path, "w", encoding="utf-8", newline="") as f:
        f.write("Order,Folder,TimestampUTC,DirPath,TomlPath\n")
        for idx, (dpath, name, ts_utc, toml_path) in enumerate(findings_sorted, start=1):
            f.write(f"{idx},{name},{ts_utc.strftime('%Y-%m-%d %H:%M:%S')},{dpath},{toml_path}\n")

    if verbose:
        print(f"[DRY-RUN] PSU plan written to: {out_path}")
        print(f"[DRY-RUN] {len(findings_sorted)} psu.toml files would be created.")
    return out_path

# --- Main ---
def main():
    ap = argparse.ArgumentParser(
        description="Deterministically set ctime/mtime recursively by folder name and category, and generate psu.toml next to title.cfg."
    )
    ap.add_argument("path", nargs="?", default=".",
                    help="Top-level directory containing the root folders to timestamp (default: current dir).")
    ap.add_argument("--dry-run", action="store_true",
                    help="Do NOT modify timestamps or write psu.toml; output CSVs in the current working directory.")
    ap.add_argument("--verbose", action="store_true", help="Extra logging.")
    args = ap.parse_args()

    base_path = os.path.abspath(args.path)
    if not os.path.isdir(base_path):
        print(f"Not a directory: {base_path}", file=sys.stderr)
        sys.exit(1)

    root_folders = [d for d in os.listdir(base_path) if os.path.isdir(os.path.join(base_path, d))]

    if args.verbose:
        print(f"Found {len(root_folders)} root folders under {base_path}")

    plan = []
    for name in root_folders:
        try:
            ts, eff, cat_lbl, cat_idx, slot_idx, offset_sec = _planned_timestamp_for_folder(name)
        except Exception as e:
            print(f"[WARN] Failed to compute timestamp for {name}: {e}", file=sys.stderr)
            continue
        plan.append((name, ts, eff, cat_lbl, cat_idx, slot_idx, offset_sec))

    psu_findings = _scan_and_generate_psu(base_path, dry_run=args.dry_run, verbose=args.verbose)

    if args.dry_run:
        csv1 = _write_dryrun_csv(plan, base_path, verbose=args.verbose)
        csv2 = _write_psu_dryrun_csv(psu_findings, verbose=args.verbose)
        print(f"Dry-run complete.\n  - Timestamps plan: {csv1}\n  - PSU plan:        {csv2}")
        return

    for name, ts, eff, cat_lbl, cat_idx, slot_idx, offset_sec in plan:
        full = os.path.join(base_path, name)
        if args.verbose:
            print(f"=== {name} [{cat_lbl}] cat={cat_idx} slot={slot_idx} offset={offset_sec}s -> "
                  f"{ts.astimezone().strftime('%m/%d/%Y %H:%M:%S %Z')} (UTC {ts.strftime('%Y-%m-%d %H:%M:%S')}) ===")
        _set_folder_and_contents_times(full, ts, verbose=args.verbose)

if __name__ == "__main__":
    if os.name != "nt":
        print("This script is intended for Windows (uses SetFileTime).", file=sys.stderr)
        sys.exit(1)
    main()
