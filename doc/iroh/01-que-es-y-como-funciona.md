# Qué es iroh y cómo funciona

Introducción técnica a iroh para quien no lo conozca. La decisión de usarlo en Sysmote, con sus alternativas descartadas, está en `../documentos-generales-del-proyecto/02-necesidades-tecnologicas.md` §3.3 — no se repite aquí.

## 1. Qué es

[iroh](https://www.iroh.computer/) es una librería de red P2P (peer-to-peer) en Rust, del proyecto n0. Dos equipos cualquiera pueden hablar directamente entre sí sin que el usuario configure el router ni abra puertos, y sin depender de un servidor propio: solo hace falta que ambos tengan la librería y se conozcan por un identificador.

Tiene *bindings* oficiales para varios lenguajes (Python, Kotlin, Swift, Dart a través de terceros) que exponen la misma API sobre el mismo núcleo en Rust. En Sysmote se usa:
- **`iroh` (PyPI, 1.2.0 instalado)** en el agente — binding oficial, generado con `uniffi-rs`, con API totalmente asíncrona (`asyncio`).
- **`iroh_flutter` (pub.dev, 1.3.0)** en la app — plugin de un *publisher* externo (`snowpine.io`, no n0-computer) que compila el núcleo Rust para cada plataforma con `cargokit` y expone la API de `iroh_quic` (otro paquete del mismo autor) en Dart.

## 2. Conceptos básicos

| Concepto | Qué es |
|---|---|
| **`SecretKey`** | 32 bytes aleatorios que identifican a un equipo de forma permanente. Si no se guarda, cada arranque genera una identidad nueva (ver `../../agent/sysmote/iroh_tunnel.py`, `load_or_create_secret_key`). |
| **`EndpointId`** | La clave pública derivada de la `SecretKey`. Es el "identificador iroh" que se copia entre el agente y la app — 64 caracteres hexadecimales. |
| **`Endpoint`** | El punto de conexión local: lo que se "arranca" para poder aceptar o iniciar conexiones. Equivale a un socket, pero por encima de QUIC y con descubrimiento de direcciones. |
| **`Connection`** | Una conexión establecida entre dos `Endpoint`s, identificada por el `EndpointId` del otro lado. |
| **`BiStream` / stream bidireccional** | Un canal de bytes dentro de una `Connection`, como una conexión TCP normal. Una `Connection` puede tener muchos *streams* abiertos a la vez (multiplexado, una ventaja de QUIC sobre TCP). |
| **ALPN** | Una cadena de bytes que identifica el protocolo que va a hablar la conexión (igual que en TLS). Sysmote usa `b"sysmote/tunnel/0"`; si algún día se habla otro protocolo sobre iroh, se distingue por el ALPN. |
| **Relé** | Un servidor intermediario (gestionado por n0, gratuito para uso personal) que reenvía el tráfico cifrado cuando los dos equipos no pueden verse directamente. Habla HTTPS (TCP), no UDP. |

## 3. Cómo se establece una conexión

1. El lado que acepta (el agente) hace `Endpoint.bind(...)` y queda escuchando. Su identificador es su `EndpointId`.
2. El lado que conecta (la app) hace `endpoint.connect(addr, alpn)`, donde `addr` lleva el `EndpointId` del agente (y, opcionalmente, direcciones conocidas).
3. iroh **empieza siempre por el relé**: ambos equipos abren una conexión HTTPS al mismo relé y el tráfico se reenvía cifrado a través de él. Esto funciona casi siempre, incluso detrás de NAT o cortafuegos estrictos, porque usa el mismo puerto 443 que cualquier navegador.
4. En paralelo, iroh intenta la **travesía de NAT** (*hole punching* sobre UDP): cada equipo prueba a enviar paquetes UDP directamente al otro, usando las direcciones que ha descubierto. Si lo consigue, la conexión **pasa a directa** sin que la aplicación tenga que hacer nada — los *streams* ya abiertos se mantienen, solo cambia la ruta de los paquetes por debajo.
5. Si la travesía de NAT falla (por ejemplo, porque el cortafuegos bloquea el UDP saliente), la conexión **se queda por el relé** indefinidamente. Sigue funcionando, solo con más latencia.

Este comportamiento se verificó de verdad en la fase 2: ver `04-pruebas.md`, casos 1-4.

## 4. Qué cifra y qué no

Cada `Connection` va sobre QUIC, que cifra con TLS 1.3 de serie — el tráfico nunca viaja en claro, ni por el relé ni directo. El relé ve el tráfico cifrado pero no puede leerlo. Sysmote no añade un TLS propio encima por iroh: el cifrado y la autenticación del agente (por su clave pública, el `EndpointId`) los pone iroh. El TLS propio de Sysmote (certificado autofirmado, fase 3) solo se usa en la conexión por red local.

## 5. Patrón usado en Sysmote: dumbpipe

Sysmote no "habla iroh" dentro de la API del agente. En vez de eso, usa iroh como un **túnel transparente**: el agente abre un `Endpoint`, acepta conexiones y reenvía cada *stream* a su propio servidor HTTP local (`127.0.0.1:8444`, el puerto HTTP interno), byte a byte, sin tocar el contenido. La app hace lo mismo al revés: abre un *stream* por cada petición HTTP y la envía tal cual. Así la API REST/WebSocket del agente no sabe si la petición llegó por USB, por la LAN o por iroh — es el mismo patrón que la herramienta `dumbpipe` del propio proyecto iroh. El detalle de implementación está en `02-implementacion.md`.
