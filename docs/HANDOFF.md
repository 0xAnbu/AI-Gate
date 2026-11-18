# HANDOFF — AIGate

> Punto exacto de reanudación. Este documento debe bastar para continuar sin depender del historial de la conversación.
>
> Última actualización: 2026-11-18

---

## ENTREGA ACTUAL

**Entrega 3 — Dataset y exploración de datos.**

Sub-entrega **3.1 (investigación y diseño): aprobada.**
Sub-entrega **3.2 (laboratorio y piloto): en curso.**

Rama de trabajo: `entrega-3-recogida-de-datos`.
Commit base: `3ae9f4f Merge PR: entrega-2-entorno-y-estructura`.
Estado del árbol: cambios de 3.1/3.2 sin commitear.

## ESTADO

**Infraestructura lista, datos no.**

Existe:

- Diseño experimental aprobado en `docs/DATA_CAPTURE.md`.
- Decisiones D-013…D-020 en `docs/DECISIONS.md`.
- Tres clientes instalados: Codex `0.170.0`, Claude Code `2.1.327`, OpenCode `2.1.4`.
- `scripts/lab_session.sh` con `up`, `down`, `status`, `exec`, `DRY_RUN` y rollback.
- `scripts/capture_session.sh` con tcpdump, límites, hashes, `capture.meta.json` y manifiesto.
- `fixtures/prompts/{f1,f2,f3}.txt`, `fixtures/workspace/` y `fixtures/fixture_server.py`.
- Esquema de manifiesto v1 y validador con 12 tests; 3 tests del servidor local.
- Piloto de conectividad: 32 paquetes, `401` de DeepSeek, limpieza verificada.

No existe:

- Ninguna captura de sesión experimental (solo el PCAP de humo en `/tmp`).
- Ningún manifiesto rellenado.
- Ningún log Zeek de sesión real.
- Ningún control negativo ejecutado.
- Ningún dataset externo descargado.
- `DATASET_CARD.md`.

## HECHO

### 3.1 — Diseño

1. Comparativa de Codex CLI, Claude Code y OpenCode/DeepSeek con fuentes oficiales.
2. Análisis económico, de autenticación, credenciales y 12 puntos de fuga.
3. Arquitectura netns + veth + tcpdump + Zeek + nftables, con limpieza y rollback.
4. 27 sesiones positivas (3×3×3), 7 controles negativos.
5. Etiquetado de sesión y procedencia de flujo, sin atribución por paquete.
6. Esquema de manifiesto v1 y evaluación de datasets externos.
7. Viabilidad temporal y plan de repliegue.
8. `docs/DATA_CAPTURE.md`, actualización de documentación persistente.
9. Registro de D-013…D-020.

### 3.2 — Laboratorio

1. Instalación y verificación de los tres clientes.
2. Implementación de `scripts/lab_session.sh`.
3. Implementación de `src/aigate/capture/manifest.py` y `manifest-v1.schema.json`.
4. Implementación de `scripts/capture_session.sh` y `_write_capture_manifest.py`.
5. Fixtures: prompts F1–F3, workspace inicial y servidor local con tests.
6. 12 tests de manifiesto + 3 tests del fixture (25 en total).
7. Piloto de conectividad ejecutado por el usuario y verificado.

## ARCHIVOS CREADOS

- `docs/DATA_CAPTURE.md`
- `scripts/lab_session.sh`
- `scripts/capture_session.sh`
- `scripts/_write_capture_manifest.py`
- `src/aigate/capture/manifest.py`
- `src/aigate/capture/manifest-v1.schema.json`
- `tests/unit/test_manifest.py`
- `tests/unit/test_fixture_server.py`
- `fixtures/prompts/f1.txt`, `f2.txt`, `f3.txt`
- `fixtures/workspace/` (`input.txt`, `buggy_stats.py`, `test_buggy_stats.py`, `README.md`)
- `fixtures/fixture_server.py`
- `data/work/.gitkeep`

## ARCHIVOS MODIFICADOS

- `docs/DECISIONS.md` — D-013…D-020 y resumen.
- `docs/PROJECT_CONTEXT.md` — estado, estructura, decisiones y entorno.
- `docs/PROJECT_STATUS.md` — componentes, validaciones y pendientes.
- `docs/HANDOFF.md` — este documento.
- `docs/CONFIG.md` — puntero a la Entrega 3.
- `README.md` — estado de la Entrega 3 y documento de captura.
- `pyproject.toml` — `package-data` para el esquema JSON.
- `Makefile` y `.github/workflows/tests.yml` — lint/format también sobre `scripts` y `fixtures`.
- `.gitignore` — `data/work/` ignorado salvo `.gitkeep`.

**No modificados:** `docs/DATASET_CARD.md` no existe; `src/` solo cambia en `capture/`; `data/` sigue sin datos.

## COMPROBACIONES EJECUTADAS

```bash
cd /home/kali/Opencode/repos/aigate
source .venv/bin/activate
make check
bash -n scripts/lab_session.sh
bash -n scripts/capture_session.sh
DRY_RUN=1 ./scripts/lab_session.sh up s01 1
DRY_RUN=1 ./scripts/capture_session.sh --lab-id s01 --agent openai \
    --family F2 --repetition 1 --prompt fixtures/prompts/f2.txt -- echo hello
codex --version
claude --version
opencode --version
```

