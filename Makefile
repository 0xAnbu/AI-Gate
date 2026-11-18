PYTHON ?= .venv/bin/python
RUFF ?= .venv/bin/ruff
PRE_COMMIT ?= .venv/bin/pre-commit

.PHONY: install install-dev lint format format-check test check pre-commit-install pre-commit clean

install:
	$(PYTHON) -m pip install -e .

install-dev:
	$(PYTHON) -m pip install -r requirements-dev.txt
	$(PYTHON) -m pip install -e .

lint:
	$(RUFF) check src tests scripts fixtures

format:
	$(RUFF) format src tests scripts fixtures

format-check:
	$(RUFF) format --check src tests scripts fixtures

test:
	$(PYTHON) -m pytest

check: lint format-check test

pre-commit-install:
	$(PRE_COMMIT) install

pre-commit:
	$(PRE_COMMIT) run --all-files

clean:
	rm -rf .pytest_cache .ruff_cache build dist src/*.egg-info
