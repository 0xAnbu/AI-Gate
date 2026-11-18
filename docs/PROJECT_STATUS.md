# PROJECT STATUS — AIGate

> Estado real del repositorio, no el estado deseado.
>
> Última actualización: 2026-11-18
> Rama de trabajo: `entrega-3-recogida-de-datos`
> Último commit: `3ae9f4f Merge PR: entrega-2-entorno-y-estructura`
> Commits nuevos: **ninguno** (el commit corresponde al usuario)

---

## 1. Estado de las entregas

| Entrega | Estado | Observaciones |
|---|---|---|
| 1 — Diseño y planificación | Completada | No hay artefactos de planificación en `docs/`; el contexto disponible es `context/MASTER-PROMPT.md`. |
| 2 — Entorno y estructura | **Completada** | Entorno, dependencias separadas, paquete editable, estructura, Makefile, pre-commit, CI, tests de infraestructura y documentación. Integrada en `3ae9f4f`. |
| 3 — Dataset y exploración | **En curso** | 3.1 aprobada; 3.2 en curso. Clientes instalados, `lab_session.sh`, `capture_session.sh`, fixtures, esquema de manifiesto y 25 tests. Sin PCAP del dataset ni manifiestos rellenados. ISCXVPN2016 Non-VPN seleccionado, no descargado. |
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
| `data/work/` | Preparado, sin datos | Copia por sesión del workspace; ignorado por Git salvo el marcador. |
| `models/` (raíz) | Preparado, sin artefactos | Solo `.gitkeep`; ignorado por Git salvo el marcador. |
| `scripts/` | En curso | `lab_session.sh` y `capture_session.sh` implementados y validados en seco; captura real pendiente. |
| `fixtures/` | Implementado | Prompts F1–F3, workspace inicial y `fixture_server.py`; 3 tests del servidor. |
| `src/aigate/__init__.py` | Completado | Define `__version__ = "0.1.0"`. |
| `src/aigate/capture/` | Parcial | `manifest.py` y `manifest-v1.schema.json`; captura y Zeek pendientes. |
| `src/aigate/features/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/models/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/policy/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `src/aigate/enforcement/` | Paquete importable, sin implementación | `__init__.py` con docstring; no hay lógica. |
| `tests/` | 25 tests | 10 de infraestructura + 12 de manifiesto + 3 del fixture. |
| Ruff | Operativo | `ruff check` y `ruff format --check` pasan sobre 17 archivos (`src`, `tests`, `scripts`, `fixtures`). |
| pytest | Operativo | `25 passed`, exit code 0. |
| pre-commit | Configurado y funcionando | `.pre-commit-config.yaml`; hook instalado en `.git/hooks/pre-commit`; ejecución manual correcta. |
| Makefile | Operativo | Objetivos `install`, `install-dev`, `lint`, `format`, `format-check`, `test`, `check`, `pre-commit-install`, `pre-commit`, `clean`. |
| GitHub Actions | Configurada | `.github/workflows/tests.yml`; no ejecutada en GitHub porque no hay push. |
| Zeek | Operativo | `zeek version 9.0.1`; paquete `zeek 9.0.1-0` desde el repositorio oficial. |
| tcpdump | Operativo | 4.99.6. |
| tshark/Wireshark | Operativo | 4.6.6. |
| nftables | Operativo | 1.1.7. |
| iproute2 | Operativo | 7.2.0. |
| Git | Operativo | 2.53.0; rama de entrega creada; sin commits nuevos. |
| Documentación persistente | Completado | `PROJECT_CONTEXT.md`, `PROJECT_STATUS.md`, `DECISIONS.md`, `HANDOFF.md`, `DATA_CAPTURE.md` y `README.md`. |
| Diseño del dataset | Completado y aprobado | `docs/DATA_CAPTURE.md`: 27 sesiones positivas, 7 controles, etiqueta `CLIENT_RUNTIME_IDLE`. |
| Decisiones D-013…D-020 | Registradas | Clientes, aislamiento, DNS/IPv6, etiquetado, manifiesto, dataset externo y privacidad. |
| Clientes de agentes | Instalados | Codex `0.170.0`, Claude Code `2.1.327`, OpenCode `2.1.4`; modelos reportados registrados. |
| Laboratorio netns/veth | Implementado y probado | `scripts/lab_session.sh`; piloto con 32 paquetes y limpieza verificada. |
| Manifiesto de sesión | Implementado | `manifest.py`, `manifest-v1.schema.json` y 12 tests; sin manifiestos reales. |
| Pipeline de captura | Implementado, sin datos | `scripts/capture_session.sh` + `_write_capture_manifest.py`; validado en seco, captura real pendiente. |
| Fixtures de tarea | Implementados | Prompts F1–F3, workspace inicial y servidor local; 3 tests del servidor. |
| Dataset | No iniciado | Sin capturas propias ni manifiestos rellenados. |
| Dataset externo | Seleccionado, no descargado | ISCXVPN2016 Non-VPN; descarga mediante formulario que completa el usuario. |
| Controles negativos | Diseñados | 7 controles definidos; ninguno ejecutado. |
| Modelo ML | No iniciado | No hay entrenamiento ni artefacto. |
| Motor de políticas | No iniciado | No hay configuración ni código. |
| Enforcement nftables | No iniciado | No hay código ni laboratorio. |
| Dashboard | No iniciado | No hay aplicación Streamlit. |

## 3. Validaciones ejecutadas

Las comprobaciones de la Entrega 2 se ejecutaron el 2026-11-15 en `/home/kali/Opencode/repos/aigate`, con `.venv` activado. Las de la fase de diseño de la Entrega 3 se ejecutaron el 2026-11-18 sin privilegios y sin modificar el sistema.

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

Comprobaciones de Git (2026-11-18):

- `git branch --show-current` → `entrega-3-recogida-de-datos`.
- `git status --short --branch` → rama correcta, base `3ae9f4f`, cambios de 3.1/3.2 sin commit.
- `git log --oneline -3` → `3ae9f4f`, `d9e2270`, `05f4975`.
- `main` apunta al mismo commit `3ae9f4f`.

### 3.1. Comprobaciones de la fase de diseño y preparación (2026-11-18)

| Comprobación | Resultado real |
|---|---|
| `make check` | Ruff correcto, `25 passed`, exit 0 |
| `opencode --version` | `2.1.4` |
| `codex --version` | `0.170.0`, modelo `gpt-6.2-sol` |
| `claude --version` | `2.1.327`, modelo `Claude Opus 5.5` |
| `command -v node`, `npm` | No encontrados |
| `command -v bwrap socat jq unshare nsenter` | Presentes |
| `python -m pip show jsonschema` | `4.26.0`, ya fijado en `requirements.txt` |
| `net.ipv4.ip_forward` | `0` (restaurado tras el piloto) |
| `net.ipv6.conf.all.forwarding` | `0` |
| `ip netns list` | Vacío tras la limpieza |
| `bash -n scripts/lab_session.sh` | Sintaxis correcta |
| `bash -n scripts/capture_session.sh` | Sintaxis correcta |
| `DRY_RUN=1 scripts/lab_session.sh up s01 1` | Previsualización sin crear estado |
| `DRY_RUN=1 scripts/capture_session.sh ... -- echo hello` | Plan impreso sin crear ficheros |
| `_write_capture_manifest.py` con entorno simulado | Manifiesto y `capture.meta.json` válidos para el esquema |
| `tests/unit/test_fixture_server.py` | 3 tests del servidor local pasan |

Piloto de conectividad ejecutado por el usuario (contexto en `context/Entrega-3-contexto-temporal.txt`):

| Comprobación | Resultado real |
|---|---|
| Interfaz WAN | `eth0` |
| Namespace / veth | `aigate-s01` / `veth-h-s01` / `veth-n-s01` |
| DNS del ns | `nameserver 1.1.1.1` |
| IPv6 dentro del ns | `1` (desactivado) |
| `curl https://api.deepseek.com/` desde el ns | `401` |
| Captura en `veth-h-s01` | 32 paquetes, 0 descartados |
| Limpieza | `ip_forward=0`, sin tabla nftables, sin namespace |

