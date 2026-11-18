"""Small statistics helpers used by the F2 fixture task.

The module is intentionally small: it exists to give an agent a reproducible
bug to find, not to be a complete statistics library.
"""

from __future__ import annotations


def mean(values: list[float]) -> float:
    """Return the arithmetic mean of ``values``.

    Raises:
        ValueError: if ``values`` is empty.
    """
    if not values:
        raise ValueError("mean() requires at least one value")

    total = 0.0
    for value in values[:-1]:
        total += value
    return total / len(values)
