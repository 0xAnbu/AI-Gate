# PROJECT CONTEXT — AIGate

**AI-Aware Network Security Gateway**

> Documento persistente de contexto. Debe permitir retomar el proyecto sin depender del historial de conversaciones.
>
> Última actualización: 2026-11-18
> Entrega en curso: 3 — Dataset y exploración de datos.
> Estado: 3.1 aprobada; 3.2 (laboratorio y piloto) en curso. Clientes instalados, esquema de manifiesto y script de laboratorio implementados; captura del dataset **no iniciada**.

---

## 1. Objetivo general

AIGate es una prueba de concepto de seguridad de red para Linux que integra análisis de tráfico, extracción de características, Machine Learning supervisado y un motor configurable de políticas para identificar y controlar tráfico asociado a aplicaciones y agentes de IA.

El objetivo no es detectar IA de forma infalible, sino construir un gateway experimental, reproducible y explicable que:

1. Observe tráfico de red y lo transforme en registros estructurados.
2. Diferencie evidencias deterministas (destino, DNS, SNI, puerto, reglas) de señales estadísticas.
3. Clasifique sesiones o ventanas temporales con un modelo supervisado.
4. Combine ambas fuentes en decisiones de política.
5. Aplique bloqueos únicamente cuando exista una regla explícita.
6. Permita explicar por qué una conexión fue permitida, alertada, bloqueada o enviada a revisión.

## 2. Problema y límite fundamental

El proyecto distingue cuatro conceptos que no deben confundirse:

| Concepto | Definición |
|---|---|
| `AI_SERVICE_TRAFFIC` | Tráfico dirigido a servicios de IA conocidos. |
| `AGENT_ASSOCIATED_TRAFFIC` | Tráfico observado durante la ejecución de un entorno con un agente de IA, incluyendo llamadas al modelo y acciones de sus herramientas. |
| `AUTOMATION_NON_AI` | Automatización convencional: Nmap, curl, Python Requests, Burp, Caido, sqlmap, scripts, tareas programadas. |
| `HUMAN_REFERENCE` | Tráfico de referencia producido en escenarios controlados de interacción humana. |
| `UNKNOWN` | Tráfico sin evidencia suficiente para clasificarlo. |

Un destino de IA no implica que la conexión haya sido iniciada por un agente. Un patrón rápido o repetitivo no implica IA. HTTPS oculta gran parte de la información de aplicación. Por tanto, AIGate presentará clasificación estadística y evidencia determinista por separado, documentará la incertidumbre y no prometerá atribución universal.

## 3. Arquitectura prevista

```text
AGENTE / HUMANO / AUTOMATIZACIÓN
              |
              v
       TRÁFICO DE RED
              |
              v
            PCAP
              |
              v
            ZEEK
              |
              v
     EXTRACCIÓN DE FEATURES
              |
              v
       RANDOM FOREST / LR
              |
              v
       MOTOR DE DETECCIÓN
              |
              v
        MOTOR DE POLÍTICAS
              |
              v
  ALLOW / ALERT / BLOCK / REVIEW
              |
              v
           NFTABLES
              |
              v
      FILTRADO EN LABORATORIO
              |
              v
         MONITORIZACIÓN
```

### 3.1. Responsabilidades

| Componente | Responsabilidad | Estado actual |
|---|---|---|
| `capture/` | Captura PCAP/PCAPNG, simulación desde PCAP y orquestación de Zeek. | `manifest.py` y `manifest-v1.schema.json` implementados y testeados; captura pendiente. |
| `features/` | Parseo de registros Zeek, agregación temporal y cálculo de variables. | Paquete importable con `__init__.py`; sin implementación. |
| `models/` | Entrenamiento, evaluación, carga y serialización de modelos. | Paquete importable con `__init__.py`; sin implementación. |
| `policy/` | Whitelist, blacklist, reglas deterministas, umbrales y decisiones explicables. | Paquete importable con `__init__.py`; sin implementación. |
| `enforcement/` | Traducción de decisiones a nftables y gestión de namespaces. | Paquete importable con `__init__.py`; sin implementación. |
| `config/` | Configuración YAML del gateway y de las políticas. | Directorio vacío. |
| `data/` | Capturas originales, datos derivados, datasets externos, datos intermedios, manifiestos y workspaces de sesión. | Directorios y `.gitkeep`; sin datos. Esquema de manifiesto v1 implementado en `capture/`. |
| `models/` (raíz) | Artefactos serializados. | Solo `.gitkeep`. |
| `scripts/` | Automatización de laboratorio y escenarios. | `lab_session.sh` y `capture_session.sh` operativos en modo seco; captura real pendiente. |
| `fixtures/` | Prompts, workspace inicial y servidor local de F3. | Implementado y con 3 tests del servidor. |
| `tests/` | Tests unitarios, de integración, de pipeline, de políticas y de firewall. | 25 tests: 10 de infraestructura, 12 del manifiesto y 3 del fixture local. |
| Dashboard Streamlit | Monitorización de resultados. | No iniciado. |

