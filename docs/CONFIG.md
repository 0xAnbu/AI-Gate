# ENTREGA 2 — Entorno y estructura: comandos y verificaciones

> Documento operativo de la Entrega 2. Recoge, punto por punto, qué problema se resolvió, qué archivo o comando lo resuelve y cómo comprobar que la solución es correcta.
>
> Ámbito: puntos 1–8 de los problemas pendientes de la Entrega 2.
> Fuera de ámbito: punto 9 (commit), que corresponde al usuario.
>
> Última actualización: 2026-11-15

---

## 0. Preparación

Todos los comandos se ejecutan desde la raíz del proyecto:

```bash
cd /home/kali/Opencode/repos/aigate
source .venv/bin/activate
```

Comprobación previa del entorno:

```bash
python --version        # Python 3.14.8
python -m pip check     # No broken requirements found.
```

El `Makefile` usa rutas explícitas a `.venv/bin/...`, por lo que los objetivos de `make` funcionan con o sin el entorno activado, siempre que `.venv` exista.

## Resumen

| # | Punto | Solución | Verificación principal |
|---|---|---|---|
| 1 | Makefile | `Makefile` | `make -n check`, `make check` |
| 2 | pre-commit | `.pre-commit-config.yaml` + `pre-commit install` | `pre-commit run --files ...` |
| 3 | CI | `.github/workflows/tests.yml` | Parseo YAML + comprobación de comandos |
| 4 | Tests de infraestructura | `tests/unit/test_infrastructure.py` | `python -m pytest` |
| 5 | Paquete instalado y setuptools | `requirements-dev.txt`, `pyproject.toml` + instalación | `pip show aigate`, `pip check` |
| 6 | Separación runtime/dev | `requirements.txt`, `requirements-dev.txt`, `pyproject.toml` | Test dedicado + `grep` |
| 7 | Subpaquetes importables | `src/aigate/*/__init__.py` | Importación de los cinco subpaquetes |
| 8 | Directorios de datos | `data/interim/.gitkeep`, `data/manifests/.gitkeep`, `.gitignore` | `find` + `git check-ignore` |

---

## 1. Makefile operativo

**Qué hace y objetivo:** centralizar en una sola interfaz las tareas de instalación, lint, formato y test. Evita depender de recordar comandos manuales y garantiza que todas las comprobaciones se ejecutan igual en cada sesión.

**Archivo creado**

- `Makefile`

Contiene los objetivos `install`, `install-dev`, `lint`, `format`, `format-check`, `test`, `check`, `pre-commit-install`, `pre-commit` y `clean`. Usa `PYTHON ?= .venv/bin/python`, `RUFF ?= .venv/bin/ruff` y `PRE_COMMIT ?= .venv/bin/pre-commit`, de modo que no es necesario activar el entorno en cada comando.

**Verificación del contenido**

```bash
# Los objetivos requeridos existen y tienen receta
grep -E '^(install|install-dev|lint|format|format-check|test|check|pre-commit-install|pre-commit|clean):' Makefile

# Ensayo sin ejecutar: muestra las recetas resueltas
make -n check

# Test automático que valida los objetivos mínimos
python -m pytest tests/unit/test_infrastructure.py::test_makefile_defines_required_targets -q

# Ejecución real de lint + formato + tests
make check
```

Resultado esperado: `All checks passed!`, `9 files already formatted`, `10 passed`.

---

## 2. pre-commit configurado y hooks instalados

**Qué hace y objetivo:** ejecutar controles automáticos antes de cada commit (Ruff, formato, validación YAML/JSON/TOML, fin de archivo, espacios, claves privadas, tamaño máximo y pytest), de forma que un error no llegue al historial de Git.

**Archivo creado**

- `.pre-commit-config.yaml`

Declara tres repositorios de hooks:

- `astral-sh/ruff-pre-commit` (`v0.17.5`) con `ruff` y `ruff-format`.
- `pre-commit/pre-commit-hooks` (`v6.0.0`) con `check-yaml`, `check-json`, `check-toml`, `end-of-file-fixer`, `trailing-whitespace`, `detect-private-key` y `check-added-large-files` (1 MB).
- Un hook local `pytest` que ejecuta `.venv/bin/python -m pytest`.

