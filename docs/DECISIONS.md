# DECISIONS — AIGate

> Registro de decisiones técnicas y de sus consecuencias. Cada entrada explica el concepto aplicado al proyecto, no teoría genérica.
>
> Última actualización: 2026-11-15

---

## Formato

Cada decisión incluye:

- **Decisión:** qué se ha adoptado.
- **Contexto:** por qué era necesaria.
- **Justificación:** qué problema resuelve en AIGate.
- **Consecuencias:** ventajas, límites y deuda técnica.
- **Concepto aplicado:** explicación del mecanismo subyacente.

---

## D-001 — Kali Linux Rolling como entorno de referencia

**Estado:** aceptada.

**Decisión:** usar Kali Linux Rolling (2026.3, kernel 7.1.5+kali-amd64) como entorno de desarrollo y laboratorio, en lugar del Ubuntu 24.04 LTS.

**Contexto:** el entorno real confirmado es Kali Rolling. Ya incluye Zeek, tcpdump, tshark, nftables, iproute2 y las herramientas de red y seguridad ofensiva que el proyecto necesita para construir escenarios controlados.

**Justificación:** reducir instalaciones, trabajar sobre el sistema real que se va a utilizar en el laboratorio y disponer de las herramientas de captura, inspección y filtrado sin añadir capas artificiales. Kali es Debian-based, por lo que el stack Python y los paquetes del sistema son compatibles con el enfoque previsto. Debido a que es una VM facilita el trabajo sin poner en riesgo el equipo host.

**Consecuencias:**

- Es una distribución *rolling*: las versiones cambian con el tiempo. La reproducibilidad se apoya en `requirements.txt` y en documentar las versiones del sistema, no en asumir que Kali será idéntico dentro de meses.
- La desviación respecto a Ubuntu 24.04 queda registrada aquí. No se presenta Kali como equivalente exacto; se documenta como entorno real validado.
- No se deben ejecutar actualizaciones completas del sistema sin necesidad durante el proyecto, para no romper dependencias del laboratorio.

**Concepto aplicado:** el entorno de referencia no es solo un sistema operativo; es la combinación de kernel, librerías del sistema, herramientas de red y versiones de Python. Cambiar esa combinación puede cambiar el comportamiento de Zeek, nftables o las capturas. Por eso se documenta y se valida, en lugar de darla por supuesta.

---

## D-002 — Python 3.14.8 con entorno virtual `.venv`

**Estado:** aceptada.

**Decisión:** ejecutar AIGate con Python 3.14.8 dentro de `.venv`, con `include-system-site-packages = false`.

**Contexto:** Kali instala Python y paquetes del sistema mediante `apt`. Instalar pandas, scikit-learn o Streamlit globalmente con `pip` puede entrar en conflicto con paquetes del sistema y con otros proyectos.

**Justificación:** `.venv` crea un intérprete y un directorio `site-packages` propios. Las dependencias de AIGate quedan aisladas; activar el entorno cambia qué `python` y qué `pip` se usan. El proyecto puede fijar versiones sin afectar a las herramientas del sistema.

**Consecuencias:**

- Hay que activar el entorno antes de trabajar: `source .venv/bin/activate`.
- El archivo `.venv/pyvenv.cfg` confirma `include-system-site-packages = false`; el aislamiento es real, no solo nominal.
- Python 3.14 es una versión reciente. Algunas librerías podrían no soportarla; en este entorno las dependencias instaladas pasan `pip check`, pero esa compatibilidad debe vigilarse al añadir paquetes.
- `.venv/` está ignorado por Git y no debe publicarse.

**Concepto aplicado:** un entorno virtual no copia el intérprete completo necesariamente; crea una estructura con enlaces al intérprete base y un `site-packages` separado. El aislamiento evita que una actualización de una librería para AIGate rompa una herramienta del sistema que dependa de otra versión. Es la diferencia entre «funciona en mi máquina» y «funciona con este conjunto exacto de versiones».

---

## D-003 — Separación de dependencias de ejecución y desarrollo

**Estado:** aceptada.

**Decisión:** mantener `requirements.txt` solo con dependencias de ejecución y `requirements-dev.txt` con las herramientas de desarrollo. Ambos fijan versiones exactas, incluidas las dependencias transitivas.

