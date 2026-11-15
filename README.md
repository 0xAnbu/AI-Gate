# AIGate — AI-Aware Network Security Gateway

AIGate es una prueba de concepto de seguridad de red para Linux que combina análisis de tráfico, extracción de características, Machine Learning supervisado y un motor de políticas para identificar y controlar tráfico asociado a aplicaciones y agentes de IA.

No es un detector universal de tráfico generado por IA. Es un gateway experimental que separa evidencias deterministas (destinos, SNI, DNS, puertos y reglas) de la clasificación estadística, y que solo bloquea cuando existe una regla explícita.

## Estado actual

- **Entrega 1 — Diseño y planificación:** completada.
- **Entrega 2 — Entorno y estructura:** **completada.** Entorno Python, dependencias separadas, paquete instalado en modo editable, estructura de directorios, `Makefile`, pre-commit, CI, tests de infraestructura y documentación de cierre preparados.
- **Entrega 3:** no iniciada. No hay pipeline funcional, dataset ni modelo.

La documentación detallada del estado está en [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) y [`docs/HANDOFF.md`](docs/HANDOFF.md).

## Objetivo

AIGate pretende responder a una pregunta acotada: ¿puede un gateway Linux combinar metadatos de red y un clasificador supervisado para señalar tráfico asociado a agentes de IA, distinguiéndolo de la automatización convencional, y aplicar después una política de seguridad explicable?

El MVP previsto cubre:

- Captura PCAP/PCAPNG y simulación de tráfico en vivo desde un PCAP.
- Análisis con Zeek de flujos TCP/UDP y metadatos DNS, HTTP y TLS.
- Extracción de características estadísticas de flujo y de ventanas temporales.
- Clasificación con Random Forest y baseline de Logistic Regression.
- Motor de políticas independiente del modelo, con whitelist, blacklist, umbrales y acciones `ALLOW`, `ALERT`, `BLOCK` y `REVIEW`.
- Aplicación de decisiones mediante nftables en un laboratorio aislado con network namespaces.
- Monitorización con Streamlit.

## Clases de tráfico

| Etiqueta | Significado |
|---|---|
| `AI_SERVICE_TRAFFIC` | Tráfico dirigido a servicios de IA conocidos, identificado preferentemente por reglas deterministas. |
| `AGENT_ASSOCIATED_TRAFFIC` | Tráfico observado durante la ejecución de un agente: llamadas al proveedor, herramientas invocadas, descargas, repositorios, etc. |
| `AUTOMATION_NON_AI` | Automatización convencional: Nmap, curl, scripts, Python Requests, Burp, sqlmap, tareas programadas. |
| `HUMAN_REFERENCE` | Tráfico de referencia generado en escenarios controlados de interacción humana. |
| `UNKNOWN` | Tráfico sin evidencia suficiente. |

La distinción es deliberadamente estricta: que un destino sea un servicio de IA no demuestra que la conexión haya sido iniciada por un agente, y que el tráfico sea rápido o repetitivo no demuestra que sea de IA.

## Arquitectura prevista

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
            ZEEK  ---> conn.log / dns.log / http.log / ssl.log
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
        MOTOR DE POLÍTICAS  <--- whitelist / blacklist / reglas YAML
              |
              v
      ALLOW / ALERT / BLOCK / REVIEW
              |
              v
           NFTABLES
              |
              v
      FILTRADO EN EL LABORATORIO
              |
              v
         MONITORIZACIÓN