| Comprobación | Resultado |
|---|---|
| `make check` | Ruff correcto, `25 passed` |
| Sintaxis de los scripts | Correcta |
| `DRY_RUN` | Previsualiza sin crear estado |
| Codex | `0.170.0`, `gpt-6.2-sol` |
| Claude Code | `2.1.327`, `Claude Opus 5.5` |
| OpenCode | `2.1.4` |
| `ip_forward` tras el piloto | `0` |
| Namespace / veth / tabla tras el piloto | Eliminados |

## BLOQUEOS

| # | Bloqueo | Necesita |
|---|---|---|
| B-01 | El piloto real de 3 sesiones no se ha ejecutado. | Ejecución manual con `sudo`, autenticación de clientes y captura. |
| B-02 | ISCXVPN2016 exige un formulario con datos personales. | El usuario lo completa; el proyecto no lo automatiza. |
| B-03 | No hay commit de 3.1/3.2. | Commit manual del usuario tras revisar `make check`. |

Los bloqueos económicos anteriores están resueltos: el usuario confirmó el uso sin límites de los tres clientes.

## DECISIONES ACEPTADAS

| ID | Decisión |
|---|---|
| D-013 | Codex CLI, Claude Code y OpenCode/DeepSeek; uso confirmado. |
| D-014 | Un netns + veth por sesión; captura en el extremo host. |
| D-015 | DNS público por namespace; IPv6 desactivado dentro del ns. |
| D-016 | 27 sesiones + 7 controles; etiqueta `CLIENT_RUNTIME_IDLE`. |
| D-017 | Etiquetado de sesión y flujo; MCP del agente = `AGENT_TOOL_MCP`. |
| D-018 | Manifiesto YAML v1 validado con JSON Schema y `jsonschema`. |
| D-019 | ISCXVPN2016 Non-VPN como dataset externo de referencia. |
| D-020 | PCAP privado; solo agregados y manifiestos saneados. |

## SIGUIENTE PASO

1. Revisar y commitear los cambios de 3.1/3.2 (usuario).
2. Autenticar los clientes fuera de la captura.
3. Crear el laboratorio con `sudo ./scripts/lab_session.sh up s01 1`.
4. Ejecutar 3 sesiones de piloto (una por agente, familia F2) con `capture_session.sh`.
5. Revisar los manifiestos y los hosts observados; congelar `labelling_rules_version = 1`.
6. Solicitar ISCXVPN2016 Non-VPN y preparar la muestra acotada.
7. Actualizar `DATA_CAPTURE.md` con los hallazgos del piloto.

## PRIMERA ACCIÓN RECOMENDADA

```bash
cd /home/kali/Opencode/repos/aigate
git status --short --branch
source .venv/bin/activate
make check
DRY_RUN=1 ./scripts/lab_session.sh up s01 1
DRY_RUN=1 ./scripts/capture_session.sh --lab-id s01 --agent openai \
    --family F2 --repetition 1 --prompt fixtures/prompts/f2.txt -- echo hello
```

Después, revisar `docs/DATA_CAPTURE.md` §15 y ejecutar el piloto con `sudo`.

---

## Recuperación del entorno

### 1. Repositorio y rama

```bash
cd /home/kali/Opencode/repos/aigate
git switch entrega-3-recogida-de-datos
git status --short --branch
git log --oneline -3
```

Base esperada: `3ae9f4f`.

### 2. Entorno virtual

```bash
source .venv/bin/activate
python --version          # 3.14.8
python -m pip check       # No broken requirements found.
```

### 3. Calidad

```bash
make check                # Ruff + formato + 25 tests
```

### 4. Clientes

```bash
codex --version           # 0.170.0
claude --version          # 2.1.327
opencode --version        # 2.1.4
```

### 5. Laboratorio limpio

```bash
ip netns list
sysctl net.ipv4.ip_forward
ip -br link | grep veth || echo "sin veth"
sudo nft list tables
pgrep -af 'codex|claude|opencode' || echo "sin clientes en ejecución"
```

Esperado: sin netns, `0`, sin veth, sin tabla `aigate_lab`, sin procesos.

### 6. Script de laboratorio

```bash
./scripts/lab_session.sh --help
DRY_RUN=1 ./scripts/lab_session.sh up s01 1
sudo ./scripts/lab_session.sh up s01 1
sudo ./scripts/lab_session.sh status s01
sudo ./scripts/lab_session.sh down s01
```

`down` se niega a borrar un namespace con procesos vivos; usar `--force` solo si se ha comprobado que son los del experimento.

---

## Reglas para no romper el estado

- No leer ni copiar ficheros de credenciales.
- No publicar PCAP, logs crudos ni datos personales.
- No dejar `ip_forward=1` ni la tabla `inet aigate_lab`.
- No reducir las 27 sesiones sin aprobación y sin registrarlo.
- No crear `DATASET_CARD.md` antes de tener datos reales.
- No registrar en `DECISIONS.md` nada que no esté aprobado.
- No mezclar `data/external/` con `data/raw/`.