**Contexto:** el proyecto debe ser reproducible con presupuesto 0 € y sin herramientas adicionales de gestión. Una instalación del paquete no debe arrastrar pytest, Ruff o pre-commit.

**Justificación:** `requirements.txt` contiene el cierre de runtime de AIGate: pandas, NumPy, scikit-learn, joblib, PyYAML, Streamlit y sus dependencias transitivas. `requirements-dev.txt` incluye `-r requirements.txt` y añade pytest, Ruff, pre-commit, setuptools y sus dependencias. Así, `pip install -r requirements.txt` reconstruye el entorno de ejecución y `pip install -r requirements-dev.txt` reconstruye el de desarrollo.

**Consecuencias:**

- Se fijan también dependencias transitivas, lo que mejora la reproducibilidad pero hace los archivos más largos y sensibles a la plataforma.
- No incluyen hashes de integridad; no son lockfiles de nivel industrial.
- `requirements-dev.txt` instala runtime por transitividad mediante `-r requirements.txt`; no se duplican versiones.
- `setuptools` queda en desarrollo/build, no como dependencia de ejecución del producto.
- Las versiones se derivaron del entorno validado; no se garantiza que todas tengan wheel para otros sistemas operativos.

**Concepto aplicado:** separar runtime y desarrollo evita que una herramienta de test o lint forme parte de la superficie de instalación del producto. `requirements.txt` responde a «qué necesita AIGate para ejecutarse»; `requirements-dev.txt` responde a «qué necesita una persona para desarrollarlo y verificarlo». Ambos usan `pip` y versiones fijas, sin añadir un gestor nuevo.

---

## D-004 — `pyproject.toml` como configuración del proyecto y de herramientas

**Estado:** aceptada.

**Decisión:** usar `pyproject.toml` para metadatos del paquete, backend de build, configuración de pytest y configuración de Ruff.

**Contexto:** el proyecto necesita una configuración única y versionada para que las mismas comprobaciones se ejecuten en local y en CI.

**Justificación:** `pyproject.toml` es el estándar de Python para declarar el proyecto y centralizar herramientas. En AIGate:

- `[build-system]` declara `setuptools>=75`.
- `[project]` define nombre, versión, descripción, `requires-python = ">=3.14"` y dependencias estáticas de ejecución.
- `[project.optional-dependencies].dev` declara pytest, Ruff, pre-commit y setuptools para instalaciones de desarrollo.
- `[tool.setuptools.packages.find]` descubre `aigate*` bajo `src/`.
- `[tool.pytest.ini_options]` fija `testpaths = ["tests"]`, `pythonpath = ["src"]` y `addopts = "-ra"`.
- `[tool.ruff]` fija longitud de línea 100, objetivo `py314` y reglas `E`, `F`, `I`, `B`, `UP`.

**Consecuencias:**

- El paquete está instalado en modo editable (`pip install -e .`) y `import aigate` funciona desde el entorno.
- `setuptools 84.2.1` está instalado en `.venv` y satisface el requisito de build.
- pytest puede importar `aigate` desde `src/` sin depender de la instalación, gracias a `pythonpath`.
- Las dependencias de ejecución son estáticas y directas; `requirements.txt` conserva el cierre completo con transitivas para reproducibilidad.
- `pyproject.toml` no sustituye a un lockfile; la combinación con `requirements.txt` fijado es la que aporta reproducibilidad.

**Concepto aplicado:** `requirements.txt` responde a «qué instalar»; `pyproject.toml` responde a «qué es este proyecto y cómo se construye, prueba y lintéa». Se complementan. El primero es una foto del entorno; el segundo es la configuración estable del repositorio. Las dependencias estáticas evitan que el paquete arrastre herramientas de desarrollo.

---

## D-005 — Zeek 9.0.1 desde el repositorio oficial, no el paquete de Kali

**Estado:** aceptada.

**Decisión:** usar Zeek 9.0.1 instalado desde `https://download.opensuse.org/repositories/security:/zeek/Debian_Testing`. No usar el paquete `5.1.1-0kali3` de Kali.

**Contexto:** el paquete 5.1.1 de los repositorios Kali presentaba incompatibilidad con la versión de glibc del sistema. La instalación real se revisó antes de ejecutarla mediante una simulación.

