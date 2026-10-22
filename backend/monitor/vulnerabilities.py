"""Weekly vulnerability check of the scraper's Python packages (D19).

The scraper and CI install the 17 packages pinned in backend/requirements.lock,
but Dependabot only reads the 2 named in requirements.txt (D17). This asks the
OSV database (https://osv.dev), which includes GitHub's advisories, about every
pinned version. On 22 Oct 2026 an SS session found the certifi advisory
GHSA-6q48-6c7w-9gw2 this way, two days after it was published (#34); run
weekly, the check no longer waits for a session.

Only package names and versions are sent to OSV, and they are public in this
repo anyway.

Exit code 0 = no known vulnerabilities, 1 = at least one, or the check couldn't
run (the workflow then files an alert issue). When VULN_REPORT names a file,
the problem is also written there as markdown, title first, for that issue.

Author: SS (Claude Code), Oct 2026
"""

import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path

LOCK_FILE = Path(__file__).parent.parent / "requirements.lock"
OSV_API = "https://api.osv.dev/v1"
# How many times to ask OSV, and the seconds between tries, before giving up.
ATTEMPTS = 3
RETRY_PAUSE = 20

_PIN = re.compile(r"([A-Za-z0-9][A-Za-z0-9._-]*)==([^\s;]+)")

FIX_ADVICE = (
    "SS updates each package in a pull request: the fixed version and its hashes go in "
    "`backend/requirements.lock` (see its header), and CI and this check run on the PR. "
    "Close this issue once the fix merges."
)


def normalize(name: str) -> str:
    """A package name the way PyPI compares them (PEP 503)."""
    return re.sub(r"[-_.]+", "-", name).lower()


def locked_packages(lock_src: str) -> list:
    """(name, version) for every package pinned in requirements.lock.

    Every line that starts a requirement must be an exact pin, so a lock file
    this can't fully read fails the check, rather than passing with packages
    left unchecked.
    """
    packages = []
    for number, line in enumerate(lock_src.splitlines(), 1):
        if not line.strip() or line.startswith((" ", "\t", "#")):
            continue  # blank, a comment, or a "--hash" or "# via" line under a pin
        m = _PIN.match(line)
        if not m:
            raise ValueError(f"line {number} of requirements.lock isn't an exact pin: {line.strip()[:60]}")
        packages.append((normalize(m.group(1)), m.group(2)))
    if not packages:
        raise ValueError("requirements.lock pins no packages")
    return packages


def osv(path: str, payload: dict = None, timeout: int = 30) -> dict:
    """GET an OSV API path, or POST a JSON payload to it, and return the answer."""
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(OSV_API + path, data=data, headers={
        "Content-Type": "application/json",
        "User-Agent": "SawitSense vulnerability watchdog",
    })
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.load(resp)


def advisory_ids(packages: list) -> list:
    """For each package, in order, the IDs of OSV's advisories for its pinned version.

    OSV is asked up to ATTEMPTS times; an OSError means it never answered.
    """
    payload = {"queries": [{"package": {"name": name, "ecosystem": "PyPI"}, "version": version}
                           for name, version in packages]}
    for _ in range(ATTEMPTS - 1):
        try:
            results = osv("/querybatch", payload)["results"]
            break
        except OSError as e:
            print(f"OSV didn't answer ({e}); asking again in {RETRY_PAUSE} s")
            time.sleep(RETRY_PAUSE)
    else:  # the last try: if OSV still doesn't answer, its error ends the check
        results = osv("/querybatch", payload)["results"]
    if len(results) != len(packages):
        raise ValueError(f"OSV answered for {len(results)} of {len(packages)} packages")
    return [[vuln["id"] for vuln in (result.get("vulns") or [])] for result in results]


def fixed_versions(vuln: dict, package: str) -> list:
    """The versions of `package` that OSV says fix an advisory, in OSV's order."""
    fixed = []
    for affected in vuln.get("affected") or []:
        pkg = affected.get("package") or {}
        if pkg.get("ecosystem") == "PyPI" and normalize(pkg.get("name", "")) == package:
            for rng in affected.get("ranges") or []:
                fixed += [event["fixed"] for event in rng.get("events") or []
                          if rng.get("type") == "ECOSYSTEM" and "fixed" in event]
    return list(dict.fromkeys(fixed))


def describe(vuln_id: str, package: str) -> dict:
    """OSV's summary, severity, aliases and fixed versions for one advisory.

    Best effort: if OSV doesn't answer, the advisory is still reported by its
    ID. The summary is cut to one short line, so it can't spill into the
    workflow's log commands.
    """
    try:
        vuln = osv(f"/vulns/{vuln_id}", timeout=15)
    except (OSError, ValueError):
        return {}
    summary = " ".join(str(vuln.get("summary") or "").split())[:160].rstrip(".")
    return {
        "summary": summary,
        "severity": str((vuln.get("database_specific") or {}).get("severity") or "").lower(),
        "aliases": vuln.get("aliases") or [],
        "fixed": fixed_versions(vuln, package),
        "withdrawn": bool(vuln.get("withdrawn")),
    }


def finding_line(package: str, version: str, vuln_id: str, details: dict) -> str:
    """One line about one advisory, for the log and the alert issue."""
    line = f"{package} {version}: {vuln_id}"
    if details.get("severity"):
        line += f" ({details['severity']})"
    if details.get("summary"):
        line += f", {details['summary']}"
    line += "."
    if details.get("fixed"):
        line += f" Fixed in {' or '.join(details['fixed'])}."
    elif details:
        line += " No fixed version yet."
    return f"{line} https://osv.dev/vulnerability/{vuln_id}"


def find_vulnerabilities(packages: list) -> list:
    """(package, line) for each known vulnerability in the pinned versions; [] if none."""
    findings = []
    for (name, version), ids in zip(packages, advisory_ids(packages)):
        reported = set()
        for vuln_id in sorted(ids):  # a GHSA advisory before its PYSEC alias
            if vuln_id in reported:
                continue
            details = describe(vuln_id, name)
            if details.get("withdrawn"):
                continue
            reported.update([vuln_id, *details.get("aliases", [])])
            findings.append((name, finding_line(name, version, vuln_id, details)))
    return findings


def report_problem(title: str, lines: list, advice: str) -> int:
    """Print a problem for the run's log, write it for the alert issue, and return 1."""
    print(f"::error::{title}")
    for line in lines:
        print(f"::error::{line}")
    report = os.environ.get("VULN_REPORT")
    if report:
        text = "\n".join([title, "", *(f"- {line}" for line in lines), "", advice, ""])
        Path(report).write_text(text, encoding="utf-8")
    return 1


def main(lock_file: Path = LOCK_FILE) -> int:
    try:
        packages = locked_packages(lock_file.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        return report_problem("The vulnerability check couldn't read requirements.lock", [str(e)],
                              "Nothing was checked. Make every line an exact pin again, then run the check.")
    try:
        findings = find_vulnerabilities(packages)
    except (OSError, ValueError, KeyError, TypeError) as e:
        return report_problem("The vulnerability check couldn't get an answer from OSV",
                              [f"{type(e).__name__}: {e}"],
                              "Nothing is known to be wrong, but nothing was checked this time.")
    if findings:
        names = ", ".join(sorted({name for name, _ in findings}))
        return report_problem(f"Known vulnerability in the scraper's Python packages: {names}",
                              [line for _, line in findings], FIX_ADVICE)
    print(f"No known vulnerabilities in the {len(packages)} Python packages pinned in "
          "requirements.lock (checked against OSV).")
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else LOCK_FILE))