**Comando de instalación del hook**

```bash
pre-commit install
```

Resultado esperado: `pre-commit installed at .git/hooks/pre-commit`.

**Verificación**

```bash
# El hook está instalado y es ejecutable
ls -l .git/hooks/pre-commit

# Ejecutar todos los hooks sobre los archivos del proyecto
pre-commit run --files \
  $(find src tests -type f -name '*.py') \
  pyproject.toml .pre-commit-config.yaml .github/workflows/tests.yml \
  Makefile README.md requirements.txt requirements-dev.txt \
  docs/PROJECT_CONTEXT.md docs/PROJECT_STATUS.md docs/DECISIONS.md docs/HANDOFF.md \
  .gitignore

# Test automático que valida los hooks requeridos
python -m pytest tests/unit/test_infrastructure.py::test_pre_commit_configuration_includes_quality_gates -q
```

Resultado esperado: todos los hooks `Passed` y exit code 0.

Nota: `pre-commit run --all-files` solo considera archivos ya trackeados por Git. Mientras no exista commit, hay que usar `--files` con las rutas explícitas.

---

## 3. CI en GitHub Actions

**Qué hace y objetivo:** reproducir en un runner limpio las mismas comprobaciones que se ejecutan en local, para demostrar que el resultado no depende de la máquina de desarrollo.

**Archivo creado**

- `.github/workflows/tests.yml`

Se activa en `push` y `pull_request`. Usa Python 3.14, caché de `pip`, instala `requirements-dev.txt` y el paquete en modo editable, y ejecuta `ruff check src tests`, `ruff format --check src tests` y `python -m pytest`.

**Verificación del contenido**

```bash
# El YAML es válido y se puede parsear
python -c "import yaml; yaml.safe_load(open('.github/workflows/tests.yml')); print('yaml ok')"

# Los tres comandos de calidad están presentes
grep -E 'ruff check|ruff format --check|pytest' .github/workflows/tests.yml

# Test automático que valida los comandos del workflow
python -m pytest tests/unit/test_infrastructure.py::test_ci_workflow_runs_quality_gates -q
```

**Verificación de la reproducibilidad en entorno limpio**

Simula el job de CI sin depender del `.venv` local:

```bash
rm -rf /tmp/opencode/aigate-ci-venv
python3 -m venv /tmp/opencode/aigate-ci-venv
/tmp/opencode/aigate-ci-venv/bin/python -m pip install --quiet --upgrade pip
/tmp/opencode/aigate-ci-venv/bin/python -m pip install --quiet -r requirements-dev.txt
/tmp/opencode/aigate-ci-venv/bin/python -m pip install --quiet -e .
/tmp/opencode/aigate-ci-venv/bin/python -m pip check
/tmp/opencode/aigate-ci-venv/bin/python -m pytest
/tmp/opencode/aigate-ci-venv/bin/python -m ruff check src tests
/tmp/opencode/aigate-ci-venv/bin/python -m ruff format --check src tests
rm -rf /tmp/opencode/aigate-ci-venv
```

Resultado esperado: `No broken requirements found.`, `10 passed`, `All checks passed!`, `9 files already formatted`.

La ejecución en GitHub solo puede comprobarse tras el `push` de la rama.

---

## 4. Tests de infraestructura

**Qué hace y objetivo:** sustituir el resultado vacío de pytest (`0 tests`, exit code 5) por comprobaciones reales del contrato del repositorio. No prueban el producto, sino que la configuración, la estructura y los controles declarados existen y son coherentes.

**Archivos creados**

- `tests/unit/test_infrastructure.py`
- `tests/unit/__init__.py`

Los 10 tests validan: versión de Python, dependencias estáticas en `pyproject.toml`, separación runtime/dev, directorios esperados, importación de subpaquetes, patrones de `.gitignore`, objetivos del `Makefile`, hooks de pre-commit, comandos de CI y Zeek operativo (con `skip` si no está instalado).