**Justificación:** Zeek es el analizador principal del proyecto. Debe ejecutarse de forma estable y generar registros que el pipeline pueda consumir. Un paquete incompatible con la libc del sistema no es una base fiable. La versión 9.0.1 responde correctamente a `zeek --version` y el paquete figura instalado como `zeek 9.0.1-0`.

**Consecuencias:**

- Se añade un repositorio de terceros (openSUSE OBS) con su clave firmada. Hay que documentar su origen y no mezclarlo con paquetes de Kali sin control.
- `apt-cache policy zeek` muestra dos candidatos: `9.0.1-0` del repositorio de Zeek y `5.1.1-0kali3` de Kali. Una actualización descuidada podría intentar cambiar de origen; hay que revisar antes de actualizar.
- No se reinstala ni se cambia de versión en esta entrega.

**Concepto aplicado:** Zeek es un analizador de tráfico pasivo. Lee paquetes de una interfaz o de un PCAP, reconstruye flujos y aplica analizadores de protocolo. En lugar de mostrar paquetes individuales, escribe registros estructurados como `conn.log`, `dns.log`, `http.log` y `ssl.log`. En AIGate, Zeek será la fuente de verdad de los flujos: el pipeline no reinventará la reconstrucción TCP ni el parseo de protocolos. Zeek no es un firewall inline; no bloquea por sí mismo. La decisión de bloquear corresponderá al motor de políticas y a nftables.

---

## D-006 — Estructura `src/` y separación por responsabilidades

**Estado:** aceptada.

**Decisión:** organizar el código en `src/aigate/` con subpaquetes `capture`, `features`, `models`, `policy` y `enforcement`.

**Contexto:** el proyecto debe crecer desde un esqueleto hasta un pipeline con captura, features, modelo, políticas y enforcement. Sin separación, el modelo podría acabar ejecutando acciones o la lógica de red podría mezclarse con la de clasificación.

**Justificación:**

- `capture/` encapsula PCAP, simulación y Zeek.
- `features/` transforma registros en variables; no decide.
- `models/` entrena, evalúa, guarda y carga; no aplica políticas.
- `policy/` combina evidencias, umbrales, whitelist y predicción; decide.
- `enforcement/` traduce decisiones a nftables y gestiona namespaces; no clasifica.

La estructura `src/` evita importar accidentalmente desde el directorio de trabajo y obliga a que el paquete tenga una ubicación explícita. Con `pythonpath = ["src"]`, pytest puede importar `aigate` sin instalarlo; además, el paquete está instalado en modo editable, por lo que el import también funciona fuera de pytest.

**Consecuencias:**

- Cada subdirectorio contiene un `__init__.py` con docstring; Git los versiona y Python los trata como paquetes importables.
- **No son componentes implementados:** no hay funciones, clases ni lógica de captura, features, modelo, política o enforcement.
- La separación permite testear políticas sin privilegios y enforcement con un laboratorio autorizado, sin mezclar ambos.
- Los tests actuales comprueban que los paquetes se importan; no prueban comportamiento de producto.

**Concepto aplicado:** `src/` es un *layout* de empaquetado. Si el código estuviera en la raíz, un `import aigate` podría resolver al directorio actual en lugar de a la versión instalada. Con `src/`, el import es inequívoco. La separación por subpaquetes aplica el principio de responsabilidad única: un fallo en el modelo no debe poder modificar reglas de firewall por accidente. Un `__init__.py` con docstring declara la frontera del paquete; no implementa la funcionalidad.

---

## D-007 — Separación de datos `raw`, `processed`, `external`, `interim` y `manifests`

**Estado:** aceptada.

**Decisión:** usar `data/raw/`, `data/processed/`, `data/external/`, `data/interim/` y `data/manifests/` como ubicaciones separadas.

**Contexto:** el proyecto generará PCAP propios, datos derivados, datos intermedios, manifiestos de procedencia y datasets complementarios de terceros.

**Justificación:**

- `raw/`: capturas originales. Deben ser inmutables. Si se reprocesan, no se sobrescriben.
- `processed/`: características, agregados y datasets listos para el modelo. Son derivados y deben poder regenerarse desde `raw/`.
- `external/`: datasets de terceros. Tienen su propia licencia, formato y limitaciones; no se mezclan con las capturas propias.
- `interim/`: resultados intermedios de transformaciones que todavía no son el dataset final.
- `manifests/`: metadatos de capturas y sesiones (proveedor, escenario, etiqueta, timestamps, namespace, método de generación). Relacionan cada dato con su procedencia.

