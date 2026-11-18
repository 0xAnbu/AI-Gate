# Fixture workspace

This directory is copied into `data/work/<session_id>/` before each capture
session. Agents must work only with the files listed here.

| File | Used by | Purpose |
|---|---|---|
| `input.txt` | F1 | Source text for the five-bullet summary. |
| `buggy_stats.py` | F2 | Module with a reproducible off-by-one bug. |
| `test_buggy_stats.py` | F2 | Test that fails until the bug is fixed. |
| `README.md` | All | This description. |

F3 does not need local input files: it queries the fixture server described in
`fixtures/fixture_server.py`.

The workspace is deliberately tiny and contains no personal data. Changing any
file here changes the experiment and requires a new prompt or fixture hash.