**Verificación**

```bash
# Ejecución completa
python -m pytest

# Recuento sin ejecutar
python -m pytest --collect-only -q

# Solo los tests de infraestructura
python -m pytest tests/unit/test_infrastructure.py -v
```

Resultado esperado: `10 passed`, exit code 0.

---

## 5. Proyecto instalado como paquete y setuptools disponible

**Qué hace y objetivo:** permitir `import aigate` desde cualquier directorio del entorno, sin depender de `pythonpath`, y dejar el backend de build (`setuptools`) disponible en `.venv`.

**Archivos implicados**

- `pyproject.toml` — declara `[build-system]` con `setuptools>=75`, `build-backend = "setuptools.build_meta"`, metadatos estáticos y `[tool.setuptools.packages.find]` con `where = ["src"]` e `include = ["aigate*"]`.
- `requirements-dev.txt` — fija `setuptools==84.2.1`.

**Comandos de resolución**

```bash
# Instalar setuptools y el resto de herramientas de desarrollo
python -m pip install -r requirements-dev.txt

# Instalar el proyecto en modo editable
python -m pip install -e .
```

También disponible como objetivo de `make`:

```bash
make install       # python -m pip install -e .
make install-dev   # requirements-dev.txt + instalación editable
```

**Verificación**

```bash
python -c "import setuptools; print(setuptools.__version__)"   # 84.2.1
python -m pip show aigate | grep -E 'Name|Version|Editable'
python -c "import aigate; print(aigate.__version__, aigate.__file__)"
python -m pip check
```

Resultado esperado: `aigate 0.1.0`, editable en `src/aigate`, `No broken requirements found.`

---

## 6. Separación de dependencias de ejecución y desarrollo

**Qué hace y objetivo:** evitar que una instalación del producto arrastre pytest, Ruff o pre-commit, y eliminar la carga dinámica de dependencias desde `requirements.txt`. El runtime queda en un archivo y las herramientas de desarrollo en otro.

**Archivos creados/modificados**

- `requirements.txt` — solo runtime y dependencias transitivas, con versiones fijas (`pandas`, `numpy`, `scikit-learn`, `joblib`, `PyYAML`, `streamlit` y su cierre).
- `requirements-dev.txt` — incluye `-r requirements.txt` y añade pytest, Ruff, pre-commit, setuptools y sus dependencias.
- `pyproject.toml` — dependencias estáticas en `[project].dependencies` (sin `dynamic`) y herramientas de desarrollo en `[project.optional-dependencies].dev`.

**Verificación del contenido**

```bash
# Las herramientas de desarrollo no aparecen en runtime
grep -Ei 'pytest|ruff|pre-commit' requirements.txt && echo "ERROR: herramienta de dev en runtime" || echo "runtime limpio"

# requirements-dev.txt referencia al runtime
grep -E '^-r requirements\.txt$' requirements-dev.txt

# pyproject.toml no usa dependencias dinámicas
grep -E '^dynamic|tool\.setuptools\.dynamic' pyproject.toml && echo "ERROR: dependencias dinámicas" || echo "dependencias estáticas"

# Tests automáticos de ambos contratos
python -m pytest \
  tests/unit/test_infrastructure.py::test_pyproject_declares_static_project_metadata \
  tests/unit/test_infrastructure.py::test_runtime_and_development_requirements_are_separated -q
```

Resultado esperado: `runtime limpio`, coincidencia con `-r requirements.txt`, `dependencias estáticas`, `2 passed`.

**Verificación de instalación**

```bash
python -m pip install -r requirements.txt
python -m pip check
```

---

## 7. Subpaquetes importables de `src/aigate/`

**Qué hace y objetivo:** convertir los directorios vacíos en paquetes Python reales para que Git los versione y para que `import aigate.capture`, `aigate.features`, `aigate.models`, `aigate.policy` y `aigate.enforcement` funcione. No añaden lógica: solo declaran la frontera del paquete.

