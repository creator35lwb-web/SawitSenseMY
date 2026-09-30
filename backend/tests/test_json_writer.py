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


def test_read_latest_round_trips_and_tolerates_missing_or_corrupt(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    assert json_writer.read_latest() is None
    json_writer.write_price_data({"cpo": {"date": "2026-09-28", "price_myr_per_tonne": 4664.0}})
    assert json_writer.read_latest()["cpo"]["date"] == "2026-09-28"
    (tmp_path / "latest.json").write_text("{not json", encoding="utf-8")
    assert json_writer.read_latest() is None


def _write_day(directory, date, price):
    (directory / f"prices_{date}.json").write_text(
        json.dumps({"cpo": {"date": date, "price_myr_per_tonne": price}}), encoding="utf-8"
    )


def test_history_index_lists_daily_cpo_prices_oldest_first(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    for date, price in [("2026-09-28", 4664.0), ("2026-09-24", 4772.0), ("2026-09-25", 4672.0)]:
        _write_day(tmp_path, date, price)
    # A failed day (no CPO) and an unreadable file are skipped.
    (tmp_path / "prices_2026-05-14.json").write_text(json.dumps({"cpo": None, "success": False}), encoding="utf-8")
    (tmp_path / "prices_broken.json").write_text("{not json", encoding="utf-8")

    assert json_writer.write_history() is True
    history = json.loads((tmp_path / "history.json").read_text(encoding="utf-8"))
    assert [d["date"] for d in history["days"]] == ["2026-09-24", "2026-09-25", "2026-09-28"]
    assert history["days"][-1]["cpo_price"] == pytest.approx(4664.0)


def test_history_index_keeps_only_the_most_recent_entries(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    for day in range(1, 11):
        _write_day(tmp_path, f"2026-09-{day:02d}", 4000.0 + day)
    json_writer.write_history(max_entries=3)
    history = json.loads((tmp_path / "history.json").read_text(encoding="utf-8"))
    assert [d["date"] for d in history["days"]] == ["2026-09-08", "2026-09-09", "2026-09-10"]


def test_each_snapshot_refreshes_the_history_index(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_price_data({"cpo": {"date": "2026-09-28", "price_myr_per_tonne": 4664.0}, "success": True})
    history = json.loads((tmp_path / "history.json").read_text(encoding="utf-8"))
    assert [d["date"] for d in history["days"]] == ["2026-09-28"]
    assert history["days"][0]["cpo_price"] == pytest.approx(4664.0)