Esta separación permite auditar el origen de cada dato y evita que un dataset externo contamine sin control el conjunto experimental de AIGate.

**Consecuencias:**

- Actualmente existen los cinco directorios con `.gitkeep`; no hay datos.
- El formato exacto de los manifiestos se definirá en la Entrega 3, cuando existan capturas reales.
- Los cinco directorios están ignorados por Git salvo sus marcadores `.gitkeep`.

**Concepto aplicado:** «raw» es el dato tal como se capturó; «interim» es una transformación parcial; «processed» es el resultado reproducible; «external» es un dato que no controlamos; «manifests» describe qué es cada dato. Mezclarlos impide saber si un resultado proviene de una captura propia o de un dataset ajeno, y dificulta reproducir el pipeline. En un proyecto de ML, la trazabilidad del dato es parte de la validez del resultado.

---

## D-008 — Protección de PCAP, datasets y artefactos con `.gitignore`

**Estado:** aceptada.

**Decisión:** ignorar `.venv/`, cachés, `data/raw/*`, `data/processed/*`, `data/external/*`, `data/interim/*`, `data/manifests/*`, `models/*`, `*.pcap`, `*.pcapng`, `*.log` y archivos `.env`, manteniendo `.gitkeep` como excepción. Añadir además controles automáticos de secretos y tamaño en pre-commit.

**Contexto:** las capturas de tráfico y los datasets pueden contener información sensible y pueden ser grandes. Git conserva el historial: borrar un archivo en un commit posterior no lo elimina de commits anteriores.

**Justificación:**

- Un PCAP puede incluir cookies, tokens, credenciales en HTTP, nombres de usuario, direcciones internas o metadatos de sesión. Aunque el tráfico sea de laboratorio, no debe publicarse sin revisión.
- Los datasets pueden tener licencias que impiden su redistribución.
- Los modelos y datos derivados son reproducibles; no necesitan estar en Git.
- `.env` puede contener claves de API. Nunca debe versionarse; si hace falta una plantilla, se usará `.env.example` sin valores reales.
- Los manifiestos también pueden contener metadatos sensibles; se ignoran por defecto.

**Consecuencias:**

- `.gitkeep` permite conservar la estructura de directorios vacíos sin subir su contenido.
- La protección no es completa: `*.joblib`, `*.pkl`, `reports/` o `artifacts/` no están cubiertos explícitamente. Se ampliará cuando se definan esas rutas.
- pre-commit incluye `detect-private-key` y `check-added-large-files` (1 MB), por lo que los commits pasan por controles de secretos y tamaño.
- Ignorar no es lo mismo que sanitizar: antes de publicar cualquier captura habrá que revisarla y documentar el proceso.

**Concepto aplicado:** `.gitignore` evita que archivos no deseados entren en el índice de Git. No es un mecanismo de cifrado ni de control de acceso; es una barrera contra errores. La regla práctica de AIGate es: si un dato puede contener tráfico real, credenciales o información personal, no se sube. Los hooks de pre-commit añaden una segunda barrera antes de crear el commit.

---

## D-009 — pytest, Ruff, pre-commit y CI como controles de calidad

**Estado:** aceptada y automatizada.

**Decisión:** usar pytest para tests, Ruff para linting y formato, pre-commit para controles locales antes del commit y GitHub Actions para las mismas comprobaciones en remoto.

**Contexto:** el proyecto necesita controles repetibles antes de cada cambio y en CI. La calidad no debe depender de recordar comandos manuales.

**Justificación:**

- pytest descubre tests en `tests/`, permite fixtures y se integra con la configuración del proyecto. En AIGate se usarán tests unitarios para features y políticas, y tests de integración para captura y enforcement.
- Ruff sustituye a varias herramientas de linting y formato con una sola dependencia. Detecta errores comunes (`E`, `F`), orden de imports (`I`), problemas de diseño (`B`) y sugerencias de modernización (`UP`).
- `ruff format --check` verifica que el formato es consistente sin modificar archivos.
- pre-commit ejecuta Ruff, Ruff format, validación YAML/JSON/TOML, corrección de fin de archivo y espacios, detección de claves privadas, límite de tamaño y pytest antes de cada commit.
- La CI ejecuta `ruff check`, `ruff format --check` y `pytest` en un runner limpio.

