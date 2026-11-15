# PROJECT STATUS — AIGate

> Estado real del repositorio, no el estado deseado.
>
> Última actualización: 2026-11-15
> Rama de trabajo: `entrega-2-entorno-y-estructura`
> Último commit: `6da72e5 Initial commit`
> Commits nuevos: **ninguno** (el commit corresponde al usuario)

---

## 1. Estado de las entregas

| Entrega | Estado | Observaciones |
|---|---|---|
| 1 — Diseño y planificación | Completada | No hay artefactos de planificación en `docs/`; el contexto disponible es `context/MASTER-PROMPT.md`. |
| 2 — Entorno y estructura | **Completada técnicamente** | Entorno, dependencias separadas, paquete editable, estructura, Makefile, pre-commit, CI, tests de infraestructura y documentación. |
| 3 — Dataset y exploración | Pendiente | No iniciada. Requiere aprobación explícita. |
| 4 — Feature engineering | Pendiente | No iniciada. |
| 5 — Entrenamiento y evaluación | Pendiente | No iniciada. |
| 6 — Motor de detección y decisiones | Pendiente | No iniciada. |
| 7 — Firewall y filtrado | Pendiente | No iniciada. |
| 8 — Dashboard y monitorización | Pendiente | No iniciada. |
| 9 — Testing y demostración | Pendiente | No iniciada. |
| 10 — Documentación y presentación | Pendiente | No iniciada. |

## 2. Estado por componente

