"""Tests for the weekly vulnerability check (D19).

OSV's answers are built here in the shape OSV gives them, so the tests never
contact OSV.

Author: SS (Claude Code), Oct 2026
"""

import re
import urllib.error
from unittest.mock import patch

import pytest

from monitor import vulnerabilities
from monitor.vulnerabilities import (
    ATTEMPTS,
    FIX_ADVICE,
    LOCK_FILE,
    find_vulnerabilities,
    locked_packages,
)

GHSA = "GHSA-6q48-6c7w-9gw2"
PYSEC = "PYSEC-2026-4320"

# OSV's record for the certifi advisory that #34 fixed, cut down.
CERTIFI_ADVISORY = {
    "id": GHSA,
    "summary": "certifi bundles emSign root CAs with compromised intermediate CA keys",
    "aliases": [PYSEC],
    "database_specific": {"severity": "CRITICAL"},
    "affected": [{
        "package": {"name": "certifi", "ecosystem": "PyPI"},
        "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "2019.03.09"}, {"fixed": "2026.10.19"}]}],
    }],
}
# The same advisory as the Python Packaging Advisory Database lists it.
CERTIFI_PYSEC = {"id": PYSEC, "aliases": [GHSA], "affected": CERTIFI_ADVISORY["affected"]}

OLD_PINS = [("certifi", "2026.7.22"), ("requests", "2.34.2")]


def _lock(*pins: str) -> str:
    """A lock file shaped like uv's: each pin with its hash and "via" lines."""
    lines = ["# Hash-locked dependencies", ""]
    for pin in pins:
        lines += [pin + " " + chr(92), "    --hash=sha256:" + "0" * 64, "    # via -r requirements.txt"]
    return "\n".join(lines) + "\n"


def _fake_osv(advisories: dict, records: dict):
    """An OSV stand-in. `advisories` maps "name==version" to advisory IDs and
    `records` maps an ID to OSV's record for it; a missing record fails to load."""
    calls = []

    def osv(path, payload=None, timeout=30):
        calls.append((path, payload))
        if path == "/querybatch":
            return {"results": [
                {"vulns": [{"id": i, "modified": "2026-10-20T22:11:14Z"} for i in ids]} if ids else {}
                for ids in (advisories.get(f"{q['package']['name']}=={q['version']}", [])
                            for q in payload["queries"])
            ]}
        vuln_id = path.rsplit("/", 1)[1]
        if vuln_id not in records:
            raise urllib.error.URLError("no answer")
        return records[vuln_id]

    return osv, calls


class TestLockedPackages:
    def test_reads_every_pin_in_the_real_lock_file(self):
        src = LOCK_FILE.read_text(encoding="utf-8")
        packages = locked_packages(src)
        names = [name for name, _ in packages]
        assert len(packages) == sum(1 for line in src.splitlines() if line[:1].isalnum())
        assert {"certifi", "requests", "beautifulsoup4", "urllib3"} <= set(names)
        assert all(re.fullmatch(r"[0-9][0-9A-Za-z.+!-]*", version) for _, version in packages)

    def test_names_are_compared_the_way_pypi_does(self):
        assert locked_packages(_lock("Typing_Extensions==4.16.0")) == [("typing-extensions", "4.16.0")]

    def test_a_line_that_is_not_an_exact_pin_fails(self):
        # A range would leave the installed version, and so the check, unknown.
        lock = _lock("certifi==2026.10.19", "requests>=2.31.0")
        with pytest.raises(ValueError, match="line 6 .* exact pin: requests>=2.31.0"):
            locked_packages(lock)

    def test_a_lock_file_without_pins_fails(self):
        with pytest.raises(ValueError, match="pins no packages"):
            locked_packages("# nothing here\n")