### 3.2. Invariantes de diseño

- El modelo **no** ejecuta acciones de red.
- La política decide; el enforcement aplica; la monitorización solo lee.
- Las reglas deterministas y la predicción ML son fuentes separadas y combinables.
- La política por defecto es `ALLOW + LOG` para tráfico desconocido o no clasificado; `REVIEW` cuando la evidencia es insuficiente; solo se bloquea con regla explícita.
- El modo `APPLY` requiere privilegios, un namespace de laboratorio autorizado y validaciones explícitas. No se modifican las reglas globales del host.
- Un PCAP offline no permite bloquear retroactivamente una conexión terminada; la demostración exige repetir una conexión equivalente tras aplicar la regla.

## 4. Stack tecnológico y versiones validadas

| Componente | Versión comprobada | Papel |
|---|---|---|
| Kali Linux Rolling | 2026.3 | Entorno de laboratorio y desarrollo. |
| Kernel Linux | 7.1.5+kali-amd64 | Base del laboratorio de red. |
| Python | 3.14.8 | Lenguaje del pipeline. |
| Git | 2.53.0 | Control de versiones. |
| Zeek | 9.0.1 | Analizador principal de tráfico. |
| tcpdump | 4.99.6 | Captura de laboratorio. |
| tshark/Wireshark | 4.6.6 | Inspección y validación. |
| nftables | 1.1.7 | Filtrado. |
| iproute2 | 7.2.0 | Namespaces, veth y diagnóstico. |
| pandas | 3.1.1 | Procesamiento tabular. |
| NumPy | 2.5.4 | Cálculo numérico. |
| scikit-learn | 1.9.1 | Modelos y métricas. |
| joblib | 1.6.0 | Serialización. |
| PyYAML | 6.0.3 | Configuración y políticas. |
| Streamlit | 1.67.0 | Dashboard. |
| pytest | 9.2.0 | Testing. |
| Ruff | 0.17.5 | Linting y formato. |
| pre-commit | 4.7.0 | Hooks de Git configurados e instalados. |
| setuptools | 84.2.1 | Backend de build; instalado en `.venv`. |
| GitHub Actions | Configurada | CI de lint, formato y tests; se ejecutará al hacer push. |

## 5. Estructura actual del repositorio

