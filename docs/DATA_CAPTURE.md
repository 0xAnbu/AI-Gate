# DATA CAPTURE — AIGate

> Diseño experimental del **«AIGate Controlled Agent Traffic Dataset»**.
>
> **Sub-entrega 3.1 — investigación y diseño: aprobada.** Sub-entrega 3.2 — laboratorio y piloto: **en curso**.
>
> Fecha de referencia de la investigación: **2026-11-16**. Fecha del documento: 2026-11-18.
>
> Estado: decisiones **D-013…D-020 aceptadas**. Los clientes están instalados, el piloto de conectividad se ejecutó con 32 paquetes y la limpieza se verificó. **No hay todavía capturas del dataset.**

---

## Aviso de alcance

Este documento responde a una pregunta previa a la captura: *¿qué habría que hacer, por qué, con qué límites y cómo se verificaría?* No es un runbook ejecutado ni un Dataset Card. El Dataset Card se escribirá en la sub-entrega posterior, cuando existan capturas reales y cifras reales.

Todo lo que aquí aparece como cifra de coste, tamaño o duración es una **estimación con supuestos explícitos**, no una medición. Lo que no se ha podido verificar con una fuente oficial está marcado como **[NO VERIFICADO]**.

---

## Índice

1. [Objetivo y criterios de aceptación](#1-objetivo-y-criterios-de-aceptación)
2. [Punto de partida verificado](#2-punto-de-partida-verificado)
3. [Selección de agentes y clientes](#3-selección-de-agentes-y-clientes)
4. [Viabilidad económica con presupuesto 0 €](#4-viabilidad-económica-con-presupuesto-0-€)
5. [Arquitectura de aislamiento](#5-arquitectura-de-aislamiento)
6. [Diseño de la captura](#6-diseño-de-la-captura)
7. [Escenarios positivos](#7-escenarios-positivos)
8. [Controles negativos](#8-controles-negativos)
9. [Etiquetado y procedencia](#9-etiquetado-y-procedencia)
10. [Esquema de manifiesto](#10-esquema-de-manifiesto)
11. [Dataset externo complementario](#11-dataset-externo-complementario)
12. [Viabilidad temporal](#12-viabilidad-temporal)
13. [Riesgos y mitigaciones](#13-riesgos-y-mitigaciones)
14. [Decisiones aceptadas](#14-decisiones-aceptadas)
15. [Estado de la sub-entrega 3.2](#15-estado-de-la-sub-entrega-32)
16. [Referencias](#16-referencias)

---

## 1. Objetivo y criterios de aceptación

### 1.1. Objetivo

Construir, con presupuesto 0 €, una persona y 24 horas efectivas, un conjunto de capturas de tráfico **reproducible, aislado y honestamente etiquetado** que permita estudiar si existen diferencias observables en el plano de red entre:

- tres agentes de IA que usan tres proveedores distintos (OpenAI, Anthropic, DeepSeek);
- una misma tarea ejecutada por cada uno de ellos;
- y un conjunto de controles negativos (automatización no-IA, resolución DNS, handshake TLS, reposo).

El dataset no pretende demostrar que «el tráfico de IA es detectable». Pretende producir evidencia suficiente para entrenar y evaluar un clasificador **y**, sobre todo, para medir sus límites.

### 1.2. Qué se entrega en 3.1

| Artefacto | Estado |
|---|---|
| Comparativa de clientes con fuentes oficiales | Completo; versiones y modelos confirmados en el equipo |
| Análisis de autenticación, credenciales y fugas | Completo |
| Arquitectura de aislamiento con netns + veth + nftables | Diseñada y validada con un piloto de conectividad |
| Diseño de captura y análisis con Zeek | Diseñado; captura de humo de 32 paquetes |
| Escenarios positivos (27 sesiones) | Diseñados; ninguna sesión de dataset ejecutada |
| Controles negativos | Diseñados; 7 controles |
| Esquema de manifiesto y etiquetado | Diseñado e implementado el esquema v1 |
| Evaluación de dataset externo | Completa; ISCXVPN2016 Non-VPN seleccionado |
| Estimación temporal y plan de repliegue | Completa |
| `scripts/lab_session.sh` | Implementado; `up`/`down`/`status`/`exec` con rollback |
| Este documento | Actualizado a decisiones aceptadas |

### 1.3. Qué **no** se entrega todavía

- No hay PCAP del dataset: el único PCAP existente es una prueba de conectividad de 32 paquetes en `/tmp`, no una sesión experimental.
- No hay manifiestos de sesión rellenados ni Dataset Card.
- No hay logs Zeek de sesiones reales.
- No se ha descargado ISCXVPN2016.
- No se han ejecutado las 27 sesiones positivas ni los 7 controles negativos.

### 1.4. Criterios de aceptación de 3.1

1. Cada recomendación técnica importante explica qué es, por qué se elige, cómo se aplicaría, qué alternativas existen, qué límites tiene y cómo se verificaría.
2. Toda afirmación sobre precios, planes, versiones o comportamiento de un cliente tiene fuente oficial o está marcada **[NO VERIFICADO]**.
3. La arquitectura cubre explícitamente DNS, IPv6, herencia de procesos hijos, fugas, colocación de la captura, NAT, limpieza y rollback.
4. El etiquetado distingue sesión, flujo y procedencia, y **no** promete atribución por paquete.
5. Se justifica cualquier reducción de las 27 sesiones positivas.

---

## 2. Punto de partida verificado

Comprobado en `/home/kali/Opencode/repos/aigate` el 2026-11-18.

### 2.1. Repositorio

| Elemento | Valor real |
|---|---|
| Rama actual | `entrega-3-recogida-de-datos` |
| Último commit | `3ae9f4f Merge PR: entrega-2-entorno-y-estructura` |
| Árbol de trabajo | Cambios de 3.1/3.2 sin commitear |
| `main` | También en `3ae9f4f` |
| Commits nuevos | **Ninguno** |
| `make check` | Pasa: Ruff correcto, 25 tests |

La documentación persistente estaba desactualizada: `PROJECT_STATUS.md` y `HANDOFF.md` describían la rama `entrega-2-entorno-y-estructura` y trabajo sin commitear. Se corrigió en 3.1 y se actualiza de nuevo aquí.

### 2.2. Sistema y herramientas

| Componente | Valor real | Relevancia para la captura |
|---|---|---|
| Kali Linux Rolling | 2026.3 | Entorno de laboratorio |
| Kernel | `7.1.5+kali-amd64` | netns, veth, nftables |
| Python | 3.14.8 | Pipeline y validación de manifiestos |
| Zeek | 9.0.1 | Analizador principal |
| tcpdump | 4.99.6 | Captura |
| tshark | 4.6.6 | Inspección y validación |
| nftables | 1.1.7 | NAT y filtrado de laboratorio |
| iproute2 | 7.2.0 | netns, veth, diagnóstico |
| OpenCode | 2.1.4 (`/usr/bin/opencode`) | Cliente para DeepSeek |
| `codex` | **Instalado**: 0.170.0, modelo `gpt-6.2-sol` | Cliente para OpenAI |
| `claude` | **Instalado**: 2.1.327, modelo `Claude Opus 5.5` | Cliente para Anthropic |
| Node.js / npm | **No instalados** | Ninguno de los tres clientes los necesita |
| `jq` | Instalado | Procesamiento de JSON |
| `bwrap` | Instalado | Sandbox de Codex/Claude en Linux |
| `socat` | Instalado | Utilidades de laboratorio |
| `unshare`, `nsenter` | Instalados | Diagnóstico de namespaces |
| `jsonschema` (Python) | 4.26.0, ya fijado en `requirements.txt` | Validación de manifiestos |

Los tres clientes se instalaron con los instaladores oficiales y se verificaron con `--version`. Los modelos mostrados son los que cada cliente reporta por defecto en esta fecha; se registran por sesión y no se asumen estables.

### 2.3. Estado de red y privilegios

| Comprobación | Resultado | Implicación |
|---|---|---|
| `net.ipv4.ip_forward` | `0` (restaurado tras el piloto) | El script guarda y restaura el valor previo |
| `net.ipv6.conf.all.forwarding` | `0` | No se toca; IPv6 se desactiva dentro del ns |
| `ip netns list` | Vacío tras la limpieza | El piloto no dejó estado |
| `sudo` | Requiere contraseña | Todo paso privilegiado es manual y del usuario |
| `~/.codex` | Existe tras la instalación | Contiene credenciales; **no se lee ni se copia** |
| `~/.claude` | Existe tras la instalación | Contiene credenciales; **no se lee ni se copia** |

### 2.4. Piloto de conectividad ejecutado

Comandos del `context/Entrega-3-contexto-temporal.txt`, ejecutados por el usuario:

| Comprobación | Resultado real |
|---|---|
| Interfaz WAN detectada | `eth0` |
| Namespace y veth | `aigate-s01` / `veth-h-s01` / `veth-n-s01` creados |
| DNS del ns | `nameserver 1.1.1.1` |
| IPv6 dentro del ns | `disable_ipv6 = 1` |
| `curl https://api.deepseek.com/` desde el ns | HTTP `401` (sin credenciales, esperado) |
| Captura en `veth-h-s01` | 32 paquetes, 0 descartados por el kernel |
| `ip_forward` tras la limpieza | `0` |
| Tabla nftables tras la limpieza | Eliminada |
| Namespace tras la limpieza | Eliminado |

Esto valida la topología, el NAT, el DNS, el apagado de IPv6 y el rollback. **No** valida el dataset: no hay agente, no hay tarea y no hay manifiesto.

### 2.5. Consecuencia

La infraestructura mínima está probada. Lo que falta es ejecutar las sesiones reales: instalar la configuración de cada cliente, autenticar, lanzar tareas y rellenar manifiestos. Cualquier paso privilegiado sigue siendo manual y del usuario.

---

## 3. Selección de agentes y clientes

### 3.1. Restricción del proyecto

El prompt maestro exige exactamente tres proveedores: **OpenAI, Anthropic y DeepSeek**. El objetivo es comparar *agentes*, no *modelos sueltos*. Por tanto se elige un cliente de agente por proveedor y se mantiene el mismo tipo de tarea entre los tres.

### 3.2. Distinciones que el dataset debe preservar

Cuatro campos distintos, que no deben colapsarse en una sola etiqueta:

| Campo | Qué identifica | Ejemplo |
|---|---|---|
| `agent_provider` | Empresa que sirve el modelo | `openai`, `anthropic`, `deepseek` |
| `agent_client` | Programa que ejecuta el bucle del agente | `codex-cli`, `claude-code`, `opencode` |
| `model_version` | Identificador del modelo reportado por el proveedor | `deepseek-flash` / `DeepSeek-V4.1-Flash-1017` |
| `client_version` | Versión del binario del cliente | `0.170.0`, `2.1.327`, `2.1.4` |

Motivo: un cambio de comportamiento de red puede deberse al cliente (telemetría, actualizador, protocolo de streaming) y no al modelo. Si se confunden, cualquier conclusión sobre «tráfico de OpenAI» será en realidad una conclusión sobre «tráfico de Codex CLI 0.170.0».

### 3.3. Comparativa

Versiones y modelos **verificados en este equipo** el 2026-11-18 con `--version` y el modelo que cada cliente reporta por defecto. La versión se fija en el manifiesto; el modelo puede cambiar sin cambiar el binario.

| | OpenAI | Anthropic | DeepSeek |
|---|---|---|---|
| Cliente | Codex CLI | Claude Code | OpenCode |
| Versión verificada | `0.170.0` | `2.1.327` | `2.1.4` |
| Modelo reportado | `gpt-6.2-sol` | `Claude Opus 5.5` (`claude-opus-5-5`) | `deepseek-flash` (`DeepSeek-V4.1-Flash-1017`) |
| Instalación | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` | `curl -fsSL https://claude.ai/install.sh \| bash` | Ya instalada; alternativa `dsh` |
| Autenticación | Login ChatGPT (navegador) o API key | OAuth con Pro/Max/Team/Enterprise o Console | API key |
| Modo no interactivo | `codex exec` | `claude -p` | `opencode run --standalone` |
| Aislamiento de red propio | `--sandbox workspace-write`; red **off** por defecto | Sandbox con `bwrap` en Linux | Servidor local; requiere `--standalone` |
| Coste | Uso confirmado por el usuario sin límites | Uso confirmado por el usuario sin límites | Uso confirmado por el usuario sin límites |
| Requiere Node.js | No | No | No |
| Requiere Node.js | No (binario) | No (binario) | No (binario instalado) |

### 3.4. Justificación por proveedor

#### OpenAI — Codex CLI

**Qué es.** Cliente de agente de OpenAI que ejecuta tareas de codificación en terminal, con sandbox local y modo no interactivo (`codex exec`).

**Por qué se elige.** Es el cliente oficial de agente de OpenAI, tiene modo no interactivo documentado, salida JSON (`--json`) y un sandbox propio que reduce el riesgo de que el agente toque el host. Su sandbox usa `bwrap` y `seccomp` en Linux, y ambas dependencias están presentes.

**Alternativas descartadas.** La API directa con `curl` no es un agente: no hay bucle de herramientas ni tráfico de cliente. La app de escritorio añade GUI y superficie de red no reproducible. Usar la API desde un script propio mediría «un cliente escrito por nosotros», no «un agente de OpenAI», y rompería la comparación.

**Límites.** El acceso a red del sandbox está **desactivado por defecto** y hay que habilitarlo explícitamente (`[sandbox_workspace_write] network_access = true`) o el agente no llegará al proveedor. El modelo reportado por defecto es `gpt-6.2-sol`, pero puede cambiar con el plan o una actualización; se registra en cada sesión.

**Verificación.** `codex --version` debe devolver `0.170.0` (o la versión registrada), `codex exec --help` debe mostrar el modo no interactivo, y una sesión de humo debe producir al menos una conexión TLS al host del proveedor.

#### Anthropic — Claude Code

**Qué es.** Cliente de agente de Anthropic para terminal, con herramientas de edición, ejecución de comandos y modo `-p` no interactivo.

**Por qué se elige.** Es el cliente oficial de agente de Anthropic y el único que la documentación vincula a los planes de suscripción. `bwrap` está disponible, que es la dependencia del sandbox en Linux.

**Alternativas descartadas.** `--bare` **no** sirve para este experimento: usa API key y no la suscripción, por lo que cambiaría el modo de autenticación y el modelo de coste. La API directa tiene el mismo problema que en OpenAI.

**Límites.** La documentación oficial indica que «el plan gratuito de claude.ai no incluye acceso a Claude Code»; el usuario confirma que dispone de acceso sin límites para este proyecto. El modelo reportado es `Claude Opus 5.5` (`claude-opus-5-5`). El autoactualizador está activo por defecto y debe desactivarse durante la captura.

**Verificación.** `claude --version` → `2.1.327`; `claude -p "responde OK"` debe devolver texto y generar tráfico a los hosts documentados; `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` debe reducir el tráfico no esencial (se comprueba comparando con y sin la variable en el piloto).

#### DeepSeek — OpenCode

**Qué es.** OpenCode es un cliente de agente de terminal multi-proveedor. DeepSeek lo documenta oficialmente como integración y publica una base compatible con OpenAI (`https://api.deepseek.com`) y otra con formato Anthropic (`https://api.deepseek.com/anthropic`).

**Por qué se elige.** Ya está instalado (2.1.4), cumple la versión mínima recomendada (≥ 1.18.30), no necesita Node.js y habla directamente con la API de DeepSeek mediante API key. Evita instalar un segundo cliente.

**Alternativas descartadas.** DeepSeek Harness (`dsh`) es oficial, pero añade una interfaz web, un servidor local y más superficie de red que habría que caracterizar por separado. Para un experimento de 24 horas, OpenCode es la opción con menos variables nuevas.

**Límites.** OpenCode arranca por defecto un **servidor en segundo plano compartido** que posee la sesión y ejecuta las herramientas. Si no se usa `--standalone`, parte de la ejecución puede quedar fuera del namespace y la captura sería incompleta. El usuario confirma que el uso de DeepSeek no tiene límites para este proyecto; el coste por sesión se estima en el apartado 4.3 por si se usara API de pago.

**Verificación.** `opencode --version` → `2.1.4`; `opencode run --standalone "responde OK"` debe completar y generar tráfico a `api.deepseek.com`; `ss -tpn` dentro del ns debe mostrar el proceso dentro y no un servidor huérfano fuera.

### 3.5. Lo que no se ha podido verificar

| Afirmación | Estado | Por qué importa |
|---|---|---|
| Lista completa de hosts de OpenAI | **[NO VERIFICADO]** | Se construirá empíricamente en el piloto |
| OpenCode no envía telemetría propia | **[NO VERIFICADO]** | Se medirá y etiquetará; L-04 se analiza y deshabilita |
| Claude Code no usa DoH | **[NO VERIFICADO]** | Se detectará por SNI/destino en el piloto |
| Estabilidad del modelo por defecto entre sesiones | **[NO VERIFICADO]** | Se registra `model_reported`; puede cambiar |
| Hosts exactos de MCP si el agente inicia uno | **[NO VERIFICADO]** | Se etiquetan como `AGENT_TOOL_MCP` y se documentan |

Regla adoptada: **ninguna de estas lagunas se rellena por inferencia**. Se resuelven con una medición del piloto o quedan como limitación documentada.

---

## 4. Viabilidad económica con presupuesto 0 €

### 4.1. Principio

«0 €» significa **coste marginal cero para el proyecto**: software libre, datos propios y, como máximo, recursos que el usuario **ya posee y ya paga**. No significa «usar un servicio de pago sin pagarlo». Cualquier gasto nuevo requiere aprobación explícita y, por tanto, deja de cumplir la restricción.

### 4.2. Coste marginal por proveedor

| Proveedor | Vía de coste cero | Coste si no se cumple | Estado |
|---|---|---|---|
| OpenAI | Acceso confirmado por el usuario | Plus 20 USD/mes o API por uso | **Confirmado** |
| Anthropic | Acceso confirmado por el usuario | Pro 20 USD/mes | **Confirmado** |
| DeepSeek | Uso confirmado por el usuario | Recarga mínima + consumo | **Confirmado** |

### 4.3. Estimación de consumo para DeepSeek

Supuestos, no mediciones:

| Supuesto | Rango | Base |
|---|---|---|
| Tokens de entrada por sesión | 60 000 – 200 000 | Tarea corta con historial y resultados de herramientas |
| Tokens de salida por sesión | 3 000 – 15 000 | Respuestas y llamadas a herramientas |
| Precio entrada (cache miss) | 0,15 – 0,30 USD/M | Tarifa publicada, según franja |
| Precio salida | 0,60 – 1,20 USD/M | Tarifa publicada, según franja |
| Sesiones DeepSeek | 9 | 3 familias × 3 repeticiones |

Cálculo: `200 000 × 0,30/10⁶ + 15 000 × 1,20/10⁶ = 0,06 + 0,018 = 0,078 USD` por sesión en el peor caso. Nueve sesiones: **≈ 0,20 – 0,70 USD**. Es un orden de magnitud bajo, pero **no es 0 €**: exige saldo previo.

### 4.4. Conclusión económica

- El usuario ha confirmado que los tres clientes pueden usarse **sin límites** para este proyecto. La viabilidad económica deja de ser un bloqueo.
- La estimación de 4.3 se conserva como referencia de lo que costaría el mismo experimento con API de pago, no como gasto previsto.
- Si en el futuro cambia el acceso, hay dos salidas honestas: reducir el alcance a los proveedores viables y documentarlo, o aplazar la captura.
- **No se propone** crear cuentas nuevas, usar pruebas gratuitas de forma encubierta ni compartir credenciales: además de romper el presupuesto, introduce riesgo legal y de términos de servicio.

---

## 5. Arquitectura de aislamiento

### 5.1. Topología

Una sesión = un namespace = un veth = una captura.

```text
┌──────────────────────────── host (Kali) ────────────────────────────┐
│                                                                     │
│   nft table inet aigate_lab                                         │
│   (solo 10.203.0.0/16, solo mientras dura la sesión)                │
│                                                                     │
│   veth-h-s01 10.203.0.1/30 ────────┐                                │
│        │                            │                               │
│        │ tcpdump -i veth-h-s01      │  NAT / forward                │
│        │ (captura lado host)        │                               │
│        ▼                            ▼                               │
│   data/raw/<session>/<session>.pcap                       WAN ──────┼──► proveedor
│                                                                     │
│  ┌──────────────── ns: aigate-s01 ────────────────┐                 │
│  │                                                │                 │
│  │  veth-n-s01 10.203.0.2/30                      │                 │
│  │  default via 10.203.0.1                        │                 │
│  │  /etc/netns/aigate-s01/resolv.conf → 1.1.1.1   │                 │
│  │  IPv6 desactivado                              │                 │
│  │                                                │                 │
│  │  cliente de agente (codex | claude | opencode) │                 │
│  │  herramientas hijas (bash, python, git, ...)   │                 │
│  │  fixture local 10.203.0.1:8080 (host)          │                 │
│  └────────────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2. Network namespace + veth — qué, por qué, cómo, alternativas, límites, verificación

**Qué.** Un *network namespace* es una pila de red aislada: interfaces, rutas, tablas ARP, sockets y reglas propias. Un *veth* es un par de interfaces virtuales conectadas: lo que entra por un extremo sale por el otro.

**Por qué.** Permite atribuir **todo** el tráfico de una sesión a un agente concreto sin depender de la IP de origen ni de marcas en el host. Sin aislamiento, el tráfico de tres agentes y del navegador se mezcla y la etiqueta de sesión se vuelve una suposición. Además, permite limpiar el estado de red de una sesión sin reiniciar el host.

**Cómo.** Crear un ns por sesión, mover un extremo del veth dentro, asignar un `/30` distinto por sesión, poner la ruta por defecto hacia el extremo del host y ejecutar el cliente con `ip netns exec`.

**Alternativas.**

| Alternativa | Por qué no |
|---|---|
| Solo `bwrap` | Aísla el sistema de archivos, no la red; el tráfico sigue saliendo por la pila del host |
| `unshare -n` sin veth | Sin conectividad: el agente no puede hablar con el proveedor |
| Contenedor/Docker | Excluido por las restricciones del proyecto |
| VM dedicada | Más fiel, pero no hay infraestructura preparada y consume tiempo del presupuesto |
| Proxy obligatorio + iptables por UID | El agente puede ignorar el proxy; el marcado por UID es frágil con procesos hijos |

**Límites.** No aísla el sistema de archivos: el agente ve `$HOME`, incluidos los ficheros de credenciales. No impide que un proceso se comunique por sockets Unix con demonios del host. No separa el reloj ni el disco. Un proceso que se ejecute fuera del ns (por ejemplo, un servicio systemd activado por D-Bus) queda fuera de la captura.

**Verificación.** `ip netns exec <ns> ip addr` muestra solo `lo` y el veth; `ip netns exec <ns> ip route` muestra la ruta por defecto correcta; `ip netns pids <ns>` lista el cliente y sus hijos; `ss -tpn` dentro del ns no muestra conexiones del host.

### 5.3. DNS

**Qué.** El nombre debe resolverse dentro del ns, con un resolver visible en la captura.

**Por qué.** DNS es una de las señales deterministas más valiosas del dataset (destino, momento, patrón de reintentos). Si se usa el resolver del host con caché, la consulta puede no aparecer en el veth y se pierde la evidencia.

**Cómo.** `ip netns exec` monta `/etc/netns/<ns>/resolv.conf` sobre `/etc/resolv.conf` dentro del ns. Se escribe un resolver público (por ejemplo `1.1.1.1`) y se evita cualquier caché local.

**Alternativas.** Un resolver propio dentro del ns añade un proceso y una fuente de ruido. Un resolver en el host con `dnsmasq` cachea y oculta consultas. DoH/DoT del cliente no se puede impedir sin romper el cliente; se detecta y se etiqueta.

**Límites.** Si el cliente usa DoH, la consulta DNS clásica no aparece; solo se ve TLS al endpoint DoH. Si el resolver público falla, la sesión falla por una causa ajena al agente.

**Verificación.** `ip netns exec <ns> cat /etc/resolv.conf` muestra el resolver esperado; una consulta de prueba aparece en `dns.log` de Zeek y en el PCAP; no aparece ninguna consulta en el resolver del host.

### 5.4. IPv6

**Qué.** Desactivar IPv6 **dentro del ns**, no en el host.

**Por qué.** Si el ns tiene IPv6 (por ejemplo, autoconfiguración o ruta heredada), parte del tráfico puede salir por una ruta que no está NATeada ni capturada de forma equivalente, y la sesión se vuelve no reproducible. Además, Happy Eyeballs puede elegir IPv6 o IPv4 de forma distinta en cada repetición.

**Cómo.** `sysctl -w net.ipv6.conf.all.disable_ipv6=1` y `net.ipv6.conf.default.disable_ipv6=1` con `ip netns exec`, de modo que solo afecte al ns. No se asigna dirección IPv6 al veth.

**Alternativas.** Capturar IPv6 también y añadir NAT66: más fiel a una red real, pero duplica la complejidad y las variables. Dejarlo activado sin NAT66: rompe conectividad de forma intermitente, peor que desactivarlo.

**Límites.** Es una desviación deliberada respecto a una red doméstica real, donde IPv6 suele estar presente. Debe figurar como limitación: el dataset representa IPv4.

**Verificación.** `ip netns exec <ns> cat /proc/sys/net/ipv6/conf/all/disable_ipv6` → `1`; `ip -6 addr` dentro del ns solo muestra `lo` (o nada); el host conserva su valor original.

### 5.5. Herencia de procesos hijos

**Qué.** Todo proceso lanzado desde dentro del ns hereda el ns, salvo que algo lo saque explícitamente.

**Por qué.** Un agente no es un proceso: es un árbol. Si el cliente lanza un servidor en segundo plano que se re-parenta a `systemd` o se registra en D-Bus, ese proceso puede acabar en el ns del host y generar tráfico invisible.

**Cómo.** Lanzar el cliente con `ip netns exec`; usar modos que no deleguen en un servicio externo (`opencode run --standalone`); desactivar servicios de usuario y actualizadores; comprobar con `ip netns pids` y con `/proc/<pid>/ns/net` que todos los procesos del árbol comparten el mismo inodo de ns.

**Alternativas.** `nsenter` a posteriori es frágil y puede llegar tarde. Un `cgroup` con `nsproxy` fijo sería más robusto, pero añade complejidad y no está en el stack previsto.

**Límites.** Un proceso puede usar `setns()` para volver al ns del host si tiene privilegios; un cliente normal no lo hace, pero no se puede demostrar por completo sin auditoría del binario.

**Verificación.** Antes de cerrar la sesión: `ip netns pids <ns>` contiene todos los procesos del agente; ningún `codex`, `claude` u `opencode` aparece en `pgrep -a` del host; `ls -l /proc/<pid>/ns/net` coincide para padre e hijos.

### 5.6. Puntos de fuga

| ID | Fuga | Efecto | Mitigación | Verificación |
|---|---|---|---|---|
| L-01 | OAuth en navegador del host | Tráfico de autenticación fuera de la captura | Autenticar **antes** de la sesión, fuera del ns | No hay sesión de captura durante el login |
| L-02 | Autoactualizador del cliente | Descargas no atribuibles a la tarea | **Analizar y deshabilitar** (`DISABLE_AUTOUPDATER`, `DISABLE_UPDATES` donde exista) | Comparar tráfico con y sin la variable |
| L-03 | Servidor compartido de OpenCode | Ejecución y red fuera del ns | `opencode run --standalone` | `ip netns pids` y `ss -tpn` |
| L-04 | Telemetría (Datadog, Sentry, crash reporting) | Flujos auxiliares que contaminan | **Analizar y deshabilitar** con las variables oficiales | Conteo de destinos por sesión |
| L-05 | MCP servers y hooks iniciados por el agente | Llamadas a servicios de terceros | **Se consideran tráfico de agente** y se etiquetan `AGENT_TOOL_MCP`; no se configura MCP no solicitado | Lista de procesos y destinos |
| L-06 | DoH del cliente | DNS invisible | Detectar y etiquetar como `PROVIDER_AUX`/`UNKNOWN` | SNI y destinos en `ssl.log` |
| L-07 | IPv6 | Ruta no capturada | Desactivar dentro del ns | `disable_ipv6=1` |
| L-08 | `HTTP_PROXY`/`HTTPS_PROXY` heredados | Tráfico desviado a un proxy del host | Limpiar el entorno antes de `ip netns exec` | `env | grep -i proxy` vacío |
| L-09 | Keyring / D-Bus | Lectura de credenciales o prompts fuera del ns | Usar almacén en fichero si el cliente lo permite (`cli_auth_credentials_store = "file"` en Codex); nunca leerlo | El cliente arranca sin prompt de keyring |
| L-10 | Sockets Unix al host (X11, ssh-agent) | Canal lateral no capturado | No usar GUI ni agentes SSH en la sesión | `ss -x` antes y después |
| L-11 | Loopback del ns | Tráfico interno no visible en el veth | Captura opcional en `lo` dentro del ns | Comparar ambos PCAP |
| L-12 | Reloj/NTP | Marcas temporales inconsistentes | No hay NTP dentro del ns; se registra la hora del host | Diferencia PCAP vs. manifiesto |

**Nota importante sobre L-09:** el proyecto **no lee, copia ni registra** ficheros de credenciales. Solo se comprueba que el cliente arranca; el contenido de `~/.codex/auth.json` o `~/.claude/.credentials.json` queda fuera del alcance y nunca se incluye en Git ni en el dataset.

**Plan para L-02 y L-04.** Se medirán en el piloto en dos pasadas, con las variables de desactivación activas y sin ellas, y se comparará el conjunto de destinos. Si un cliente no ofrece un interruptor documentado, no se bloquea a ciegas: se etiqueta como `PROVIDER_AUX` o `AGENT_RUNTIME` y se registra en `anomalies`. El resultado se refleja en los campos `telemetry_disabled` y `autoupdate_disabled` del manifiesto.

**Sobre L-05.** Durante la captura no hay tráfico humano. Si el agente inicia un servidor MCP o una herramienta externa, ese flujo forma parte de la sesión y se etiqueta `AGENT_TOOL_MCP`; no se trata como ruido ni como `UNKNOWN`. Lo que no se hace es atribuirlo al modelo: se sabe que lo inició el agente, no qué byte generó el modelo.

### 5.7. Colocación de la captura

**Qué.** Un único punto de captura principal: el extremo **host** del veth.

**Por qué.** Todo el tráfico del ns pasa obligatoriamente por ese extremo. Capturar ahí ve direcciones pre-NAT, es decir, la identidad real de la sesión (`10.203.x.2`), y evita duplicar paquetes. Capturar dentro del ns vería lo mismo, pero añadiría un proceso más dentro del entorno medido y podría alterar el comportamiento.

**Cómo.** `tcpdump -i veth-h-s01 -n -s 0 -w <session>.pcap`. Sin filtro BPF, para no excluir evidencia por error.

**Alternativas.** `dumpcap` escribe pcapng y puede ser preferible si se necesita metadata de interfaz; tcpdump es suficiente y ya está validado. Capturar en el WAN daría la vista post-NAT, pero mezclaría todo el tráfico del host.

**Límites.** No ve loopback del ns, ni sockets Unix, ni tráfico que no cruce el veth. No ve el interior de TLS.

**Verificación.** El PCAP contiene el handshake de la sesión; `tcpdump -nr` muestra la IP `10.203.x.2` como origen; el número de paquetes es mayor que cero; `capinfos`/`tshark -q -z io,stat` confirma un rango temporal coherente con el manifiesto.

### 5.8. Forwarding y NAT

**Qué.** El host debe reenviar paquetes del ns y aplicar masquerade solo al rango del laboratorio.

**Por qué.** Sin forwarding, el ns no sale. Sin NAT, el proveedor no sabría devolver la respuesta, porque `10.203.0.0/16` no es enrutable en Internet.

**Cómo.** Guardar el valor actual de `ip_forward`, activarlo, crear una tabla nftables propia y una regla de masquerade limitada al prefijo del laboratorio y a la interfaz WAN detectada en tiempo de ejecución. No se tocan las tablas existentes del host.

**Alternativas.** NAT a nivel de aplicación (proxy) cambia el tráfico y complica la atribución. `slirp4netns` evitaría privilegios, pero no está confirmado en el equipo y añade una pila de usuario distinta.

**Riesgos.** (1) Dejar `ip_forward=1` tras la sesión cambia el comportamiento del host. (2) Una regla de masquerade demasiado amplia afectaría a otras redes. (3) Una política `drop` en otra tabla nftables puede anular el `accept` del laboratorio, porque en nftables gana el drop. (4) `conntrack` retiene estado tras cerrar el ns.

**Verificación y rollback.**

```bash
# Antes: registrar el estado exacto (no suponer que es 0)
PREV_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
nft list tables

# Después: comprobar que no queda nada
cat /proc/sys/net/ipv4/ip_forward   # debe coincidir con $PREV_FORWARD
nft list tables                     # no debe aparecer inet aigate_lab
ip netns list                       # no debe aparecer aigate-s01
ip -br link | grep veth             # sin veth huérfano
ip netns pids aigate-s01            # vacío antes de borrar
```

`scripts/lab_session.sh` automatiza exactamente esto: guarda `PREV_FORWARD` en un fichero de estado y restaura ese valor, no un `0` supuesto.

Orden de limpieza: matar procesos del ns → borrar la tabla nftables → restaurar `ip_forward` → `ip netns del` (elimina también el extremo del veth) → verificar.

**Regla de seguridad.** Si cualquier verificación posterior falla, la sesión se marca como **inválida** y no entra en el dataset. No se «arregla» a posteriori.

**Guarda de ejecución:** si `WAN_IF` está vacío (sin ruta por defecto IPv4), el script debe abortar antes de crear reglas. Una regla de masquerade sin interfaz de salida puede aplicarse a tráfico no previsto.

### 5.9. Por qué no se usa el aislamiento propio de los clientes como sustituto

Codex y Claude aplican sandbox de sistema de archivos y, en algunos modos, de red. Ese sandbox es útil, pero **no es un instrumento de medida**: no garantiza un punto único de captura, no separa sesiones y su configuración cambia entre versiones. Se usa el sandbox del cliente como defensa en profundidad, no como metodología.

---

## 6. Diseño de la captura

### 6.1. Estructura de ficheros

```text
data/
├── raw/
│   └── 20261120T101500Z-openai-codex-f1-r1/
│       ├── session.pcap
│       ├── loopback.pcap            # opcional, solo si se usa servidor local
│       ├── capture.meta.json        # parámetros reales de tcpdump
│       ├── tcpdump.log              # resumen de paquetes y descartes
│       ├── command.stdout           # salida del cliente
│       ├── command.stderr           # errores del cliente
│       └── stop_reason              # solo si la captura se cortó antes
├── processed/
│   └── 20261120T101500Z-openai-codex-f1-r1/
│       └── zeek/
│           ├── conn.log
│           ├── dns.log
│           ├── http.log
│           ├── ssl.log
│           ├── files.log
│           ├── x509.log
│           ├── weird.log
│           └── notice.log
├── manifests/
│   └── 20261120T101500Z-openai-codex-f1-r1.yaml
└── work/
    └── 20261120T101500Z-openai-codex-f1-r1/   # copia de fixtures/workspace
```

`data/raw/`, `data/manifests/` y `data/work/` están ignorados por Git salvo `.gitkeep`. Los PCAP **no se publican**.

`capture.meta.json` registra el hash del comando, no su texto: un comando puede contener una ruta con un nombre de usuario o una credencial pasada por error. El texto de la tarea vive en `fixtures/prompts/` y se identifica por su SHA-256.

### 6.2. Parámetros

| Parámetro | Valor propuesto | Justificación |
|---|---|---|
| Interfaz | `veth-h-<id>` | Punto único de paso |
| Snaplen | `0` (completo) | No truncar SNI ni certificados; el PCAP no sale del host |
| Filtro BPF | ninguno | Evitar exclusiones accidentales; el volumen es pequeño |
| Precisión temporal | nanosegundos | Coherencia con el manifiesto (`--time-stamp-precision=nano`) |
| Rotación | un fichero por sesión; límite de seguridad 512 MB | Sesiones cortas; el límite evita llenar el disco |
| Duración máxima | 15 min por sesión | Acota coste y varianza |
| Timeout de inactividad | 120 s sin crecimiento del PCAP | Detecta cuelgues del cliente |
| Captura de loopback | opcional, segundo fichero | Solo si el cliente abre un servidor local |

El piloto confirmó que `-s 0` produce una longitud de snapshot de 262144 bytes (el máximo de tcpdump 4.99), suficiente para conservar SNI y certificados. La captura de humo generó 32 paquetes con 0 descartes del kernel.

El script `scripts/lab_session.sh` implementa la creación y el borrado del laboratorio con `trap`, guardado de `ip_forward` y verificación final. La captura se lanza aparte y nunca forma parte de `up`.

El script `scripts/capture_session.sh` implementa la captura y el manifiesto:

- Arranca `tcpdump` con `-s 0` y precisión de nanosegundos.
- Copia `fixtures/workspace/` a `data/work/<session_id>/` para que todos los agentes partan del mismo estado.
- Ejecuta el comando indicado tras `--` dentro del namespace, con los proxies heredados borrados.
- Aplica `--max-duration`, `--idle-timeout` y `--max-bytes`; si se alcanza un límite, escribe `stop_reason` y marca `timeout_hit`.
- Comprueba que el PCAP es legible, calcula su SHA-256 y escribe `capture.meta.json` y el manifiesto YAML.
- Emite el manifiesto con `valid: false` e `invalidation_reason: pending-review`: la validez experimental no la decide el script.

El campo `bytes` del manifiesto es el **tamaño del fichero PCAP**, no la suma de bytes en el cable. `capture.meta.json` lo declara con `"bytes_kind": "pcap_file_size"` para evitar ambigüedad.

### 6.3. Zeek — qué, por qué, cómo, alternativas, límites, verificación

**Qué.** Zeek convierte paquetes en registros estructurados por conexión y por protocolo (`conn`, `dns`, `http`, `ssl`, `files`, `x509`, `weird`).

**Por qué.** Es el analizador principal del proyecto. Separar captura (tcpdump) de análisis (Zeek) permite reprocesar el mismo PCAP con otra versión de Zeek o con otros scripts sin volver a generar tráfico, algo esencial cuando cada sesión cuesta dinero o requiere autenticación manual.

**Cómo.** `cd` al directorio de salida y `zeek -r <ruta absoluta al pcap> local`. Zeek escribe en el directorio de trabajo; así se evita depender de una variable de configuración.

**Alternativas.** TShark puede extraer campos concretos, pero no produce un modelo de conexiones tan completo. CICFlowMeter está descartado salvo necesidad justificada.

**Límites.** Zeek no ve el interior de TLS. `ssl.log` aporta SNI, versión, JA3 y certificado, no el prompt ni la respuesta. Con QUIC/HTTP3 algunos flujos pueden quedar peor caracterizados; se detectará en el piloto.

**Verificación.** `conn.log` no está vacío; el número de conexiones es coherente con `tshark -q -z conv,tcp`; `dns.log` contiene las consultas esperadas; `weird.log` se revisa y se documenta si aparece algo relevante.

### 6.4. Integridad

Cada PCAP y cada manifiesto llevan `sha256`. El hash se calcula al cerrar la sesión y se escribe en el manifiesto y en `capture.meta.json`. Si el PCAP se reprocesa, el hash debe coincidir; si no, la sesión se invalida. El manifiesto también registra el hash del prompt y el del fixture, de modo que un cambio de texto o de estado inicial se detecta sin publicar el texto.

### 6.5. Privacidad

| Dato | Riesgo | Tratamiento |
|---|---|---|
| PCAP completo | Contiene IPs, SNI, DNS, certificados | Nunca se publica; `data/raw/` ignorado |
| Logs Zeek | Contienen IPs y SNI | No se publican en crudo |
| Manifiesto | Puede contener rutas y usuario | Se revisa; sin tokens, correos ni rutas absolutas |
| Credenciales | Nunca se leen | Fuera de alcance por diseño |
| Prompts | Pueden contener datos personales | Solo se guarda su hash y una descripción; el texto vive en `fixtures/` del repo si es propio |

Regla: se puede publicar **esquema, manifiestos saneados y estadísticas agregadas**. No se publica PCAP ni log crudo.

---

## 7. Escenarios positivos

### 7.1. Diseño factorial

Tres familias × tres agentes × tres repeticiones = **27 sesiones positivas**.

| Familia | Nombre | Tarea | Herramientas | Tráfico esperado |
|---|---|---|---|---|
| F1 | Consulta y síntesis | Resumir un fichero local de 1–2 KB en 5 viñetas | Lectura de fichero | Pocas llamadas al proveedor, sin salidas a Internet |
| F2 | Inspección y edición | Encontrar un fallo en un módulo pequeño, corregirlo y ejecutar un test | `grep`, editor, `python` | Varias llamadas, ráfagas, tráfico del intérprete |
| F3 | Tarea multi-paso con fixture | Consultar un servicio HTTP local, transformar el resultado y escribir un informe | `curl`/`requests`, ficheros | Llamadas al proveedor + tráfico al fixture local |

**Por qué estas tres.** Cubren tres regímenes distintos: mínimo (F1), interactivo con herramientas (F2) y mixto con destino adicional controlado (F3). Permiten separar «tráfico del proveedor» de «tráfico de herramientas» sin contactar terceros.

**Por qué un fixture local.** F3 necesita un destino que no sea el proveedor para estudiar el tráfico de herramientas. Un servicio en `10.203.0.1:8080` es reproducible, está capturado en el veth y no requiere autorización de terceros.

### 7.2. Equidad entre agentes

- Mismo texto de tarea, misma temperatura conceptual (la que permita cada cliente), mismo límite de turnos y mismo timeout.
- Mismo fixture, mismo commit del repositorio de trabajo y mismo estado inicial.
- Se registran las diferencias que no se pueden igualar: modelo por defecto, política de reintentos, streaming, formato de herramientas.

**Confusores declarados:** el modelo, el cliente, la política de red del cliente y el plan contratado varían a la vez. Por eso el dataset **no** permite atribuir una diferencia observada a «OpenAI vs. Anthropic»; solo a «esta combinación cliente+modelo+plan en esta fecha».

### 7.3. Plantilla de prompt

Cada familia tiene un fichero en `fixtures/prompts/<familia>.txt`, versionado y hasheado. El prompt no se improvisa en la sesión: si se cambia, cambia el hash y la sesión es otra.

Los textos concretos están en `fixtures/prompts/f1.txt`, `f2.txt` y `f3.txt`. F1 y F2 trabajan sobre `fixtures/workspace/`, que se copia a `data/work/<session_id>/` antes de cada sesión. F3 consulta el servidor local `fixtures/fixture_server.py` en `http://10.203.1.1:8080/data`; por eso las sesiones F3 usan siempre el índice de subred 1 y el script de captura rechaza otro índice.

### 7.4. Orden de ejecución

Primero el **piloto**: 3 sesiones (una por agente, familia F2). Sirve para descubrir hosts reales, medir duración, validar el aislamiento y ajustar timeouts. Después, las 24 restantes. Si el piloto invalida un supuesto (por ejemplo, el cliente abre un servidor local inesperado), se corrige el diseño antes de gastar las 24 sesiones.

---

## 8. Controles negativos

Obligatorios. Sin ellos, un clasificador puede aprender «hay tráfico» en lugar de «hay agente».

| ID | Control | Duración | Qué aísla | Etiqueta |
|---|---|---|---|---|
| N-01 | Namespace en reposo, sin procesos | 5 min | Ruido base, ARP, NDP | `BACKGROUND_NOISE` |
| N-02 | Solo DNS: `dig` a los tres hosts | 2 min | Resolución sin TLS | `NON_AGENT_REFERENCE_SESSION` |
| N-03 | Solo TLS: `curl -I`/`openssl s_client` a los tres hosts | 3 min | Handshake sin agente | `NON_AGENT_REFERENCE_SESSION` |
| N-04 | Automatización no-IA: `curl` al fixture + script Python | 5 min | Automatización convencional | `AUTOMATION_NON_AI` |
| N-05 | Humano ejecutando los mismos comandos que N-04 | 5 min | Referencia humana sin agente | `HUMAN_REFERENCE` |
| N-06 | Cliente instalado pero inactivo (sin prompt) | 10 min | Heartbeat, telemetría, update check | `CLIENT_RUNTIME_IDLE` |
| N-07 | Gestor de paquetes dentro del ns (opcional) | 5 min | Ruido de fondo realista | `BACKGROUND_NOISE` |

**N-06 es el control más valioso.** Separa el tráfico «de estar instalado» del tráfico «de ejecutar una tarea». Sin él, un modelo podría aprender la firma de telemetría del cliente y llamarlo detección de agente.

**Por qué `CLIENT_RUNTIME_IDLE` es una etiqueta propia.** El usuario quiere poder bloquear ese tráfico por separado o habilitarlo de forma explícita en el firewall. Si se mezclara con `NON_AGENT_REFERENCE_SESSION`, una regla de política no podría distinguir «referencia humana» de «cliente de IA en reposo». La etiqueta es de sesión y se mapea a la taxonomía canónica de cinco clases en los informes: `CLIENT_RUNTIME_IDLE` describe tráfico de un cliente de IA que no está ejecutando una tarea, no tráfico de un agente activo.

**N-03 es el control más honesto.** Demuestra cuánto de la señal es simplemente «conexión TLS a un proveedor de IA», que es exactamente lo que AIGate no quiere confundir con un agente.

---

## 9. Etiquetado y procedencia

### 9.1. Dos niveles, nunca uno

| Nivel | Unidad | Etiqueta | Cómo se obtiene |
|---|---|---|---|
| Sesión | Una ejecución completa | `AGENT_ASSOCIATED_SESSION`, `NON_AGENT_REFERENCE_SESSION`, `AUTOMATION_NON_AI`, `HUMAN_REFERENCE`, `BACKGROUND_NOISE`, `CLIENT_RUNTIME_IDLE` | Diseño experimental: se sabe qué se lanzó |
| Flujo | Una conexión de `conn.log` | `PROVIDER_API`, `PROVIDER_AUX`, `TOOL_LOCAL`, `AGENT_TOOL_MCP`, `AGENT_RUNTIME`, `UNKNOWN_IN_SESSION` | Reglas por destino y ventana temporal, versionadas |

**Mapeo a la taxonomía canónica del proyecto.** Las etiquetas de sesión son más finas que las cinco clases del prompt maestro; no las sustituyen:

| Etiqueta de sesión | Clase canónica | Uso de política |
|---|---|---|
| `AGENT_ASSOCIATED_SESSION` | `AGENT_ASSOCIATED_TRAFFIC` | `ALLOW`/`ALERT` según regla |
| `CLIENT_RUNTIME_IDLE` | `UNKNOWN` (subclase con hook propio) | `BLOCK` o `ALLOW` independiente, a decisión del usuario |
| `NON_AGENT_REFERENCE_SESSION` | `UNKNOWN` | Referencia, no bloqueable por sí sola |
| `AUTOMATION_NON_AI` | `AUTOMATION_NON_AI` | `ALLOW`/`ALERT` |
| `HUMAN_REFERENCE` | `HUMAN_REFERENCE` | `ALLOW` |
| `BACKGROUND_NOISE` | `UNKNOWN` | `ALLOW` |

`CLIENT_RUNTIME_IDLE` no es «tráfico de agente activo» ni «tráfico de IA genérico»: es el tráfico de un cliente de IA instalado que no está ejecutando una tarea. Por eso se puede bloquear sin afectar a las sesiones positivas.

### 9.2. Reglas de procedencia

`labelling_rules_version = 1`

1. `PROVIDER_API`: destino ∈ conjunto de hosts del proveedor, puerto 443/80, dentro de la ventana de la sesión.
2. `PROVIDER_AUX`: destino ∈ hosts auxiliares documentados (telemetría, CDN, actualización, auth).
3. `TOOL_LOCAL`: destino = `10.203.0.1` (fixture).
4. `AGENT_TOOL_MCP`: flujo iniciado por el agente hacia un servidor MCP o herramienta externa, dentro de la ventana de la sesión. Se identifica por proceso y destino, no por contenido.
5. `AGENT_RUNTIME`: proceso del cliente pero destino no clasificado como API/AUX (por ejemplo, un endpoint no documentado).
6. `UNKNOWN_IN_SESSION`: cualquier flujo restante. **No se fuerza una etiqueta**.

Los conjuntos de hosts se construyen **empíricamente en el piloto** y se congelan por versión. Un host nuevo en una sesión posterior no se reclasifica retroactivamente: se marca `UNKNOWN_IN_SESSION` y se documenta.

### 9.3. Lo que el etiquetado no permite afirmar

- **No** hay atribución por paquete. Un flujo es «asociado a la sesión del agente», no «generado por el modelo».
- **No** se puede afirmar que un flujo a `api.openai.com` durante una sesión de Claude sea de OpenAI: puede ser un MCP, un proxy o una extensión. Se etiqueta por destino y se declara la ambigüedad.
- **No** se usa el destino, la IP, el SNI ni el timestamp como predictor. Serían *leakage*: el modelo aprendería la etiqueta mirando la respuesta.
- **Sí** se afirma que un flujo `AGENT_TOOL_MCP` fue iniciado por el agente, porque no hay tráfico humano durante la captura y el proceso se puede observar dentro del namespace.

### 9.4. Por qué el etiquetado por destino es legítimo para evaluar y no para predecir

Para **evaluar**, el destino es un oráculo aceptable: sabemos a qué host se conectó la sesión y podemos comprobar si el clasificador lo acierta. Para **predecir**, usar ese mismo destino como entrada es circular. La separación se implementa en la Entrega 4: las features excluyen IP, puerto, SNI y nombres de host.

---

## 10. Esquema de manifiesto

### 10.1. Formato y validación

YAML 1.2, un fichero por sesión en `data/manifests/<session_id>.yaml`. El esquema está en `src/aigate/capture/manifest-v1.schema.json` (JSON Schema, Draft 2020-12) y se valida con `jsonschema` + PyYAML en `src/aigate/capture/manifest.py`.

`jsonschema` **no añade una dependencia nueva**: la versión `4.26.0` ya estaba fijada en `requirements.txt` como dependencia transitiva, y está instalada en `.venv`. Se usa porque aporta algo que un validador manual no da: un contrato declarativo reutilizable por CI y por herramientas externas, errores que señalan la ruta exacta del fallo y la posibilidad de validar manifiestos sin importar el paquete. La alternativa —una función con `if` dispersos— se desvía del documento y no es reutilizable.

El esquema usa `additionalProperties: false`: cualquier campo nuevo exige subir la versión. Los tests `tests/unit/test_manifest.py` cubren manifiesto válido, campo obligatorio ausente, proveedor inválido, etiqueta inválida, sesión inválida, conteo negativo, credenciales y carga desde YAML.

**Distinción importante:** que un manifiesto sea válido para el esquema **no** significa que la sesión sea válida como experimento. `valid: false` es un valor permitido por el esquema; la validez experimental la decide la lista de comprobaciones.

### 10.2. Campos

| Grupo | Campos |
|---|---|
| Identidad | `manifest_version`, `session_id`, `created_at_utc`, `phase`, `operator` |
| Escenario | `scenario_family`, `repetition`, `task_prompt_sha256`, `fixture_id`, `fixture_sha256` |
| Agente | `agent_provider`, `agent_client`, `client_version`, `model_requested`, `model_reported`, `auth_mode`, `plan` |
| Entorno | `host_os`, `kernel`, `arch`, `python_version`, `zeek_version`, `tcpdump_version` |
| Red | `netns`, `veth_host`, `veth_ns`, `host_ip`, `ns_ip`, `dns_resolver`, `ipv6_disabled`, `mtu` |
| Captura | `pcap_file`, `pcap_sha256`, `snaplen`, `bpf_filter`, `started_at_utc`, `ended_at_utc`, `packets`, `bytes` |
| Zeek | `zeek_logdir`, `zeek_scripts`, `logs_sha256` |
| Ejecución | `exit_code`, `duration_s`, `turns`, `timeout_hit`, `success` |
| Controles | `telemetry_disabled`, `autoupdate_disabled`, `standalone_mode`, `proxy_env_cleared` |
| Etiquetas | `session_label`, `labelling_rules_version`, `flow_provenance_counts` |
| Calidad | `anomalies`, `valid`, `invalidation_reason` |
| Privacidad | `contains_credentials: false`, `publishable: false` |

### 10.3. Ejemplo

```yaml
manifest_version: 1
session_id: 20261120T101500Z-openai-codex-f1-r1
created_at_utc: "2026-11-20T10:15:00Z"
phase: pilot
operator: local
scenario_family: F1
repetition: 1
task_prompt_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

agent_provider: openai
agent_client: codex-cli
client_version: "0.170.0"
model_requested: default
model_reported: "pending-capture"
auth_mode: chatgpt_subscription
plan: free-or-existing

host_os: "Kali Rolling 2026.3"
kernel: "7.1.5+kali-amd64"
arch: x86_64
python_version: "3.14.8"
zeek_version: "9.0.1"
tcpdump_version: "4.99.6"

netns: aigate-s01
veth_host: veth-h-s01
veth_ns: veth-n-s01
host_ip: 10.203.1.1/30
ns_ip: 10.203.1.2/30
dns_resolver: 1.1.1.1
ipv6_disabled: true
mtu: 1500

pcap_file: data/raw/20261120T101500Z-openai-codex-f1-r1/session.pcap
pcap_sha256: null
snaplen: 0
bpf_filter: none
started_at_utc: "2026-11-20T10:15:03Z"
ended_at_utc: "2026-11-20T10:16:41Z"
packets: null
bytes: null

zeek_logdir: data/processed/20261120T101500Z-openai-codex-f1-r1/zeek
zeek_scripts: local
logs_sha256: null

exit_code: null
duration_s: null
turns: null
timeout_hit: false
success: null

telemetry_disabled: unknown
autoupdate_disabled: true
standalone_mode: not_applicable
proxy_env_cleared: true

session_label: AGENT_ASSOCIATED_SESSION
labelling_rules_version: 1
flow_provenance_counts: {}

anomalies: []
valid: false
invalidation_reason: "design-only example"

contains_credentials: false
publishable: false
```

Los valores `null`, `pending` y `false` son deliberados: un manifiesto de ejemplo **no** debe parecer una sesión válida.

### 10.4. Por qué manifiesto y no solo nombre de fichero

El nombre de fichero codifica cuatro cosas y no cabe más. El manifiesto registra el estado real del entorno, que es lo que permite distinguir un resultado de un artefacto. Sin él, en dos semanas nadie sabrá si una captura se hizo con IPv6 activo o con telemetría encendida.

---

## 11. Dataset externo complementario

### 11.1. Dataset seleccionado: ISCXVPN2016 (Non-VPN)

**Decisión D-019.** Se selecciona **ISCXVPN2016 (VPN-nonVPN, UNB/CIC)** como dataset externo principal, utilizando inicialmente **solo el subconjunto Non-VPN**. Sustituye a la propuesta anterior, que queda rechazada.

| Atributo | Valor verificado en la página oficial |
|---|---|
| Nombre | VPN-nonVPN dataset (ISCXVPN2016) |
| Origen | Canadian Institute for Cybersecurity, University of New Brunswick |
| Contenido | Tráfico de aplicaciones: navegación, correo, chat, streaming, transferencia de ficheros, VoIP y P2P |
| Categorías | 14 (cada tipo en versión normal y versión VPN) |
| Formato | PCAP completo y CSV generado con ISCXFlowMeter |
| Tamaño total | 28 GB |
| Captura | Wireshark y tcpdump; VPN con OpenVPN en modo UDP |
| Etiquetas | Tipo de aplicación y VPN/non-VPN; **no** hay etiqueta de agente de IA |
| Acceso | Formulario de descarga con datos personales; público para investigación |
| Cita obligatoria | Gil, Lashkari, Mamun y Ghorbani, ICISSP 2016 |

### 11.2. Papel en AIGate

**No es un conjunto de datos de agentes.** Se usa como:

1. **Referencia externa de «no agente»**: tráfico de aplicaciones reales que no son agentes de IA.
2. **Contraste de dominio**: comprobar si el pipeline y las features se comportan de forma razonable fuera de nuestro laboratorio.
3. **Prueba de generalización**: detectar si el modelo aprendió artefactos de nuestro entorno (por ejemplo, un SNI concreto) en lugar de patrones de comportamiento.

**Lo que no se hace:** entrenar con él como positivo de agente, mezclarlo con `data/raw/`, ni presentarlo como tráfico humano real. Fue generado en laboratorio con cuentas Alice/Bob y tareas guionizadas.

### 11.3. Subconjunto Non-VPN y muestreo

- Se descarga **solo Non-VPN**, no las capturas VPN.
- El total sigue siendo grande; no se procesa entero. Se selecciona una **muestra estratificada por categoría**, con un tope de bytes documentado y un hash de la lista de ficheros elegidos.
- La selección se hace antes de mirar resultados, para no sesgar la muestra.
- Cada captura externa se procesa con la misma versión de Zeek y se marca con `source: external` en el índice. No se le asigna `session_label` de agente; se etiqueta como `EXTERNAL_NON_AGENT` en el índice del dataset externo, fuera del esquema de sesiones propias.

### 11.4. Acceso, licencia y límites

- La descarga exige rellenar un formulario con nombre, correo, organización, cargo y país. **El proyecto no lo automatiza ni lo rellena**: la solicitud la hace el usuario. No se raspa ni se busca un espejo no oficial.
- La licencia permite uso para investigación con citación. No se redistribuye el corpus.
- **Límites declarados:** no comparte la etiqueta objetivo; el tráfico es de 2016 y las aplicaciones han cambiado; las IPs y dominios están anonimizados o son antiguos; el comportamiento de TLS y de los clientes no es el actual; y la captura se hizo con un filtro por IP del cliente, lo que puede excluir tráfico auxiliar.
- Por todo ello, **ninguna conclusión sobre agentes se extrae de este dataset**. Solo se usa como contraste.

### 11.5. Candidatos descartados

| Dataset | Motivo del descarte |
|---|---|
| CIC-IDS2017 | Su tráfico benigno es sintético (B-Profile, 25 usuarios abstractos) y su etiqueta es ataque/benigno, no agente/no-agente. |
| MAWI | Un fichero de 15 min ocupa ~71 GB sin comprimir / ~20 GB gz, sin etiquetas de agente. No cabe en el presupuesto. |
| UNIBS | No se pudo verificar la página ni el tamaño/licencia durante la investigación. |
| Wireshark SampleCaptures | Útiles solo para pruebas de parser, no como datos experimentales. |

---

## 12. Viabilidad temporal

### 12.1. Presupuesto

24 horas efectivas, una persona, tres semanas a 8 h/semana.

| Sub-entrega | Trabajo | Horas |
|---|---|---|
| 3.1 | Investigación, diseño, este documento, actualización de docs | 5 |
| 3.2 | Laboratorio, scripts, manifiesto, piloto de 3 sesiones | 5 |
| 3.3 | 24 sesiones restantes + controles negativos | 7 |
| 3.4 | Zeek, exploración, calidad y muestra externa ISCXVPN2016 | 5 |
| 3.5 | Dataset Card, cierre documental | 2 |
| **Total** | | **24** |

No hay colchón. La regla de prioridad es explícita: si 3.2 o 3.3 se desvían, se recorta la **muestra externa** o se aplica el plan A; nunca se recortan en silencio las sesiones positivas ni los controles negativos.

### 12.2. Estimación por sesión

| Fase | Minutos | Nota |
|---|---|---|
| Crear ns, veth, DNS, IPv6, NAT | 3 | Automatizable |
| Verificar aislamiento | 2 | Lista de comprobación |
| Arrancar captura y cliente | 2 | Manual si hay login |
| Ejecutar tarea | 3–10 | Depende del proveedor |
| Cerrar, hashear, limpiar | 4 | Crítico |
| **Total** | **14–21** | |

27 sesiones × ~18 min ≈ 8 h en modo manual. Con los scripts de 3.2 el coste por sesión debería bajar a ~10–15 min (creación y limpieza automatizadas), lo que deja las 24 sesiones de 3.3 más los controles dentro de 7 h. Si no baja, se aplica el plan A antes de seguir consumiendo presupuesto.

### 12.3. Plan de repliegue

| Escenario | Sesiones | Condición | Justificación |
|---|---|---|---|
| Base | 27 (3×3×3) | Todo viable | Diseño completo |
| A | 18 (3×3×2) | Coste real por sesión > 25 min | Mantiene los tres proveedores y las tres familias; pierde una repetición, se declara |
| B | 9 (3×3×1) + controles | Un proveedor inviable a 0 € o un cliente no se puede aislar | Se mantiene la comparación mínima; se declara como limitación |
| C | 0 positivas | Ningún proveedor viable a 0 € | Se entrega diseño + controles negativos + análisis; el dataset positivo se aplaza |

Cualquier reducción se aprueba antes de ejecutarla y se registra en el Dataset Card como limitación explícita. **No se reduce en silencio.**

---

## 13. Riesgos y mitigaciones

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| R-01 | Anthropic no es viable sin suscripción | Resuelto | — | Uso confirmado por el usuario (D-013) |
| R-02 | DeepSeek requiere saldo | Resuelto | — | Uso confirmado por el usuario (D-013) |
| R-03 | Codex no disponible en el plan actual | Resuelto | — | Instalado y verificado (`0.170.0`) |
| R-04 | Login OAuth imposible dentro del ns | Alta | Medio | Autenticar antes, fuera de la captura |
| R-05 | Fuga de tráfico fuera del ns | Media | Alto | Lista L-01…L-12 + verificación antes/después |
| R-06 | `ip_forward` queda activo | Baja | Alto | Guardar/restaurar + comprobación final |
| R-07 | Regla NAT demasiado amplia | Baja | Alto | Prefijo `/16` dedicado + tabla propia |
| R-08 | Cliente actualiza durante la sesión | Media | Medio | Desactivar; si ocurre, etiquetar `PROVIDER_AUX` |
| R-09 | Modelo cambia entre repeticiones | Alta | Medio | Registrar `model_reported`; no prometer estabilidad |
| R-10 | Rate limit o error del proveedor | Media | Medio | Reintento documentado; sesión inválida si no completa |
| R-11 | PCAP contiene datos sensibles | Media | Alto | No publicar; solo agregados |
| R-12 | Se contacta un tercero no autorizado | Baja | Alto | Solo proveedor + fixture local; revisar destinos |
| R-13 | Tiempo insuficiente | Media | Medio | Piloto + plan de repliegue aprobado |
| R-14 | Etiqueta de flujo errónea | Media | Medio | Reglas versionadas + `UNKNOWN_IN_SESSION` |
| R-15 | Conclusiones sobreextendidas | Alta | Alto | Redactar límites antes de ver resultados |
| R-16 | ISCXVPN2016 no se descarga o el formulario falla | Media | Medio | Es opcional para el núcleo; se documenta si no se obtiene |
| R-17 | La muestra externa consume más tiempo que el previsto | Media | Medio | Tope de bytes y recorte de la muestra, no de las sesiones propias |

**Sobre R-15.** El riesgo más probable no es técnico: es escribir «los agentes de OpenAI se comportan así» cuando lo observado es «Codex CLI 0.170.0 con este plan, este día y esta tarea». El Dataset Card debe repetirlo.

---

## 14. Decisiones aceptadas

Las propuestas P-01…P-08 y P-10 fueron aceptadas por el usuario el 2026-11-18, con las condiciones indicadas. P-09 fue **rechazada** y sustituida por ISCXVPN2016 Non-VPN (D-019). El registro formal está en `docs/DECISIONS.md` (D-013…D-020).

| ID | Decisión | Estado | Condición incorporada |
|---|---|---|---|
| P-01 | Codex CLI, Claude Code y OpenCode como clientes | Aceptada (D-013) | Uso sin límites confirmado por el usuario |
| P-02 | Un netns + veth por sesión | Aceptada (D-014) | Implementada en `scripts/lab_session.sh` |
| P-03 | Captura en el extremo host del veth, snaplen 0, sin BPF | Aceptada (D-014) | Validada con 32 paquetes de humo |
| P-04 | DNS público en `/etc/netns/<ns>/resolv.conf` | Aceptada (D-015) | Verificado dentro del ns |
| P-05 | IPv6 desactivado dentro del ns | Aceptada (D-015) | Verificado con `disable_ipv6=1` |
| P-06 | 27 sesiones + 7 controles negativos | Aceptada (D-016) | Nueva etiqueta `CLIENT_RUNTIME_IDLE` para N-06 |
| P-07 | Etiqueta de sesión + procedencia de flujo, sin atribución por paquete | Aceptada (D-017) | MCP iniciado por el agente = `AGENT_TOOL_MCP` |
| P-08 | Manifiesto YAML v1 en `data/manifests/` | Aceptada (D-018) | JSON Schema + `jsonschema`, ya disponible |
| P-09 | Sin dataset externo para entrenar; solo smoke tests | **Rechazada** | Sustituida por ISCXVPN2016 Non-VPN (D-019) |
| P-10 | PCAP privado; publicar solo agregados y manifiestos saneados | Aceptada (D-020) | Sin cambios |

### 14.1. Condiciones de las decisiones L-02, L-04 y L-05

- **L-02 (autoactualizador)** y **L-04 (telemetría)**: se analizan y se deshabilitan con las variables oficiales. Se comparan dos pasadas en el piloto y se registra el resultado en el manifiesto.
- **L-05 (MCP)**: si el agente inicia un MCP o una herramienta externa durante la captura, ese tráfico es parte de la sesión y se etiqueta `AGENT_TOOL_MCP`. No hay tráfico humano que lo justifique de otra forma.
- **Resto de L**: se mantienen las mitigaciones recomendadas en §5.6.

---

## 15. Estado de la sub-entrega 3.2

**En curso.** La infraestructura, el script de captura y los fixtures están implementados y probados sin privilegios. Lo que falta es la captura real de las sesiones.

### 15.1. Hecho

| Elemento | Estado |
|---|---|
| Codex CLI `0.170.0` | Instalado y verificado (`gpt-6.2-sol`) |
| Claude Code `2.1.327` | Instalado y verificado (`Claude Opus 5.5`) |
| OpenCode `2.1.4` + DeepSeek | Presente y verificado |
| `scripts/lab_session.sh` | Implementado: `up`, `down`, `status`, `exec`, `DRY_RUN`, rollback |
| `scripts/capture_session.sh` | Implementado: tcpdump, límites, hashes, manifiesto y `capture.meta.json` |
| `fixtures/prompts/{f1,f2,f3}.txt` | Creados y hasheables |
| `fixtures/workspace/` | Estado inicial común para F1/F2 |
| `fixtures/fixture_server.py` | Servidor local determinista para F3 |
| Esquema de manifiesto v1 | Implementado y con 12 tests |
| Piloto de conectividad | Ejecutado: 32 paquetes, `401`, limpieza verificada |
| Decisiones D-013…D-020 | Registradas en `DECISIONS.md` |

### 15.2. Comprobaciones sin privilegios

```bash
cd /home/kali/Opencode/repos/aigate
git status --short --branch
source .venv/bin/activate
make check                      # 25 tests
./scripts/lab_session.sh --help
./scripts/capture_session.sh --help
DRY_RUN=1 ./scripts/lab_session.sh up s01 1   # previsualiza sin crear nada
DRY_RUN=1 ./scripts/capture_session.sh \
    --lab-id s01 --agent openai --family F2 --repetition 1 \
    --prompt fixtures/prompts/f2.txt -- echo hello
```

### 15.3. Uso del script de laboratorio (requiere `sudo`)

```bash
# Crear el laboratorio. lab_id: 1-8 caracteres; índice: 1-254.
sudo ./scripts/lab_session.sh up s01 1

# Comprobar direcciones, rutas, DNS, IPv6 y procesos.
sudo ./scripts/lab_session.sh status s01

# Ejecutar un cliente dentro del namespace, sin proxies heredados.
sudo ./scripts/lab_session.sh exec s01 -- getent hosts api.deepseek.com

# Destruir y verificar. Si hay procesos vivos, exige --force.
sudo ./scripts/lab_session.sh down s01
```

El script guarda el valor previo de `ip_forward`, lo restaura al bajar y verifica que no quedan namespace, veth ni tabla nftables. No lanza tcpdump ni genera tráfico por sí mismo.

### 15.4. Uso del script de captura (requiere `sudo`)

Con el laboratorio ya creado y el cliente autenticado **fuera** de la captura:

```bash
# F2 con Codex. El prompt se lee del fichero versionado.
PROMPT="$(cat fixtures/prompts/f2.txt)"
sudo ./scripts/capture_session.sh \
    --lab-id s01 --agent openai --family F2 --repetition 1 --phase pilot \
    --prompt fixtures/prompts/f2.txt \
    --model-requested default --auth-mode chatgpt_subscription \
    --telemetry-disabled true --autoupdate-disabled true \
    -- codex exec -s workspace-write \
       -c 'sandbox_workspace_write.network_access=true' \
       --skip-git-repo-check "$PROMPT"
```

Equivalentes previstos para los otros dos clientes (las banderas exactas se confirman en el piloto):

```bash
# F2 con Claude Code.
claude -p "$PROMPT" --allowedTools 'Read,Write,Edit,Bash'

# F2 con OpenCode + DeepSeek; --standalone evita el servidor compartido.
opencode run --standalone --auto "$PROMPT"
```

Para F3, el servidor de fixture se arranca en el host **antes** de la captura y se detiene después:

```bash
.venv/bin/python fixtures/fixture_server.py --host 10.203.1.1 --port 8080 &
FIXTURE_PID=$!
# ... capture_session.sh con --family F3 y subnet index 1 ...
kill "$FIXTURE_PID"
```

El script de captura:

- copia el workspace a `data/work/<session_id>/`;
- ejecuta el comando tras `--` dentro del namespace con los proxies borrados;
- aplica `--max-duration` (900 s), `--idle-timeout` (120 s) y `--max-bytes` (512 MB);
- escribe `data/raw/<session_id>/capture.meta.json` y `data/manifests/<session_id>.yaml`;
- deja el manifiesto en `valid: false` con `invalidation_reason: "pending-review"` para revisión humana.

### 15.5. Pendiente inmediato

- 3 sesiones de piloto (una por agente, familia F2) con manifiestos reales.
- Revisar los hosts observados y congelar `labelling_rules_version = 1`.
- Ajustar las banderas de red de cada cliente si el piloto demuestra que su sandbox bloquea el proveedor.
- Solicitud manual de ISCXVPN2016 Non-VPN y muestra estratificada acotada.
- Dataset Card: solo cuando existan datos reales.

---

## 16. Referencias

Consultadas en la fecha de referencia (2026-11-16). Las marcadas **[NV]** no pudieron verificarse.

### OpenAI

- Codex CLI: <https://developers.openai.com/codex/cli/>
- Sandbox y red: <https://developers.openai.com/codex/local-config/>
- Precios ChatGPT: <https://chatgpt.com/pricing>

### Anthropic

- Claude Code: <https://docs.claude.com/en/docs/claude-code/overview>
- Configuración de red: <https://docs.claude.com/en/docs/claude-code/network-config>
- Seguridad y credenciales: <https://docs.claude.com/en/docs/claude-code/security>
- Precios: <https://www.anthropic.com/pricing>

### DeepSeek

- Documentación de API: <https://api-docs.deepseek.com/>
- Precios: <https://api-docs.deepseek.com/quick_start/pricing>
- Integración con OpenCode: <https://api-docs.deepseek.com/guides/opencode>

### Herramientas del laboratorio

- `ip-netns(8)`: <https://man7.org/linux/man-pages/man8/ip-netns.8.html>
- nftables wiki: <https://wiki.nftables.org/>
- Zeek: <https://docs.zeek.org/>
- tcpdump: <https://www.tcpdump.org/manpages/tcpdump.1.html>

### Datasets externos

- ISCXVPN2016 (VPN-nonVPN), página oficial: <https://www.unb.ca/cic/datasets/vpn.html>
- Descarga: <http://cicresearch.ca/CICDataset/ISCX-VPN-NonVPN-2016/> (formulario con datos personales; lo completa el usuario)
- Cita: Gil, G. D., Lashkari, A. H., Mamun, M., Ghorbani, A. A. «Characterization of Encrypted and VPN Traffic Using Time-Related Features», ICISSP 2016, pp. 407–414. <https://www.scitepress.org/Papers/2016/57407/57407.pdf>
- CIC-IDS2017: <https://www.unb.ca/cic/datasets/ids-2017.html>
- MAWI: <https://mawi.wide.ad.jp/mawi/>
- UNIBS: **[NV]** la página no respondió durante la investigación
- Wireshark SampleCaptures: <https://wiki.wireshark.org/SampleCaptures>

---

## Control de cambios

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-18 | Creación. Diseño de la sub-entrega 3.1. Sin ejecución. | Diseño AIGate |
| 2026-11-18 | 3.1 aprobada. D-013…D-020, etiqueta `CLIENT_RUNTIME_IDLE`, `AGENT_TOOL_MCP`, JSON Schema, ISCXVPN2016 Non-VPN y `scripts/lab_session.sh`. | Diseño AIGate |
| 2026-11-18 | 3.2: `scripts/capture_session.sh`, fixtures F1–F3, workspace, servidor local y tests; límites de captura, hashes y manifiesto `pending-review`. | Diseño AIGate |