**Consecuencias:**

- `python -m pytest` recoge **10 tests** de infraestructura y termina con `10 passed`, exit code 0.
- `ruff check src tests` pasa sobre 9 archivos; `ruff format --check` confirma que están formateados.
- pre-commit está instalado en `.git/hooks/pre-commit`; en la primera ejecución descargó y fijó los entornos de los hooks.
- La CI está configurada, pero no se ha ejecutado en GitHub porque no hay push.
- La secuencia `pip install -r requirements-dev.txt` + `pip install -e .` se validó en un venv limpio temporal: `pip check`, 10 tests y Ruff pasaron sin depender del `.venv` local.
- Los tests actuales validan el esqueleto (configuración, dependencias, imports, directorios, `.gitignore`, Makefile, pre-commit y CI), no la funcionalidad del producto.
- La comprobación de Zeek se omite si Zeek no está instalado, para que la CI no dependa de una herramienta del sistema.

**Concepto aplicado:** pytest es un *test runner*: descubre funciones de test, las ejecuta y reporta fallos. Ruff es un analizador estático y un formateador: no ejecuta el código, pero detecta patrones problemáticos y unifica estilo. pre-commit y CI son capas de ejecución: la primera protege el commit local; la segunda verifica que el resultado no depende de la máquina de desarrollo. Cero tests no era un error de configuración: era ausencia de tests. Se resolvió añadiendo comprobaciones reales, no ocultando el código de salida 5.

---

## D-010 — Documentación persistente y cierre honesto de entrega

**Estado:** aceptada.

**Decisión:** mantener `PROJECT_CONTEXT.md`, `PROJECT_STATUS.md`, `DECISIONS.md` y `HANDOFF.md` como fuente de verdad, y no declarar completados componentes que solo tienen directorios o herramientas instaladas sin configurar.

**Contexto:** el proyecto se desarrolla en varias conversaciones y el repositorio debe permitir retomarlo sin depender del historial del chat.

**Justificación:** la documentación persistente evita repetir decisiones, permite detectar regresiones y deja claro qué está implementado, qué está probado y qué solo está preparado. En esta entrega, esa distinción es importante: existen paquetes importables y tests de infraestructura, pero no hay pipeline de producto.

**Consecuencias:**

- La Entrega 2 queda completada técnicamente: entorno, empaquetado, automatización, tests y documentación.
- El estado real se documenta sin maquillar: los módulos de `src/aigate/` siguen sin implementación y no hay datos ni modelo.
- Los documentos se actualizan al final de cada entrega; no se crean documentos redundantes.
- No se han hecho commits; el trabajo queda en la rama `entrega-2-entorno-y-estructura` para revisión y commit del usuario.

**Concepto aplicado:** un repositorio es un contrato de estado. Si la documentación dice «implementado» cuando solo hay un paquete vacío, la siguiente persona (o la siguiente conversación) tomará decisiones sobre una base falsa. El coste de documentar una carencia es mucho menor que el de descubrirla durante la demo o la entrevista.

---

## D-011 — Makefile como interfaz única de tareas

**Estado:** aceptada.

**Decisión:** incorporar un `Makefile` con objetivos `install`, `install-dev`, `lint`, `format`, `format-check`, `test`, `check`, `pre-commit-install`, `pre-commit` y `clean`.

**Contexto:** el proyecto tiene varias comprobaciones que deben ejecutarse de forma consistente. Recordar comandos manuales invita a olvidar pasos o a ejecutarlos en un orden distinto.

**Justificación:** el `Makefile` usa rutas explícitas a `.venv/bin/python`, `.venv/bin/ruff` y `.venv/bin/pre-commit`. `make install` instala el paquete; `make install-dev` instala las dependencias de desarrollo y el paquete; `make check` ejecuta lint, comprobación de formato y tests sin modificar archivos; `make format` aplica formato. `make pre-commit` ejecuta todos los hooks.

**Consecuencias:**