**Archivos creados**

- `src/aigate/__init__.py` — docstring y `__version__ = "0.1.0"`.
- `src/aigate/capture/__init__.py`
- `src/aigate/features/__init__.py`
- `src/aigate/models/__init__.py`
- `src/aigate/policy/__init__.py`
- `src/aigate/enforcement/__init__.py`

**Verificación**

```bash
# Todos los paquetes existen
find src/aigate -name '__init__.py' | sort

# Importación real de los cinco subpaquetes
python -c "import aigate; from aigate import capture, enforcement, features, models, policy; print(aigate.__version__); print([m.__name__ for m in (capture, features, models, policy, enforcement)])"

# Test automático de importación
python -m pytest tests/unit/test_infrastructure.py::test_source_subpackages_are_importable -q
```

Resultado esperado: `0.1.0` y `['aigate.capture', 'aigate.features', 'aigate.models', 'aigate.policy', 'aigate.enforcement']`.

---

## 8. Directorios `data/interim/` y `data/manifests/`

**Qué hace y objetivo:** reservar las ubicaciones de datos intermedios y de manifiestos de procedencia antes de la Entrega 3, manteniéndolas versionadas mediante `.gitkeep` y protegidas por `.gitignore` para que su contenido real nunca entre en Git.

**Archivos creados/modificados**

- `data/interim/.gitkeep`
- `data/manifests/.gitkeep`
- `.gitignore` — añade `data/interim/*`, `!data/interim/.gitkeep`, `data/manifests/*`, `!data/manifests/.gitkeep`.

**Verificación**

```bash
# Los directorios y marcadores existen
find data -maxdepth 2 -name '.gitkeep' | sort

# El contenido real queda ignorado y el marcador no
git check-ignore -q data/interim/ejemplo.csv && echo "interim ignorado (correcto)"
git check-ignore -q data/manifests/ejemplo.json && echo "manifests ignorado (correcto)"
git check-ignore -q data/interim/.gitkeep || echo "marcador interim no ignorado (correcto)"
git check-ignore -q data/manifests/.gitkeep || echo "marcador manifests no ignorado (correcto)"

# Traza de la regla aplicada (informativo; con -v el código de salida no distingue negación)
git check-ignore --no-index -v data/interim/ejemplo.csv

# Test automático de directorios y patrones de .gitignore
python -m pytest \
  tests/unit/test_infrastructure.py::test_expected_directories_exist \
  tests/unit/test_infrastructure.py::test_gitignore_protects_sensitive_artifacts -q
```

Resultado esperado: los `.gitkeep` aparecen; los archivos de ejemplo están ignorados; los marcadores no lo están; `2 passed`.

Nota: mientras no exista el commit, `git status` mostrará `.gitkeep` como archivo no trackeado. Es el comportamiento esperado: el versionado real ocurre al hacer `git add`, que corresponde al usuario.

---

## Comprobación final conjunta

```bash
cd /home/kali/Opencode/repos/aigate
source .venv/bin/activate

python -m pip check
python -c "import setuptools, aigate; print(setuptools.__version__, aigate.__version__)"
make check
pre-commit run --files \
  $(find src tests -type f -name '*.py') \
  pyproject.toml .pre-commit-config.yaml .github/workflows/tests.yml \
  Makefile README.md requirements.txt requirements-dev.txt \
  docs/PROJECT_CONTEXT.md docs/PROJECT_STATUS.md docs/DECISIONS.md docs/HANDOFF.md docs/e2-env.md \
  .gitignore
```

Salida esperada:

- `No broken requirements found.`
- `84.2.1 0.1.0`
- `All checks passed!`
- `9 files already formatted`
- `10 passed`
- Todos los hooks de pre-commit en `Passed`

## Lo que queda fuera de este documento

- **Punto 9 — commit:** lo ejecuta el usuario. El hook de pre-commit se disparará automáticamente en ese momento.
- **Ejecución remota de la CI:** requiere `push` de la rama.
- **Entrega 3:** no iniciada.