class TestFindVulnerabilities:
    def test_a_vulnerable_version_is_reported_once_with_its_fix(self):
        osv, _ = _fake_osv({"certifi==2026.7.22": [PYSEC, GHSA]}, {GHSA: CERTIFI_ADVISORY, PYSEC: CERTIFI_PYSEC})
        with patch.object(vulnerabilities, "osv", osv):
            findings = find_vulnerabilities(OLD_PINS)
        # The PYSEC entry is the same advisory under another name.
        assert findings == [("certifi", (
            "certifi 2026.7.22: GHSA-6q48-6c7w-9gw2 (critical), certifi bundles emSign root CAs with "
            "compromised intermediate CA keys. Fixed in 2026.10.19. "
            "https://osv.dev/vulnerability/GHSA-6q48-6c7w-9gw2"))]

    def test_versions_without_advisories_report_nothing(self):
        osv, calls = _fake_osv({}, {})
        with patch.object(vulnerabilities, "osv", osv):
            assert find_vulnerabilities(OLD_PINS) == []
        assert len(calls) == 1  # one batch question for all packages

    def test_an_advisory_is_still_reported_when_its_record_does_not_load(self):
        osv, _ = _fake_osv({"requests==2.34.2": ["GHSA-aaaa-bbbb-cccc"]}, {})
        with patch.object(vulnerabilities, "osv", osv):
            findings = find_vulnerabilities(OLD_PINS)
        assert findings == [("requests", "requests 2.34.2: GHSA-aaaa-bbbb-cccc. "
                                         "https://osv.dev/vulnerability/GHSA-aaaa-bbbb-cccc")]

    def test_an_advisory_without_a_fix_says_so(self):
        record = {"id": "GHSA-aaaa-bbbb-cccc", "summary": "Something.", "affected": [{
            "package": {"name": "requests", "ecosystem": "PyPI"},
            "ranges": [{"type": "ECOSYSTEM", "events": [{"introduced": "0"}]}]}]}
        osv, _ = _fake_osv({"requests==2.34.2": ["GHSA-aaaa-bbbb-cccc"]}, {"GHSA-aaaa-bbbb-cccc": record})
        with patch.object(vulnerabilities, "osv", osv):
            (_, line), = find_vulnerabilities(OLD_PINS)
        assert "requests 2.34.2: GHSA-aaaa-bbbb-cccc, Something. No fixed version yet." in line

    def test_a_withdrawn_advisory_is_not_reported(self):
        withdrawn = dict(CERTIFI_ADVISORY, aliases=[], withdrawn="2026-10-21T00:00:00Z")
        osv, _ = _fake_osv({"certifi==2026.7.22": [GHSA]}, {GHSA: withdrawn})
        with patch.object(vulnerabilities, "osv", osv):
            assert find_vulnerabilities(OLD_PINS) == []

    def test_a_summary_cannot_spill_into_the_log(self):
        # A line break in a summary could start a workflow command of its own.
        record = dict(CERTIFI_ADVISORY, summary="Bad" + chr(10) + "::add-mask::x " + "y" * 300)
        osv, _ = _fake_osv({"certifi==2026.7.22": [GHSA]}, {GHSA: record})
        with patch.object(vulnerabilities, "osv", osv):
            (_, line), = find_vulnerabilities(OLD_PINS)
        assert chr(10) not in line
        assert chr(13) not in line
        assert "Bad ::add-mask::x yyy" in line
        assert "y" * 200 not in line

    def test_only_package_names_and_versions_are_sent(self):
        osv, calls = _fake_osv({}, {})
        with patch.object(vulnerabilities, "osv", osv):
            find_vulnerabilities(OLD_PINS)
        assert calls == [("/querybatch", {"queries": [
            {"package": {"name": "certifi", "ecosystem": "PyPI"}, "version": "2026.7.22"},
            {"package": {"name": "requests", "ecosystem": "PyPI"}, "version": "2.34.2"},
        ]})]

    def test_an_answer_that_skips_packages_fails(self):
        with patch.object(vulnerabilities, "osv", return_value={"results": [{}]}):
            with pytest.raises(ValueError, match="1 of 2 packages"):
                find_vulnerabilities(OLD_PINS)


class TestMain:
    @pytest.fixture
    def lock(self, tmp_path):
        path = tmp_path / "requirements.lock"
        path.write_text(_lock("certifi==2026.7.22", "requests==2.34.2"), encoding="utf-8")
        return path

    @pytest.fixture
    def report(self, tmp_path, monkeypatch):
        path = tmp_path / "vulnerabilities.md"
        monkeypatch.setenv("VULN_REPORT", str(path))
        return path

    def test_passes_when_no_package_has_a_known_vulnerability(self, lock, report, capsys):
        osv, _ = _fake_osv({}, {})
        with patch.object(vulnerabilities, "osv", osv):
            assert vulnerabilities.main(lock) == 0
        assert "No known vulnerabilities in the 2 Python packages" in capsys.readouterr().out
        assert not report.exists()

    def test_a_vulnerability_fails_the_check_and_writes_the_alert(self, lock, report, capsys):
        osv, _ = _fake_osv({"certifi==2026.7.22": [GHSA]}, {GHSA: CERTIFI_ADVISORY})
        with patch.object(vulnerabilities, "osv", osv):
            assert vulnerabilities.main(lock) == 1
        title, blank, finding, *rest = report.read_text(encoding="utf-8").splitlines()
        assert title == "Known vulnerability in the scraper's Python packages: certifi"
        assert blank == ""
        assert finding.startswith("- certifi 2026.7.22: GHSA-6q48-6c7w-9gw2 (critical)")
        assert FIX_ADVICE in rest
        assert f"::error::{title}" in capsys.readouterr().out

    def test_osv_not_answering_is_retried_then_reported(self, lock, report, monkeypatch):
        sleeps = []
        monkeypatch.setattr(vulnerabilities.time, "sleep", sleeps.append)
        with patch.object(vulnerabilities, "osv", side_effect=urllib.error.URLError("timed out")) as osv:
            assert vulnerabilities.main(lock) == 1
        assert osv.call_count == ATTEMPTS
        assert sleeps == [vulnerabilities.RETRY_PAUSE] * (ATTEMPTS - 1)
        title = report.read_text(encoding="utf-8").splitlines()[0]
        assert title == "The vulnerability check couldn't get an answer from OSV"

    def test_osv_answering_on_a_later_try_passes(self, lock, monkeypatch):
        monkeypatch.setattr(vulnerabilities.time, "sleep", lambda seconds: None)
        answers = [urllib.error.URLError("timed out"), {"results": [{}, {}]}]
        with patch.object(vulnerabilities, "osv", side_effect=answers):
            assert vulnerabilities.main(lock) == 0

    def test_a_lock_file_it_cannot_read_fails(self, tmp_path, report):
        lock = tmp_path / "requirements.lock"
        lock.write_text(_lock("requests>=2.31.0"), encoding="utf-8")
        with patch.object(vulnerabilities, "osv") as osv:
            assert vulnerabilities.main(lock) == 1
        osv.assert_not_called()
        assert report.read_text(encoding="utf-8").startswith("The vulnerability check couldn't read requirements.lock")