```text
aigate/
├── config/                     # vacío
├── data/
│   ├── raw/.gitkeep            # PCAP originales; ignorados por Git
│   ├── processed/.gitkeep      # datos derivados; ignorados por Git
│   ├── external/.gitkeep       # datasets de terceros; ignorados por Git
│   ├── interim/.gitkeep        # datos intermedios; ignorados por Git
│   ├── manifests/.gitkeep      # manifiestos; ignorados por Git
│   └── work/.gitkeep           # copia por sesión del workspace; ignorada por Git
├── docs/
│   ├── PROJECT_CONTEXT.md
│   ├── PROJECT_STATUS.md
│   ├── DECISIONS.md
│   ├── DATA_CAPTURE.md         # diseño experimental y estado de 3.2
│   └── HANDOFF.md
├── fixtures/
│   ├── prompts/                # f1.txt, f2.txt, f3.txt
│   ├── workspace/              # estado inicial común de F1/F2
│   └── fixture_server.py       # servicio HTTP local para F3
├── models/.gitkeep             # artefactos; ignorados por Git
├── scripts/
│   ├── lab_session.sh          # laboratorio aislado: up/down/status/exec
│   ├── capture_session.sh      # captura, límites, hashes y manifiesto
│   └── _write_capture_manifest.py
├── src/aigate/
│   ├── __init__.py             # versión del paquete
│   ├── capture/
│   │   ├── __init__.py         # docstring
│   │   ├── manifest.py         # carga y validación de manifiestos
│   │   └── manifest-v1.schema.json
│   ├── features/__init__.py     # docstring; sin implementación
│   ├── models/__init__.py       # docstring; sin implementación
│   ├── policy/__init__.py       # docstring; sin implementación
│   └── enforcement/__init__.py  # docstring; sin implementación
├── tests/
│   ├── __init__.py
│   └── unit/
│       ├── __init__.py
│       ├── test_infrastructure.py
│       └── test_manifest.py
├── .github/workflows/tests.yml
├── .gitignore
├── .pre-commit-config.yaml
├── Makefile
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── README.md
└── LICENSE
```

La estructura es una separación inicial de responsabilidades. **No implica implementación.** Los subdirectorios de `src/aigate/` contienen un `__init__.py` con docstring y son importables, pero no tienen lógica de negocio. Los tests actuales verifican infraestructura, no funcionalidad del producto.

## 6. Principios y restricciones

- Una persona, 8 horas semanales, máximo 3 semanas y 24 horas efectivas.
- Presupuesto 0 €: software open source, datasets gratuitos, sin servicios cloud de pago ni APIs de pago.
- No Docker, no Deep Learning, no Suricata en el camino crítico, no CICFlowMeter salvo necesidad justificada.
- Zeek es el analizador principal; nftables es la tecnología de filtrado; iproute2 gestiona namespaces y veth.
- Priorizar funcionalidad, reproducibilidad y claridad frente a complejidad.
- No inventar datos, métricas ni resultados.
- No incluir credenciales, tokens, cookies, PCAP sensibles ni datasets privados en Git.
- Evitar data leakage: IP, dominios, SNI, identificadores de sesión, timestamps absolutos y nombres de escenario no se usarán como predictores del modelo.
- Mantener separación entre detección, clasificación, decisión y enforcement.

## 7. Estado actual del entorno

Comprobado el 2026-11-15:

- Entorno virtual `.venv` creado con Python 3.14.8; `include-system-site-packages = false`.
- Dependencias de ejecución instaladas desde `requirements.txt`; herramientas de desarrollo desde `requirements-dev.txt`.
- `requirements.txt` contiene solo runtime (pandas, NumPy, scikit-learn, joblib, PyYAML, Streamlit) y sus dependencias transitivas, con versiones fijas.
- `requirements-dev.txt` incluye `-r requirements.txt` y añade pytest, Ruff, pre-commit y setuptools.
- `pyproject.toml` declara dependencias estáticas en `[project].dependencies`, configura setuptools (`packages.find`), pytest (`testpaths`, `pythonpath`) y Ruff (`line-length`, `target-version`, reglas `E`, `F`, `I`, `B`, `UP`).
- El paquete está instalado en modo editable: `aigate 0.1.0`, apuntando a `src/aigate`.
- `setuptools 84.2.1` está instalado en `.venv` y satisface `setuptools>=75`.
- `python -m pip check` → `No broken requirements found.`
- `ruff check src tests` → `All checks passed!`
- `ruff format --check src tests` → `9 files already formatted`.
- `python -m pytest` → `10 passed`, exit code 0.
- `make check` → lint, formato y tests correctos.
- `pre-commit run --files ...` → todos los hooks pasan; hook instalado en `.git/hooks/pre-commit`.
- La instalación desde `requirements-dev.txt` + `pip install -e .` se validó en un venv limpio temporal: `pip check`, 10 tests y Ruff pasaron.
- `zeek --version` → `zeek version 9.0.1`.
- Zeek instalado desde `https://download.opensuse.org/repositories/security:/zeek/Debian_Testing`; el paquete de Kali `5.1.1-0kali3` no se usa por incompatibilidad con glibc.
- La rama de trabajo actual es `entrega-3-recogida-de-datos`, creada desde `main`; el árbol está limpio en `3ae9f4f Merge PR: entrega-2-entorno-y-estructura`. No hay commits nuevos ni push.
- La CI está configurada; se ejecutará en GitHub cuando el usuario haga push.