## 4. Pendientes y problemas conocidos

| # | Pendiente | Impacto | Propuesta |
|---|---|---|---|
| 7 | Ejecutar el piloto real de 3 sesiones (una por agente, F2). | Sin él no se conocen los hosts reales ni la duración. | `scripts/lab_session.sh` + `scripts/capture_session.sh`; después congelar `labelling_rules_version = 1`. |
| 8 | Revisar las banderas de red de cada cliente en el piloto. | El sandbox del cliente puede bloquear el proveedor y dejar la sesión sin tráfico útil. | Medir en el piloto; registrar en `anomalies` y ajustar la configuración documentada. |
| 9 | Solicitar ISCXVPN2016 Non-VPN. | El dataset externo no está disponible. | El usuario completa el formulario oficial; después, muestra estratificada acotada. |
| 10 | `config/` sigue vacío. | No hay configuración del gateway. | Entrega 6. |
| 11 | `features/`, `models/`, `policy/` y `enforcement/` sin implementación. | Solo son paquetes importables. | Entregas 4–8. |
| 12 | No hay capturas propias ni manifiestos rellenados. | El dataset positivo no ha comenzado. | Sub-entrega 3.3. |
| 13 | Cambios de 3.1/3.2 sin commit. | El trabajo no está versionado. | Commit manual del usuario tras `make check`. |

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

### 5.1. Criterios de la sub-entrega 3.1

| Criterio | Estado |
|---|---|
| Comparativa de clientes con fuentes oficiales | Cumplido; versiones y modelos verificados |
| Análisis de autenticación, credenciales y fugas | Cumplido (12 puntos de fuga) |
| Arquitectura de aislamiento | Cumplido y validado con piloto |
| Diseño de captura y Zeek | Cumplido; captura de humo de 32 paquetes |
| Escenarios positivos | 3 familias × 3 agentes × 3 repeticiones = 27 |
| Controles negativos | 7, con etiqueta `CLIENT_RUNTIME_IDLE` para N-06 |
| Etiquetado sin atribución por paquete | Cumplido; `AGENT_TOOL_MCP` añadido |
| Esquema de manifiesto | Cumplido e implementado con JSON Schema |
| Dataset externo | ISCXVPN2016 Non-VPN seleccionado (D-019) |
| Viabilidad temporal y plan de repliegue | Cumplido |
| Decisiones aprobadas y registradas | D-013…D-020 |
| Sin `DATASET_CARD.md` sin datos reales | Cumplido |

## 6. Conclusión de estado

La Entrega 2 está **completada e integrada** en `3ae9f4f`.

La Entrega 3 tiene la **sub-entrega 3.1 aprobada** y la **3.2 en curso**. Están instalados los tres clientes, implementados el esquema de manifiesto, el script de laboratorio, el script de captura y los fixtures de tarea, y validada la topología con un piloto de conectividad. **No existe todavía ningún dato del dataset**: no hay capturas propias, ni manifiestos rellenados, ni logs Zeek de sesiones reales, ni Dataset Card.

El siguiente paso es el piloto real de tres sesiones con `capture_session.sh`. Ya no hay bloqueos económicos: el usuario confirmó el uso de los tres clientes. Queda la solicitud manual de ISCXVPN2016 y la ejecución de las capturas.
