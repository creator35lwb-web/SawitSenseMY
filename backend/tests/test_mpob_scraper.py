"""Tests for MPOB BEPI scraper.

Author: QQ (Qoder CSO)
"""

import pytest
from scrapers.mpob_bepi import (
    parse_price,
    calculate_fair_price,
    get_price_verdict,
    oer_sensitivity,
)


class TestParsePrice:
    def test_plain_number(self):
        assert parse_price("4600.00") == 4600.00

    def test_comma_number(self):
        assert parse_price("4,600.00") == 4600.00

    def test_rm_prefix(self):
        assert parse_price("RM 4600") == 4600.0

    def test_rm_prefix_with_comma(self):
        assert parse_price("RM 4,578.00") == 4578.00

    def test_nt(self):
        assert parse_price("NT") is None

    def test_dash(self):
        assert parse_price("-") is None

    def test_empty(self):
        assert parse_price("") is None

    def test_none(self):
        assert parse_price(None) is None

    def test_whitespace(self):
        assert parse_price("  42.77  ") == 42.77

    def test_small_number(self):
        assert parse_price("42.77") == 42.77


class TestCalculateFairPrice:
    def test_sdn_bhd_receipt(self):
        """PV-85935: Price_1% = 42.77, OER = 18.00 -> RM 769.86"""
        result = calculate_fair_price(42.77, 18.00)
        assert result == 769.86

    def test_south_region_example(self):
        """README example: Rate = 24.40, OER = 20.5 -> RM 500.20"""
        result = calculate_fair_price(24.40, 20.5)
        assert result == 500.20

    def test_sabah_region(self):
        """Sabah: Rate = 21.50, OER = 22.5 -> RM 483.75"""
        result = calculate_fair_price(21.50, 22.5)
        assert result == 483.75

    def test_zero_oer(self):
        result = calculate_fair_price(42.77, 0)
        assert result == 0.0

    def test_high_oer(self):
        result = calculate_fair_price(42.77, 22.0)
        assert result == 940.94


class TestPriceVerdict:
    def test_green_exact_match(self):
        v = get_price_verdict(770, 770)
        assert v["verdict"] == "GREEN"

    def test_green_above(self):
        v = get_price_verdict(800, 770)
        assert v["verdict"] == "GREEN"

    def test_green_slightly_below(self):
        v = get_price_verdict(740, 770)
        assert v["verdict"] == "GREEN"

    def test_amber(self):
        v = get_price_verdict(680, 770)
        assert v["verdict"] == "AMBER"

    def test_red(self):
        v = get_price_verdict(600, 770)
        assert v["verdict"] == "RED"

    def test_gap_calculation(self):
        v = get_price_verdict(860, 770)
        assert v["gap_rm"] == 90.0


class TestOERSensitivity:
    def test_default_range(self):
        result = oer_sensitivity(42.77)
        assert len(result) == 8  # 16 to 23 inclusive
        assert result[0]["oer_pct"] == 16
        assert result[-1]["oer_pct"] == 23

    def test_price_at_18(self):
        result = oer_sensitivity(42.77)
        oer_18 = [r for r in result if r["oer_pct"] == 18][0]
        assert oer_18["price_per_tonne"] == 769.86

    def test_each_pct_worth(self):
        result = oer_sensitivity(42.77)
        oer_18 = [r for r in result if r["oer_pct"] == 18][0]
        oer_19 = [r for r in result if r["oer_pct"] == 19][0]
        diff = round(oer_19["price_per_tonne"] - oer_18["price_per_tonne"], 2)
        assert diff == 42.77  # Each 1% OER = Price_1%
