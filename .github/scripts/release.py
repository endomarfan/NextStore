#!/usr/bin/env python3
import argparse
import datetime
import hashlib
import os
import re
import subprocess
import sys

FORK_POINT = os.environ.get("RELEASE_FORK_POINT", "4f3d18d98c5fbee72c80f787ceb2e8e09ded60a6")

CONVENTIONAL = re.compile(r"^(\w+)(?:\([^)]*\))?!?:\s*(.*)$")
GROUPS = [("feat", "### New"), ("fix", "### Fixes"), (None, "### Other changes")]


def git(*args, check=True):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        sys.exit(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip() if result.returncode == 0 else ""


def next_beta(base):
    tags = git("tag", "--list").splitlines()
    if f"v{base}" in tags:
        sys.exit(f"v{base} is already released; bump MARKETING_VERSION in Build.xcconfig first")
    pattern = re.compile(rf"^v{re.escape(base)}-beta\.(\d+)$")
    numbers = [int(m.group(1)) for m in map(pattern.match, tags) if m]
    return 1 + max(numbers, default=0)


def previous_ref(kind, sha, tag):
    args = ["describe", "--tags", "--abbrev=0", "--match", "v[0-9]*"]
    if kind == "stable":
        args += ["--exclude", "*-*"]
    found = git(*args, sha, check=False)
    if found and found == tag:
        found = git(*args, f"{sha}^", check=False)
    return found or FORK_POINT


def classify(subject):
    match = CONVENTIONAL.match(subject)
    if not match:
        return None, subject
    return match.group(1).lower(), match.group(2)


def changes(prev, sha, repo):
    log = git("log", "--no-merges", "--format=%H%x1f%s", f"{prev}..{sha}")
    entries = {"feat": [], "fix": [], None: []}
    for line in log.splitlines():
        full, subject = line.split("\x1f", 1)
        kind, text = classify(subject)
        text = (text[:1].upper() + text[1:]) if text else subject
        link = f"([{full[:7]}](https://github.com/{repo}/commit/{full}))"
        entries[kind if kind in ("feat", "fix") else None].append(f"- {text} {link}")
    lines = []
    for key, title in GROUPS:
        if entries[key]:
            lines += [title, *entries[key], ""]
    return lines


def notes(args):
    sha = git("rev-parse", args.sha)
    prev = previous_ref(args.kind, sha, args.tag)
    repo = args.repo
    out = []
    if args.kind == "nightly":
        out += [
            "> [!WARNING]",
            f"> **Nightly build** of `develop`, rebuilt after every change. It may be broken. For everyday use pick the [latest stable release](https://github.com/{repo}/releases/latest) or the newest beta.",
            "",
        ]
    elif args.kind == "beta":
        out += [
            "> [!NOTE]",
            f"> **Beta** for testing. If something breaks, please [open an issue](https://github.com/{repo}/issues/new/choose) with your device and iOS version.",
            "",
        ]
    elif args.promoted_from:
        out += [f"Promoted from **{args.promoted_from}** after device testing.", ""]
    if args.highlights and os.path.exists(args.highlights):
        text = open(args.highlights, encoding="utf-8").read().strip()
        if text:
            out += [text, ""]
    built = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    out += [
        f"**Version** `{args.version}` · **Commit** [{sha[:7]}](https://github.com/{repo}/commit/{sha}) · **Built** {built}",
        "",
    ]
    label = "the fork from SideStore" if prev == FORK_POINT else prev
    out += [f"## What's changed since {label}", ""]
    commits = changes(prev, sha, repo)
    out += commits if commits else [f"No changes since {label}.", ""]
    out += [
        "## Install",
        "",
        "1. Download **SideStore.ipa** below.",
        "2. Install it with [iLoader](https://iloader.app) over your existing SideStore. Your apps and settings are kept.",
        "",
    ]
    if args.kind != "nightly":
        out += [f"**Full changelog:** https://github.com/{repo}/compare/{prev}...{args.tag or sha}", ""]
    digest = hashlib.sha256(open(args.ipa, "rb").read()).hexdigest()
    out.append(f"<sub>SHA-256 of SideStore.ipa: `{digest}`</sub>")
    print("\n".join(out))


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    beta = sub.add_parser("next-beta")
    beta.add_argument("--base", required=True)
    note = sub.add_parser("notes")
    note.add_argument("--kind", required=True, choices=["nightly", "beta", "stable"])
    note.add_argument("--version", required=True)
    note.add_argument("--sha", required=True)
    note.add_argument("--repo", required=True)
    note.add_argument("--ipa", required=True)
    note.add_argument("--highlights")
    note.add_argument("--promoted-from")
    note.add_argument("--tag")
    args = parser.parse_args()
    if args.command == "next-beta":
        print(next_beta(args.base))
    else:
        notes(args)


if __name__ == "__main__":
    main()