| Componente | Estado | Evidencia / límite |
|---|---|---|
| Kali Linux Rolling | Comprobado | 2026.3, kernel 7.1.5+kali-amd64. |
| Python del sistema | Comprobado | 3.14.8. |
| Entorno virtual `.venv` | Completado | `.venv/pyvenv.cfg`: Python 3.14.8, `include-system-site-packages = false`. |
| Dependencias de ejecución | Completado | `requirements.txt` contiene solo runtime y transitivas; `pip check` sin conflictos. |
| Dependencias de desarrollo | Completado | `requirements-dev.txt` incluye `-r requirements.txt` y pytest, Ruff, pre-commit, setuptools. |
| `pyproject.toml` | Completado | Dependencias estáticas, `[project.optional-dependencies].dev`, `packages.find`, pytest y Ruff. |
| Paquete `aigate` | Completado | Instalado en modo editable: versión 0.1.0, origen `src/aigate`. |
| `setuptools` | Completado | 84.2.1 en `.venv`; satisface `setuptools>=75`. |
| Estructura de directorios | Completado | Incluye `data/interim` y `data/manifests`. |
| `config/` | Pendiente | Directorio vacío; no hay `gateway.yaml` ni `policies.yaml`. |
| `data/raw/` | Preparado, sin datos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `data/processed/` | Preparado, sin datos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `data/external/` | Preparado, sin datos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `data/interim/` | Preparado, sin datos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `data/manifests/` | Preparado, sin datos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `models/` (raíz) | Preparado, sin artefactos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `scripts/` | Pendiente | Directorio vacío. |
| `src/aigate/__init__.py` | Completado | Define `__version__ = "0.1.0"`. |
| `src/aigate/capture/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/features/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/models/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/policy/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/enforcement/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `tests/` | Completado para infraestructura | 10 tests en `tests/unit/test_infrastructure.py`. |
| Ruff | Operativo | `ruff check` y `ruff format --check` pasan sobre 9 archivos. |
| pytest | Operativo | `10 passed`, exit code 0. |
| pre-commit | Configurado y funcionando | `.pre-commit-config.yaml`; hook instalado en `.git/hooks/pre-commit`; ejecución manual correcta. |
| Makefile | Operativo | Objetivos `install`, `install-dev`, `lint`, `format`, `format-check`, `test`, `check`, `pre-commit-install`, `pre-commit`, `clean`. |
| GitHub Actions | Configurada | `.github/workflows/tests.yml`; no ejecutada en GitHub porque no hay push. |
| Zeek | Operativo | `zeek version 9.0.1`; paquete `zeek 9.0.1-0` desde el repositorio oficial. |
| tcpdump | Operativo | 4.99.6. |
| tshark/Wireshark | Operativo | 4.6.6. |
| nftables | Operativo | 1.1.7. |
| iproute2 | Operativo | 7.2.0. |
| Git | Operativo | 2.53.0; rama de entrega creada; sin commits nuevos. |
| Documentación persistente | Completado | `PROJECT_CONTEXT.md`, `PROJECT_STATUS.md`, `DECISIONS.md`, `HANDOFF.md` y `README.md`. |
| Pipeline de captura | No iniciado | No hay código. |
| Dataset | No iniciado | No hay capturas ni manifiestos. |
| Modelo ML | No iniciado | No hay entrenamiento ni artefacto. |
| Motor de políticas | No iniciado | No hay configuración ni código. |
| Enforcement nftables | No iniciado | No hay código ni laboratorio. |
| Dashboard | No iniciado | No hay aplicación Streamlit. |

## 3. Validaciones ejecutadas

Todas las comprobaciones se ejecutaron el 2026-11-15 en `/home/kali/Opencode/repos/aigate`, con `.venv` activado.

| Comando | Resultado real | Código |
|---|---|---|
| `python --version` | `Python 3.14.8` | 0 |
| `python -m pip check` | `No broken requirements found.` | 0 |
| `python -m pip show aigate` | `aigate 0.1.0`, editable en `src/aigate` | 0 |
| `python -c "import setuptools"` | `84.2.1` | 0 |
| `python -c "import aigate, aigate.capture, ..."` | Importación correcta de los cinco subpaquetes | 0 |
| `make check` | Ruff correcto, 9 archivos formateados, `10 passed` | 0 |
| Instalación limpia en `/tmp` + `pip check` + pytest + Ruff | Reproducible: `No broken requirements found`, `10 passed`, `All checks passed!` | 0 |
| `ruff check src tests` | `All checks passed!` | 0 |
| `ruff format --check src tests` | `9 files already formatted` | 0 |
| `python -m pytest` | `10 passed` | 0 |
| `pre-commit run --files ...` | Todos los hooks pasan (ruff, ruff-format, YAML/TOML, secretos, tamaño, pytest) | 0 |
| `pre-commit install` | Hook instalado en `.git/hooks/pre-commit` | 0 |
| `zeek --version` | `zeek version 9.0.1` | 0 |
| `tcpdump --version` | `tcpdump version 4.99.6`, libpcap 1.11.0 | 0 |
| `tshark --version` | `TShark (Wireshark) 4.6.6` | 0 |
| `nft --version` | `nftables v1.1.7` | 0 |
| `ip -V` | `iproute2-7.2.0` | 0 |
| `git --version` | `git version 2.53.0` | 0 |
| `uname -r` | `7.1.5+kali-amd64` | 0 |
| `dpkg-query -W zeek` | `zeek 9.0.1-0 install ok installed` | 0 |
| `apt-cache policy zeek` | Instalado/candidato `9.0.1-0` desde `security:/zeek/Debian_Testing`; Kali ofrece `5.1.1-0kali3` | 0 |

Comprobaciones de Git:

- `git branch --show-current` → `entrega-2-entorno-y-estructura`.
- `git status --short` muestra `.gitignore` y `README.md` modificados, y los archivos nuevos sin trackear.
- `git ls-files` sigue conteniendo solo `.gitignore`, `LICENSE` y `README.md` del commit inicial.

## 4. Pendientes y problemas conocidos

| # | Pendiente | Impacto | Propuesta |
|---|---|---|---|
| 3 | `config/` y `scripts/` están vacíos. | No hay configuración ni automatización de laboratorio. | Se completarán cuando exista contenido real en las entregas correspondientes. |
| 4 | No hay datos, manifiestos ni capturas. | El dataset no ha comenzado. | Entrega 3. |
| 5 | Los módulos de `src/aigate/` no tienen implementación. | Solo son paquetes importables con docstring. | Implementar en las entregas 3–8. |
| 6 | `data/interim/` y `data/manifests/` están preparados pero vacíos. | No hay datos que procesar todavía. | Usarlos en la Entrega 3. |

No quedan problemas de configuración de la Entrega 2: Makefile, pre-commit, CI, tests, empaquetado y separación de dependencias están resueltos y validados.

## 5. Criterios DONE de la Entrega 2

| Criterio | Estado |
|---|---|
| Entorno instalado | Cumplido |
| Repositorio organizado | Cumplido |
| Dependencias funcionales | Cumplido (`pip check`) |
| Zeek operativo | Cumplido |
| Makefile operativo | Cumplido |
| Ruff operativo | Cumplido |
| Pytest operativo | Cumplido (10 tests, exit 0) |
| Pre-commit funcionando | Cumplido |
| CI configurada | Cumplido |
| Documentación inicial creada | Cumplido |
| Primeros tests de infraestructura | Cumplido |
| Commit de la entrega | Cumplido, reservado al usuario |

## 6. Conclusión de estado

La Entrega 2 está **completada técnicamente**. Todos los entregables verificables están implementados y validados localmente. El commit está completado pero corresponde al usuario por indicación expresa.

No se ha implementado ninguna funcionalidad de la Entrega 3. No se han modificado las dependencias de ejecución ni las versiones del stack; solo se ha separado runtime y desarrollo y se ha añadido `setuptools` como herramienta de build.