Comprobado el 2026-11-18 (Entrega 3, diseño y preparación del laboratorio):

- `opencode --version` → `2.1.4`, instalado en `/usr/bin/opencode`.
- `codex --version` → `0.170.0`; modelo reportado `gpt-6.2-sol`.
- `claude --version` → `2.1.327`; modelo reportado `Claude Opus 5.5` (`claude-opus-5-5`).
- Node.js y npm no están instalados; ninguno de los tres clientes los necesita.
- `bwrap`, `socat`, `jq`, `unshare` y `nsenter` están disponibles.
- `net.ipv4.ip_forward = 0` y `net.ipv6.conf.all.forwarding = 0`; no hay ningún network namespace activo.
- `jsonschema 4.26.0` está en `.venv` como dependencia transitiva fijada; se usa para validar manifiestos sin añadir paquetes.
- El piloto de conectividad creó `aigate-s01`, capturó 32 paquetes en `veth-h-s01` y obtuvo `401` de `api.deepseek.com`; la limpieza restauró `ip_forward=0` y eliminó namespace, veth y tabla nftables.
- `~/.codex` y `~/.claude` existen tras la instalación. **No se han leído ni copiado sus credenciales.**
- `scripts/lab_session.sh` implementa creación, verificación y limpieza con `trap`; no se ha ejecutado con `sudo` desde esta sesión.
- `scripts/capture_session.sh` implementa tcpdump, límites de duración/inactividad/tamaño, hashes, `capture.meta.json` y manifiesto; validado en seco, no ejecutado con `sudo`.
- `fixtures/prompts/{f1,f2,f3}.txt`, `fixtures/workspace/` y `fixtures/fixture_server.py` están implementados; el servidor tiene 3 tests en `tests/unit/test_fixture_server.py`.
- El diseño completo, las decisiones D-013…D-020 y el estado de 3.2 están en `docs/DATA_CAPTURE.md` y `docs/DECISIONS.md`.

## 8. Estado documental

La Entrega 1 se completó según el prompt maestro, pero sus artefactos no están presentes en `docs/`; el contexto disponible es `context/MASTER-PROMPT.md`. No se deben inventar documentos de planificación que no existan.

La Entrega 2 deja creados `PROJECT_CONTEXT.md`, `PROJECT_STATUS.md`, `DECISIONS.md` y `HANDOFF.md`, y actualiza `README.md`. También incorpora `Makefile`, `.pre-commit-config.yaml`, `.github/workflows/tests.yml`, `requirements-dev.txt` y los tests de infraestructura. Los documentos de entregas posteriores (`PROJECT_SPEC.md`, `ARCHITECTURE.md`, `DATASET_CARD.md`, `MODEL_CARD.md`, `TEST_PLAN.md`, `DEMO_RUNBOOK.md`) se crearán cuando exista contenido real que documentar.

La sub-entrega 3.1 añade `DATA_CAPTURE.md`, que contiene el diseño experimental completo y **no** datos. El 2026-11-18 el usuario aprobó las propuestas P-01…P-08 y P-10, rechazó P-09 y seleccionó ISCXVPN2016 Non-VPN; esas decisiones están registradas como D-013…D-020 en `DECISIONS.md`. `DATASET_CARD.md` no se crea hasta que existan capturas reales.

## 9. Documentos relacionados

- `docs/PROJECT_STATUS.md` — estado por componente, validaciones y pendientes.
- `docs/DECISIONS.md` — decisiones arquitectónicas y explicación aplicada.
- `docs/DATA_CAPTURE.md` — diseño experimental del dataset (Entrega 3): clientes, costes, aislamiento, captura, escenarios, etiquetado, manifiestos y riesgos.
- `docs/HANDOFF.md` — reanudación y recuperación del entorno.
- `README.md` — presentación, estructura, instalación y estado.
- `context/MASTER-PROMPT.md` — prompt maestro del proyecto.