- `make check` es la comprobación previa recomendada y actualmente termina con `10 passed`.
- El `Makefile` asume que `.venv` existe; no crea el entorno automáticamente para no ocultar el paso de creación.
- `make format` modifica archivos; `make check` no.
- No sustituye a la CI: la CI verifica el repositorio en un entorno limpio.

**Concepto aplicado:** un `Makefile` es una interfaz declarativa de tareas. Los objetivos `.PHONY` evitan que `make` los confunda con archivos. Al centralizar los comandos, se reduce la variación entre ejecuciones y se documenta implícitamente el flujo de desarrollo. No es una herramienta nueva del stack: es un automatizador disponible en el sistema.

---

## D-012 — Tests de infraestructura para verificar el esqueleto

**Estado:** aceptada.

**Decisión:** añadir tests de infraestructura en `tests/unit/test_infrastructure.py` que validen la configuración y el esqueleto del repositorio.

**Contexto:** la Entrega 2 no tiene funcionalidad de producto que testear, pero sí invariantes que deben mantenerse: separación de dependencias, paquete importable, directorios de datos, protecciones de `.gitignore`, objetivos del Makefile, hooks de pre-commit y comandos de CI.

**Justificación:** los tests comprueban:

- Versión de Python soportada.
- `pyproject.toml` con dependencias estáticas y `requires-python`.
- Separación de `requirements.txt` y `requirements-dev.txt`.
- Existencia de los directorios de datos y estructura.
- Importación de `aigate` y sus cinco subpaquetes.
- Patrones críticos de `.gitignore`.
- Objetivos requeridos en el Makefile.
- Hooks de Ruff, Ruff format y pytest en pre-commit.
- Comandos de lint, formato y test en el workflow de CI.
- Zeek operativo cuando está instalado; si no, el test se omite.

**Consecuencias:**

- `pytest` deja de devolver exit code 5 y pasa a `10 passed`.
- Los tests no demuestran que el pipeline funcione: solo que el esqueleto y la configuración son coherentes.
- La omisión de Zeek permite ejecutar la CI en un runner sin Zeek, sin ocultar el estado local.
- Cuando exista código de producto, se añadirán tests unitarios y de integración específicos.

**Concepto aplicado:** un test de infraestructura verifica el contrato del repositorio, no la lógica de negocio. Es útil para detectar regresiones en la configuración y para que la CI tenga algo real que ejecutar desde el primer día. No se debe crear un test vacío solo para obtener verde; cada aserción debe corresponder a una decisión del proyecto.

---

## Decisiones pendientes

Estas decisiones **no** se han tomado en esta entrega y requieren revisión o aprobación:

3. **Manifiestos:** definir el esquema exacto de `data/manifests/` en la Entrega 3.
4. **Artefactos:** decidir si se añaden patrones para `*.joblib`, `*.pkl`, `reports/` y `artifacts/` cuando existan esas rutas.
5. **Lockfile:** valorar hashes de integridad si el proyecto crece; no es necesario para el MVP actual.
6. **Producto:** implementar captura, features, modelo, políticas y enforcement en las siguientes entregas.

---

## Resumen de decisiones aceptadas

| ID | Decisión |
|---|---|
| D-001 | Kali Linux Rolling como entorno real, documentando la desviación respecto a Ubuntu 24.04. |
| D-002 | Python 3.14.8 aislado en `.venv`. |
| D-003 | Separación de dependencias de ejecución (`requirements.txt`) y desarrollo (`requirements-dev.txt`). |
| D-004 | `pyproject.toml` con dependencias estáticas, extras de desarrollo, build, pytest y Ruff. |
| D-005 | Zeek 9.0.1 desde el repositorio oficial, evitando el paquete incompatible de Kali. |
| D-006 | Estructura `src/aigate/` con paquetes importables y separación capture/features/models/policy/enforcement. |
| D-007 | Separación de datos raw, processed, external, interim y manifests. |
| D-008 | Protección de PCAP, datasets, modelos y secretos mediante `.gitignore` y pre-commit. |
| D-009 | pytest, Ruff, pre-commit y CI como controles de calidad automatizados. |
| D-010 | Documentación persistente y cierre honesto del estado. |
| D-011 | Makefile como interfaz única de tareas de desarrollo. |
| D-012 | Tests de infraestructura para verificar el esqueleto del repositorio. |