```

Invariante de diseño: el modelo **no** ejecuta acciones. La política decide; el módulo de enforcement aplica; la monitorización solo lee resultados.

## Stack

| Tecnología | Version | Uso en AIGate |
|---|---|---|
| Kali Linux Rolling | 2026.3 |
| Kernel | 7.1.5+kali-amd64 |
| Python | 3.14.8 | Desarrollo y ejecución del pipeline. |
| Zeek | 9.0.1 | Analizador principal de tráfico; genera registros estructurados. |
| tcpdump | 4.99.6 | Captura de laboratorio. |
| tshark/Wireshark | 4.6.6 | Inspección y validación de capturas. |
| pandas | 3.1.1 | Procesamiento y cálculo. |
| NumPy | 2.5.4 | Procesamiento y cálculo. |
| scikit-learn | 1.9.1 | Random Forest, Logistic Regression y métricas. |
| joblib | 1.6.0 | Serialización de modelos. |
| PyYAML | 6.0.3 | Configuración y políticas. |
| nftables | 1.1.7 | Aplicación de reglas de filtrado. |
| iproute2 | 7.2.0 | Network namespaces, veth y diagnóstico. |
| Streamlit | 1.67.0 | Dashboard de monitorización. |
| pytest | 9.2.0 | Tests. |
| Ruff | 0.17.5 | Linting y formato. |
| pre-commit | 4.7.0 | Hooks de Git configurados e instalados. |
| GitHub Actions | - | CI configurada en `.github/workflows/tests.yml`; se ejecutará al hacer push. |

Zeek procede del repositorio oficial de paquetes de Zeek (`security:/zeek/Debian_Testing`), no del paquete `5.1.1-0kali3` de Kali, que presentaba incompatibilidad con la versión de glibc del sistema. El detalle está en [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Estructura del repositorio

```text
aigate/
├── config/                 # Configuración YAML (vacío por ahora)
├── data/
│   ├── raw/                # PCAP originales; privados e ignorados por Git
│   ├── processed/          # Datos derivados y regenerables
│   ├── external/           # Datasets de terceros
│   ├── interim/            # Datos intermedios de transformación
│   └── manifests/          # Manifiestos de capturas y metadatos
├── docs/                   # Documentación persistente
├── models/                 # Modelos serializados (ignorados por Git)
├── scripts/                # Automatización de laboratorio (vacío por ahora)
├── src/aigate/
│   ├── __init__.py
│   ├── capture/__init__.py # Captura y orquestación de Zeek
│   ├── features/__init__.py # Extracción de características
│   ├── models/__init__.py  # Entrenamiento, predicción y serialización
│   ├── policy/__init__.py  # Motor de decisiones y reglas
│   └── enforcement/__init__.py # nftables y network namespaces
├── tests/
│   ├── __init__.py
│   └── unit/
│       ├── __init__.py
│       └── test_infrastructure.py
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

Los subdirectorios de `src/aigate/` ya son paquetes importables porque contienen un `__init__.py` con docstring, pero **no tienen funcionalidad**: son parte del esqueleto de la Entrega 2. No deben confundirse con módulos implementados.


## Puesta en marcha

El entorno virtual ya existe en `.venv`. Para usarlo:

```bash
cd /home/kali/Opencode/repos/aigate
source .venv/bin/activate
python --version          # Python 3.14.8
python -m pip check       # No broken requirements found.
make check                # Ruff + formato + 10 tests
```

Para recrearlo desde cero en otra máquina compatible:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pip install -e .
python -m pip check
make check
```

Notas:

- `requirements.txt` contiene únicamente dependencias de ejecución, con versiones fijas y sus dependencias transitivas.
- `requirements-dev.txt` incluye `-r requirements.txt` y añade pytest, Ruff, pre-commit, setuptools y sus dependencias.
- El paquete está instalado en modo editable (`aigate 0.1.0`), por lo que `import aigate` funciona desde cualquier directorio del entorno.
- `setuptools 84.2.1` está instalado en `.venv`; el build declara `setuptools>=75`.
- El `Makefile` invoca directamente `.venv/bin/python`, `.venv/bin/ruff` y `.venv/bin/pre-commit`, así que no exige activar el entorno en cada comando, pero sí que `.venv` exista.
- La secuencia `pip install -r requirements-dev.txt` + `pip install -e .` se validó en un entorno virtual limpio temporal: `pip check`, 10 tests y Ruff pasaron sin depender del `.venv` actual.

Comprobaciones disponibles:

```bash
make check                          # lint + format check + tests
make lint                           # ruff check src tests
make format                         # ruff format src tests
make test                           # pytest
pre-commit run --all-files          # hooks configurados; revisa archivos trackeados
zeek --version                      # zeek version 9.0.1
```

Los tests de infraestructura validan, entre otras cosas, que `pyproject.toml` usa dependencias estáticas, que runtime y desarrollo están separados, que los subpaquetes se importan, que existen los directorios esperados, que `.gitignore` protege datos sensibles y que Makefile, pre-commit y CI contienen los controles requeridos. La comprobación de Zeek se omite automáticamente si Zeek no está instalado, para que la CI pueda ejecutarse en un runner sin Zeek.

## Documentación

- [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) — contexto, arquitectura, stack y estado del entorno.
- [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) — estado real por componente, validaciones y pendientes.
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — decisiones técnicas y explicación aplicada de los conceptos.
- [`docs/HANDOFF.md`](docs/HANDOFF.md) — punto de reanudación y recuperación del entorno.

## Limitaciones conocidas

- La identificación de tráfico de IA a partir de estadísticas de red no puede ser universal: dos conexiones pueden producir patrones casi idénticos.
- HTTPS oculta la mayor parte de la información de aplicación. Solo se usarán metadatos visibles (DNS, SNI, TLS, tamaños, tiempos).
- Un PCAP analizado offline no permite bloquear retroactivamente una conexión ya terminada. La demostración de bloqueo requiere repetir una conexión equivalente en el laboratorio.
- El modo `APPLY` solo debe operar en un namespace de laboratorio autorizado, nunca sobre las reglas globales del host.
- No hay implementación del pipeline, dataset, modelo ni enforcement en este estado del repositorio.

## Licencia

MIT. Consulta [`LICENSE`](LICENSE).
