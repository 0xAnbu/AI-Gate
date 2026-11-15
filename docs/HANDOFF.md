# HANDOFF — AIGate

> Punto exacto de reanudación. Este documento debe bastar para continuar sin depender del historial de la conversación.
>
> Última actualización: 2026-11-15

---

## ENTREGA ACTUAL

**Entrega 2 — Preparación del entorno y estructura del proyecto.**

Rama de trabajo: `entrega-2-entorno-y-estructura`.
Commit base: `6da72e5 Initial commit`.

## ESTADO

**Completada técnicamente.** El entorno, las dependencias, el paquete editable, la estructura, el Makefile, pre-commit, la CI, los tests de infraestructura y la documentación están preparados y validados localmente.

Queda un único paso: el commit humano. La CI está configurada pero no se ha ejecutado en GitHub porque no hay push.

No hay pipeline, dataset, modelo, motor de políticas, enforcement ni dashboard implementados.

## FUNCIONALIDADES COMPLETADAS

- Entorno virtual `.venv` con Python 3.14.8 aislado del Python del sistema.
- Dependencias de ejecución y desarrollo separadas.
- `setuptools 84.2.1` instalado en `.venv`.
- Paquete `aigate 0.1.0` instalado en modo editable.
- `pyproject.toml` con dependencias estáticas, extras de desarrollo, `packages.find`, pytest y Ruff.
- Estructura de directorios completa, incluidos `data/interim/` y `data/manifests/`.
- Subpaquetes `capture`, `features`, `models`, `policy` y `enforcement` importables mediante `__init__.py` con docstring.
- `Makefile` con objetivos `install`, `install-dev`, `lint`, `format`, `format-check`, `test`, `check`, `pre-commit-install`, `pre-commit` y `clean`.
- `.pre-commit-config.yaml` con Ruff, Ruff format, validación YAML/JSON/TOML, fin de archivo, espacios, detección de claves privadas, tamaño máximo y pytest.
- Hook de pre-commit instalado en `.git/hooks/pre-commit`.
- CI en `.github/workflows/tests.yml` para lint, formato y tests.
- 10 tests de infraestructura en `tests/unit/test_infrastructure.py`.
- Documentación persistente actualizada.
- Rama `entrega-2-entorno-y-estructura` creada.

## ARCHIVOS CREADOS

- `docs/PROJECT_CONTEXT.md`
- `docs/PROJECT_STATUS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF.md`
- `Makefile`
- `.pre-commit-config.yaml`
- `.github/workflows/tests.yml`
- `requirements-dev.txt`
- `src/aigate/capture/__init__.py`
- `src/aigate/features/__init__.py`
- `src/aigate/models/__init__.py`
- `src/aigate/policy/__init__.py`
- `src/aigate/enforcement/__init__.py`
- `tests/unit/__init__.py`
- `tests/unit/test_infrastructure.py`
- `data/interim/.gitkeep`
- `data/manifests/.gitkeep`

## ARCHIVOS MODIFICADOS

- `README.md` — estado, estructura, instalación, validaciones y uso de Makefile/pre-commit.
- `pyproject.toml` — dependencias estáticas, extras de desarrollo, `packages.find`, pytest y Ruff.
- `requirements.txt` — solo dependencias de ejecución y transitivas.
- `.gitignore` — añadidos `data/interim/*` y `data/manifests/*` con excepción `.gitkeep`.
- `src/aigate/__init__.py` — docstring y `__version__ = "0.1.0"`.
- `docs/PROJECT_CONTEXT.md`, `docs/PROJECT_STATUS.md`, `docs/DECISIONS.md` — actualizados al estado final.

No se ha modificado `tests/__init__.py` ni se han eliminado archivos existentes.

## TESTS EJECUTADOS

```bash
cd /home/kali/Opencode/repos/aigate
source .venv/bin/activate

python --version
python -m pip check
python -m pip show aigate
python -c "import setuptools, aigate; ..."
python -m pytest
ruff check src tests
ruff format --check src tests
make check
pre-commit run --files ...
pre-commit install
zeek --version
```

También se validaron `tcpdump`, `tshark`, `nft`, `ip`, `git` y el kernel, y se parsearon `.pre-commit-config.yaml` y `.github/workflows/tests.yml` con PyYAML.

## RESULTADOS

