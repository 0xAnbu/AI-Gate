"""Tests for the F2 fixture module.

Run with: python -m unittest -v test_buggy_stats.py
"""

from __future__ import annotations

import unittest

from buggy_stats import mean


class MeanTests(unittest.TestCase):
    def test_mean_of_three_values(self) -> None:
        self.assertEqual(mean([1, 2, 3]), 2)

    def test_mean_of_single_value(self) -> None:
        self.assertEqual(mean([4]), 4)

    def test_mean_with_negative_values(self) -> None:
        self.assertEqual(mean([-2, 0, 2]), 0)

    def test_empty_input_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            mean([])


if __name__ == "__main__":
    unittest.main()
