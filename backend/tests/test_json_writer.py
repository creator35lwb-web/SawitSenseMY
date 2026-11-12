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


# --- MPOB's daily prices in history.json (D26) ---

OCT_22 = {"date": "2026-10-22", "prices": {"North": 47.82, "Sabah": 43.06}}
OCT_23 = {"date": "2026-10-23", "prices": {"North": 47.87, "Sabah": 43.11}}


def _history(directory):
    return json.loads((directory / "history.json").read_text(encoding="utf-8"))


def test_history_keeps_mpobs_daily_prices_oldest_first(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_history(ffb_days=[OCT_23, OCT_22])
    history = _history(tmp_path)
    assert history["ffb_days"] == [OCT_22, OCT_23]
    assert history["ffb_source"] == "MPOB Daily FFB Reference Price (mill gate)"


def test_earlier_days_stay_when_a_run_reads_only_new_ones(tmp_path, monkeypatch):
    # Last month's days are read once; later runs bring only this month's.
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_history(ffb_days=[OCT_22])
    json_writer.write_history(ffb_days=[OCT_23])
    assert _history(tmp_path)["ffb_days"] == [OCT_22, OCT_23]


def test_a_run_that_could_not_read_mpob_keeps_the_history(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_history(ffb_days=[OCT_22, OCT_23])
    json_writer.write_history()
    assert _history(tmp_path)["ffb_days"] == [OCT_22, OCT_23]


def test_a_day_read_again_replaces_the_earlier_copy(tmp_path, monkeypatch):
    # MPOB added 26 Oct 2026 a day late; it may also correct a figure.
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_history(ffb_days=[OCT_22])
    corrected = {"date": "2026-10-22", "prices": {"North": 47.80, "Sabah": 43.06}}
    json_writer.write_history(ffb_days=[corrected])
    assert _history(tmp_path)["ffb_days"] == [corrected]


def test_mpobs_history_keeps_only_the_most_recent_days(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    days = [{"date": f"2026-10-{day:02d}", "prices": {"North": 40.0 + day}} for day in range(1, 11)]
    json_writer.write_history(max_entries=3, ffb_days=days)
    assert [d["date"] for d in _history(tmp_path)["ffb_days"]] == ["2026-10-08", "2026-10-09", "2026-10-10"]


def test_the_cpo_history_is_unchanged_beside_mpobs(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    _write_day(tmp_path, "2026-10-22", 4792.0)
    json_writer.write_history(ffb_days=[OCT_22])
    assert _history(tmp_path)["days"] == [{"date": "2026-10-22", "cpo_price": 4792.0}]


def test_each_snapshot_passes_mpobs_days_to_the_history(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    json_writer.write_price_data({"cpo": None, "success": True}, ffb_days=[OCT_22])
    assert _history(tmp_path)["ffb_days"] == [OCT_22]


@pytest.mark.parametrize("content", ["{not json", "[]", '{"ffb_days": "none"}', '{"ffb_days": [1, {"date": 5}]}'])
def test_a_history_file_that_cannot_be_read_starts_again(tmp_path, monkeypatch, content):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    (tmp_path / "history.json").write_text(content, encoding="utf-8")
    assert json_writer.read_ffb_history() == {}


def test_a_history_file_from_before_d26_has_no_mpob_days(tmp_path, monkeypatch):
    monkeypatch.setattr(json_writer, "JSON_DIR", tmp_path)
    (tmp_path / "history.json").write_text(json.dumps({"days": []}), encoding="utf-8")
    assert json_writer.read_ffb_history() == {}