| Comprobación | Resultado |
|---|---|
| Python | 3.14.8 |
| `pip check` | `No broken requirements found.` |
| `pip show aigate` | `aigate 0.1.0`, editable en `src/aigate` |
| `setuptools` | 84.2.1 |
| Imports | `aigate` y los cinco subpaquetes importan |
| `pytest` | `10 passed`, exit code 0 |
| `ruff check src tests` | `All checks passed!` |
| `ruff format --check src tests` | `9 files already formatted` |
| `make check` | lint + formato + `10 passed`, exit code 0 |
| Simulación de CI en venv limpio | `pip check`, `10 passed`, Ruff correcto; entorno temporal eliminado |
| `pre-commit run --files ...` | Todos los hooks pasan |
| `pre-commit install` | Hook instalado en `.git/hooks/pre-commit` |
| Zeek | `zeek version 9.0.1` |
| tcpdump | 4.99.6 |
| tshark | 4.6.6 |
| nftables | 1.1.7 |
| iproute2 | 7.2.0 |
| Git | 2.53.0 |
| Kernel | 7.1.5+kali-amd64 |

## PROBLEMAS CONOCIDOS

3. **Sin funcionalidad de producto.** Los subpaquetes son importables, pero no implementan captura, features, modelo, política ni enforcement.
4. **`config/` y `scripts/` vacíos.** Se completarán en entregas posteriores.
5. **Sin datos, manifiestos, modelo ni dashboard.** La Entrega 3 aún no ha comenzado.
6. **`data/interim/` y `data/manifests/` preparados pero vacíos.** Correcto para esta fase.

No quedan bloqueos de configuración de la Entrega 2.

## DECISIONES PENDIENTES

- Definir el esquema de manifiestos en la Entrega 3.
- Valorar patrones adicionales para `*.joblib`, `*.pkl`, `reports/` y `artifacts/` cuando existan.
- Valorar hashes de integridad si el proyecto crece.
- Implementar el producto en las siguientes entregas.

## SIGUIENTE ENTREGA

**Entrega 3 — Dataset y exploración de datos**, solo después de que el usuario apruebe el cierre de la Entrega 2.

Incluirá:

- Selección de clientes de OpenAI, Claude Code y DeepSeek.
- Verificación de documentación oficial, autenticación y costes.
- Network namespaces y veth para aislar cada agente.
- Captura por agente con tcpdump/Zeek.
- Escenarios comparables y controles negativos.
- Manifiestos y etiquetado reproducible.
- Organización del dataset y exploración estadística.
- Análisis de calidad, contaminaciones y limitaciones.
- Dataset Card.

## PRIMERA ACCIÓN RECOMENDADA

1. Revisar `git status --short` y `git diff`.
2. Ejecutar `make check` y confirmar `10 passed`.
3. Añadir los archivos al índice y ejecutar `pre-commit run --all-files`; el hook también se ejecutará en el commit.
6. Solicitar aprobación para comenzar la Entrega 3.

---

## Recuperación del entorno

### 1. Entrar en el repositorio y en la rama

```bash
cd /home/kali/Opencode/repos/aigate
git switch entrega-2-entorno-y-estructura
git branch --show-current
```

Resultado esperado: `entrega-2-entorno-y-estructura`.

### 2. Activar el entorno virtual existente

```bash
source .venv/bin/activate
python --version
```

Resultado esperado: `Python 3.14.8`.

### 3. Comprobar dependencias, paquete y herramientas

```bash
python -m pip check
python -m pip show aigate
python -c "import setuptools, aigate; print(setuptools.__version__, aigate.__version__)"
ruff --version
pytest --version
pre-commit --version
zeek --version
```

Resultados esperados:

- `No broken requirements found.`
- `aigate 0.1.0` editable.
- `84.2.1 0.1.0`.
- Ruff 0.17.5.
- pytest 9.2.0.
- pre-commit 4.7.0.
- Zeek 9.0.1.

### 4. Ejecutar las comprobaciones de calidad

```bash
make check
```

Resultado esperado: `All checks passed!`, `9 files already formatted`, `10 passed`.

### 5. Ejecutar pre-commit

```bash
pre-commit run --all-files
```

Nota: `--all-files` solo considera archivos trackeados por Git. Para comprobar archivos nuevos antes de añadirlos al índice, usar `pre-commit run --files <rutas>`.

### 6. Recrear el entorno si `.venv` no existe

Solo si es necesario y con acceso a red para instalar las dependencias fijadas:

```bash
cd /home/kali/Opencode/repos/aigate
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pip install -e .
python -m pip check
pre-commit install
make check
```

Notas:

- `requirements-dev.txt` incluye runtime, pytest, Ruff, pre-commit y setuptools.
- `pip install -e .` instala el paquete en modo editable.
- No se deben cambiar versiones ni añadir dependencias sin justificarlo y aprobarlo.

### 7. Comprobar Zeek

```bash
zeek --version
dpkg-query -W -f='${Package} ${Version} ${Status}\n' zeek
apt-cache policy zeek
```

Resultado esperado: `zeek 9.0.1-0 install ok installed`. `apt-cache policy` muestra el candidato `9.0.1-0` desde `security:/zeek/Debian_Testing` y el paquete de Kali `5.1.1-0kali3`. No reinstalar ni cambiar de repositorio sin revisar la compatibilidad con glibc.
