"""Tests for the JSON writer.

Author: SS (Claude Code), Sep 2026
"""

import json

import pytest

from writer import json_writer


def test_writes_latest_and_dated_snapshot(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    ok = json_writer.write_price_data(
        {"cpo": {"date": "2026-09-28", "price_myr_per_tonne": 4664.0}, "success": True}
    )
    assert ok is True
    latest = json.loads((tmp_path / "latest.json").read_text(encoding="utf-8"))
    assert latest["cpo"]["price_myr_per_tonne"] == pytest.approx(4664.0)
    assert "updated_at" in latest
    assert (tmp_path / "prices_2026-09-28.json").exists()


def test_snapshot_without_cpo_is_filed_under_today(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_price_data({"cpo": None, "success": False})
    assert len(list(tmp_path.glob("prices_*.json"))) == 1
