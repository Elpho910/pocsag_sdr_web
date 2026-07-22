#!/usr/bin/env python3
import os
import re
import sys
import time
from datetime import datetime

DEDUP_WINDOW = int(os.environ.get("DEDUP_WINDOW", "60"))
seen = {}


def clean_line(raw: str) -> str:
    line = raw.rstrip("\n")
    line = line.replace("<NUL>", "")
    line = re.sub(r"<DEL>+", "", line)
    line = re.sub(r"@+$", "", line)
    line = re.sub(r"\s+$", "", line)
    return line


def extract_alpha_text(line: str) -> str:
    match = re.search(r"Alpha:\s*(.*)$", line)
    return match.group(1).strip() if match else ""


def normalize_payload_key(alpha_text: str) -> str:
    payload = alpha_text.split("//", 1)[1] if "//" in alpha_text else alpha_text
    payload = payload.strip()
    payload = re.sub(r"\s+", " ", payload)
    payload = payload.rstrip(" .")
    return payload.lower()


def prune_seen(now: float) -> None:
    cutoff = now - DEDUP_WINDOW
    stale = [key for key, ts in seen.items() if ts < cutoff]
    for key in stale:
        seen.pop(key, None)


for raw in sys.stdin:
    if "Alpha:" not in raw:
        continue

    line = clean_line(raw)
    if re.search(r"Alpha:\s*$", line):
        continue
    if not line:
        continue

    alpha_text = extract_alpha_text(line)
    if not alpha_text:
        continue

    dedupe_key = normalize_payload_key(alpha_text)
    if not dedupe_key:
        continue

    now = time.time()
    last = seen.get(dedupe_key)
    if last is not None and (now - last) < DEDUP_WINDOW:
        continue

    seen[dedupe_key] = now
    if len(seen) > 2000:
        prune_seen(now)

    received_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{received_ts}] {line}", flush=True)
