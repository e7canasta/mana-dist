# Especificacion de Integracion
## Nurse Office: eventos de Mana Hive

**Estado:** propuesta tecnica para implementacion
**Audiencia:** equipo de integracion, Rust/Tauri y React
**Objetivo:** construir una aplicacion para la estacion de enfermeria que escuche el bus de eventos y presente alertas visuales y auditivas accionables.

## 1. Alcance

La aplicacion Nurse Office es un consumidor del bus de eventos. No debe conocer ni depender de Cox. Cox fue utilizado como herramienta de prueba y auditoria; su rol no forma parte de este contrato.

La aplicacion debe:

- escuchar eventos publicados por Mana Hive;
- reconstruir el estado visible de cada episodio y notificacion;
- emitir una alerta visual y, cuando corresponda, sonora;
- permitir que una enfermera vea, confirme y resuelva una notificacion;
- tolerar duplicados, reintentos, mensajes fuera de orden y reconexiones;
- conservar una auditoria local de lo recibido y de las acciones del usuario.

La aplicacion no debe:

- inferir por si sola que una observacion de camara es una emergencia;
- tratar un `RecordingCommand` como una alerta clinica;
- tratar un `EvidenceRecord` como confirmacion de que una enfermera fue notificada;
- usar `NoticeEvent` para deducir el estado de la escena si existe un `SceneEvent` o `SentinelSignal` con esa informacion;
- asumir que la existencia de un evento en NATS implica que ya fue persistido en Hub.

## 2. Modelo mental

El flujo funcional es:

```text
Observation -> SceneEvent -> SentinelSignal -> NoticeEvent -> accion de enfermeria
                                      |
                                      +-> RecordingCommand / EvidenceRecord
```

No todos los casos recorren todos los pasos.

- `Observation`: medicion cruda de percepcion. Es una entrada tecnica, no una alerta.
- `SceneEvent`: hecho derivado sobre el estado de la habitacion o del residente.
- `SentinelSignal`: lifecycle clinico de un episodio.
- `NoticeEvent`: entrega y seguimiento de una notificacion.
- `RecordingCommand`: instruccion al sistema de grabacion.
- `EvidenceRecord`: evidencia de que el sistema de grabacion inicio, detuvo o creo un clip.

Para la pantalla de enfermeria, la fuente principal de alertas es `SentinelSignal` y la fuente principal de estado de entrega es `NoticeEvent`.

## 3. Transporte y envelope

Los mensajes se publican en NATS JetStream. Todos usan un envelope comun:

```json
{
  "eventId": "01J...",
  "type": "sentinel.signal.v1",
  "version": 1,
  "occurredAt": "2026-09-02T12:00:04Z",
  "source": "night-watch-runtime",
  "payloadJson": "{...}"
}
```

Reglas del consumidor:

- `eventId` es la clave de idempotencia. Persistirlo antes de aplicar el efecto o usar una transaccion equivalente.
- `type` y `version` identifican el contrato. Una version desconocida debe quedar en dead-letter/local quarantine, no romper el consumer.
- `occurredAt` es el tiempo del hecho. `receivedAt` es el tiempo local de recepcion. Para ordenar clinicamente usar `occurredAt`, pero aceptar retrasos.
- `source` identifica quien publico el mensaje y sirve para diagnostico.
- `payloadJson` debe deserializarse segun `type` y `version`; no hacer parsing generico basado solo en nombres de campos.
- Guardar el envelope original para auditoria y debugging.

## 4. Subjects

Subjects canonicos por cama:

| Proposito | Subject |
|---|---|
| Percepcion | `perception.observation.v1.<bed>` |
| Hechos de escena | `scene.fact.v1.<bed>` |
| Senales de Sentinel | `sentinel.signal.v1.<bed>` |
| Alarmas | `alarm.event.v1.<alert>` |
| Comandos de grabacion | `recorder.command.v1.<bed>` |
| Evidencia de grabacion | `evidence.record.v1.<bed>` |
| Notificaciones | `notice.event.v1.<notice>` |

Para una estacion que atiende varias camas, suscribirse al wildcard correspondiente y filtrar por `bed` del payload. No confiar solo en el sufijo del subject.

Recomendacion de despliegue:

- un durable consumer JetStream por estacion o por instancia logica;
- ack solo despues de persistir y procesar el mensaje;
- backoff y reintentos para errores transitorios;
- dead-letter para payload invalido o version no soportada;
- metricas de lag, redeliveries, eventos ignorados y eventos sin correlacion.

## 5. Contratos funcionales

### 5.1 Observation

Una observacion contiene, como minimo:

```json
{
  "monitor": "m1",
  "bed": "bed-301",
  "kind": "SITTING_IN_BED",
  "confidence": 0.92,
  "observedAt": "2026-09-02T12:00:00Z"
}
```

Tipos conocidos incluyen `IN_BED`, `LYING`, `SITTING_IN_BED`, `STANDING`, `ON_FLOOR`, presencia de staff, barandas y heartbeat.

La app de enfermeria no debe mostrar cada observacion como una alerta. Puede usarlas para un panel diagnostico o para explicar el contexto de un episodio.

### 5.2 SceneEvent

Son hechos derivados del digital twin. Tipos conocidos:

- `NightOpened`
- `TransitionDetected`
- `DwellWarning`
- `DwellExceeded`
- `SceneStateChanged`
- `StaffPresenceDetected`
- `SignalLost`
- `SignalRecovered`
- `ComeBackWarning`
- `ComeBackExceeded`
- `NightClosed`

Ejemplo conceptual de transicion:

```json
{
  "eventType": "TransitionDetected",
  "bed": "bed-301",
  "from": "LYING",
  "to": "SITTING_IN_BED",
  "at": "2026-09-02T12:00:01Z"
}
```

Uso recomendado:

- mostrar estado contextual de la cama;
- explicar por que se abrio un episodio;
- detectar perdida o recuperacion de senal;
- no generar una alarma independiente para cada transicion salvo que producto lo defina.

`SignalLost` y `SignalRecovered` son eventos operativos, no deben presentarse como caida del residente.

### 5.3 SentinelSignal y Episode

Los episodios son eventos de episodio. El lifecycle canonico es:

```text
EpisodeOpened -> EpisodeComplicated/UmbrellaEvent (opcional)
              -> AutoRecovery o SuppressedWithRecord (opcional)
              -> EpisodeClosed
```

Tipos conocidos:

- `EpisodeOpened`
- `EpisodeComplicated`
- `UmbrellaEvent`
- `AutoRecovery`
- `EpisodeClosed`
- `SuppressedWithRecord`
- `DwellPreWarning`
- `ComeBackPreWarning`

Ejemplo de apertura:

```json
{
  "type": "EpisodeOpened",
  "episode": "ep-123",
  "rule": "NIGHT_EXIT",
  "trigger": "STANDING",
  "field": "bed-301",
  "severity": "HIGH",
  "reversible": true,
  "requiresNvr": true,
  "confirmationWindow": 30,
  "at": "2026-09-02T12:00:04Z"
}
```

Ejemplo de cierre:

```json
{
  "type": "EpisodeClosed",
  "episode": "ep-123",
  "cause": "STAFF_PRESENT",
  "gapDuration": 12,
  "at": "2026-09-02T12:00:16Z"
}
```

Causas de cierre conocidas:

- `STAFF_AND_SAFE`
- `STAFF_PRESENT`
- `AUTO_RECOVERY`

Reglas para la UI:

- `EpisodeOpened` crea o activa una alerta, usando `severity`, `rule`, `bed` y `episode`.
- `EpisodeClosed` no borra la alerta: la mueve a historial y muestra la causa.
- `EpisodeComplicated` y `UmbrellaEvent` actualizan la alerta existente; no crear otra tarjeta automaticamente.
- `DwellPreWarning` y `ComeBackPreWarning` pueden mostrarse como warning previo, distinto de una alarma confirmada.
- correlacionar por `episode`, no por proximidad temporal.

### 5.4 NoticeEvent

Una notificacion representa el intento de avisar a un destinatario, no el hecho de que la escena cambio.

Lifecycle esperado:

```text
Dispatch -> Sent -> Delivered -> Seen -> Confirmed -> Resolved
                                      \-> Escalated
                                      \-> Expired
```

Datos relevantes:

- `noticeId`
- cama, residente y episodio relacionado
- severidad
- canales y destinatarios
- mensaje y contexto
- canal de envio
- staff que vio o confirmo
- actor y causa de resolucion

Comportamiento de la app:

- `Dispatch`: crear la alerta pendiente de envio.
- `Sent`: indicar que el proveedor acepto el envio.
- `Delivered`: indicar entrega al dispositivo/canal si el proveedor lo confirma.
- `Seen`: marcar vista por personal.
- `Confirmed`: detener el loop sonoro y marcar reconocida.
- `Escalated`: elevar visual y sonoramente, sin duplicar el episodio.
- `Expired`: indicar que nadie confirmo dentro del plazo.
- `Resolved`: cerrar la notificacion y conservarla en historial.

Una notificacion por episodio es la regla de dominio conocida. `RESOLVED` es estado terminal y absorbente: eventos posteriores deben registrarse y no reabrir la tarjeta sin una nueva notificacion.

### 5.5 RecordingCommand y EvidenceRecord

Son datos de grabacion y auditoria tecnica.

```text
RecordingStarted -> RecordingStopped -> ClipCreated
```

`RecordingCommand` puede ser:

- `RecordingStarted`
- `RecordingStopped`
- `ClipCreated`

`EvidenceRecord` confirma que el recorder inicio, detuvo o creo un clip. No confirma que la enfermera recibio o vio una alerta.

En la UI:

- mostrar un indicador discreto de grabacion si es necesario;
- incluir un enlace o estado del clip en el detalle del episodio;
- no crear una alerta sonora por estos eventos;
- no bloquear el cierre de una alerta porque falte `EvidenceRecord`, salvo requisito legal explicito.

## 6. Estado local recomendado

Persistir al menos estas entidades:

```text
EpisodeState
- episodeId
- residentId
- bedId
- severity
- rule
- status: OPEN | COMPLICATED | CLOSED
- openedAt
- closedAt
- closeCause
- lastOccurredAt

NoticeState
- noticeId
- episodeId
- status: DISPATCHED | SENT | DELIVERED | SEEN | CONFIRMED | ESCALATED | EXPIRED | RESOLVED
- channel
- recipient
- lastOccurredAt

ReceivedEvent
- eventId
- type
- version
- subject
- occurredAt
- receivedAt
- processingStatus
- rawEnvelope
```

Persistir antes de aplicar nuevamente un evento permite reiniciar Tauri sin repetir audio ni duplicar tarjetas.

## 7. Idempotencia y orden

El consumidor debe ser idempotente:

1. buscar `eventId` en `ReceivedEvent`;
2. si ya fue procesado, hacer ack y no repetir efectos;
3. si es nuevo, persistirlo y aplicar la transicion;
4. marcarlo procesado;
5. hacer ack.

No asumir orden perfecto. JetStream puede redeliverar y diferentes subjects pueden llegar en distinto orden.

Reglas de reconciliacion:

- ordenar por `occurredAt` dentro de una ventana corta;
- aceptar `EpisodeClosed` antes de recibir todos los eventos intermedios;
- si llega `Confirmed` antes que `Delivered`, conservar el estado mas avanzado y registrar la anomalia;
- si llega un evento para un episodio desconocido, crear un estado provisional y solicitar reconciliacion a Hub;
- no usar `receivedAt` para decidir si un episodio ocurrio antes o despues de otro.

## 8. UX de la estacion de enfermeria

La pantalla principal debe priorizar trabajo, no telemetria.

### Tarjeta de alerta

Debe mostrar:

- cama y residente;
- severidad y color accesible;
- regla o motivo en lenguaje clinico comprensible;
- hora de apertura y tiempo transcurrido;
- estado de notificacion;
- accion `Confirmar`;
- accion `Resolver` cuando corresponda;
- acceso a contexto de escena y grabacion.

### Audio

- usar un patron diferente para warning, alarma nueva y escalamiento;
- repetir la alarma mientras este pendiente de confirmacion;
- detener repeticion en `Confirmed` o `Resolved`;
- no reproducir dos veces el mismo `noticeId`/`eventId`;
- respetar mute temporal, pero mostrar siempre la alerta visual;
- probar volumen, dispositivo de salida y recuperacion despues de suspender/reanudar Tauri.

### Estados visuales sugeridos

| Estado | Visual | Audio |
|---|---|---|
| Warning previo | amarillo, no bloqueante | tono corto opcional |
| Episodio abierto | rojo/alto contraste | patron repetitivo |
| Visto | tarjeta marcada como vista | continua si no fue confirmada |
| Confirmado | azul/verde segun design system | detener |
| Escalado | rojo pulsante | patron de prioridad alta |
| Expirado | rojo persistente en historial | no repetir indefinidamente |
| Resuelto | historial | ninguno |

## 9. API de acciones

La app debe preferir las APIs de Hub para acciones sobre episodios y notificaciones, en vez de publicar eventos clinicos inventados directamente.

APIs conocidas de episodios:

- `GET /api/v1/episodes?residentId=...`
- `GET /api/v1/episodes/{episodeId}`
- `POST /api/v1/episodes/{episodeId}/acknowledge`
- `PATCH /api/v1/episodes/{episodeId}`

El contrato exacto de confirmacion y resolucion debe acordarse con el equipo de Hub. La UI debe usar comandos/REST para acciones del usuario y escuchar el evento resultante para actualizar el estado, evitando asumir que la accion fue exitosa antes de recibir confirmacion.

## 10. Arquitectura Tauri, Rust y React

```text
NATS consumer (Rust)
        |
        +-- durable store / SQLite
        |
        +-- reducer de EpisodeState y NoticeState
        |
        +-- event bus interno Tauri
                |
                +-- React: tarjetas, filtros, historial
                +-- Rust/Tauri: audio, notificaciones de OS, acciones autenticadas
```

Recomendaciones:

- mantener NATS, dedupe y reducer en Rust, fuera del renderer;
- exponer a React un modelo ya normalizado, no envelopes crudos como estado principal;
- usar eventos Tauri para cambios incrementales y una orden de snapshot inicial al abrir la pantalla;
- centralizar audio en Rust para evitar duplicados entre componentes React;
- hacer que el renderer pueda reiniciarse sin perder el estado persistido;
- incluir health status: conexion NATS, lag, ultima recepcion, audio disponible y endpoint Hub.

## 11. Escenarios de referencia

Estos escenarios fueron usados para validar el comportamiento del sistema. Las cantidades son de `SceneEvent`; episodios y notificaciones se validan por separado.

| Escenario | Secuencia de escena esperada | Resultado funcional |
|---|---|---|
| `01-e1-vuelve-solo` | `Lying -> SittingInBed`, `SittingInBed -> Lying` | no hay confirmacion por staff; revisar episodio y cierre por recuperacion |
| `02-e2-con-enfermera` | `Lying -> SittingInBed`, `SittingInBed -> Lying` | episodio y alerta de enfermeria; recording/evidence son secundarios |
| `03-noche-normal-1-episodio` | `Unknown -> Lying`, `Lying -> SittingInBed`, `SittingInBed -> Lying`, staff | episodio abierto y luego resuelto por presencia/seguridad |
| `04-staff-presente-suprime` | `Unknown -> Lying`, staff, dos transiciones | no abrir episodio clinico cuando staff ya esta presente |
| `05-escalado-sitting-standing` | `Unknown -> Lying`, `Lying -> SittingInBed`, `SittingInBed -> Standing`, `Standing -> Lying`, staff | mostrar escalamiento y luego cierre |
| `06-48h-mixto` | staff, dos transiciones y `Unknown -> Lying` | validar que el largo temporal no duplique alertas |
| `07-staff-or-safe-staff-only` | staff, `Unknown -> Lying`, transicion | staff o estado seguro suprime la alerta apropiadamente |
| `08-staff-and-safe` | staff, dos transiciones y `Unknown -> Lying` | cierre seguro con staff |
| `09-comeback-exceeded` | `Lying -> SittingInBed`, `SittingInBed -> Standing`, `Standing -> Lying`, `Unknown -> Lying` | warning/exceeded de comeback sin duplicar episodio |
| `10-observe-only` | `Lying -> SittingInBed`, `SittingInBed -> Lying`, `Unknown -> Lying` | observar y presentar contexto, sin alerta clinica nueva |

La tabla describe el comportamiento esperado de referencia, no reemplaza el contrato versionado de cada evento.

## 12. Estrategia de pruebas

### Pruebas de contrato

- deserializar cada `type` y `version` conocido;
- rechazar campos obligatorios faltantes con error observable;
- conservar campos desconocidos para forward compatibility cuando sea posible;
- probar envelopes duplicados y versiones futuras.

### Pruebas de reducer

- `EpisodeOpened` dos veces no crea dos episodios;
- `NoticeEvent Dispatch` dos veces no crea dos tarjetas;
- `Confirmed` repetido no repite audio;
- `EpisodeClosed` antes de `EpisodeOpened` crea estado provisional;
- eventos fuera de orden terminan en el mismo estado final;
- `RESOLVED` no vuelve a abrirse por un evento atrasado.

### Pruebas de integracion

Cada corrida debe guardar:

- scenario id y version;
- run id;
- eventos crudos recibidos;
- `eventId`, subject, tipo, version y timestamps;
- resultado de episodio;
- resultado de escena;
- resultado de notificacion;
- estado de recording, si aplica;
- acciones realizadas por la enfermera.

La prueba debe separar estos veredictos:

```text
EpisodeAcceptance
SceneAcceptance
NotificationAcceptance
RecordingAcceptance
```

Un fallo de recording no debe aparecer como fallo de escena. Un fallo de notificacion no debe ocultar que el episodio fue correcto.

### Criterio de calidad

El runner de regresion debe ejecutar los escenarios secuencialmente, imprimir cada resultado inmediatamente y continuar para producir un informe completo. Para una prueba interactiva de debugging se puede activar `stop-on-failure`.

## 13. Observaciones y riesgos conocidos

- La presencia de un evento NATS no garantiza que Hub ya lo haya proyectado.
- Los agentes externos que producen `Seen`, `Confirmed`, `Escalated` y `Expired` deben verificarse en el entorno objetivo.
- `RecordingCommand` y `EvidenceRecord` pueden no existir en escenarios `observe-only` y no deben ser requeridos por una prueba de escena.
- Los filtros declarados por algunos planes de observacion no necesariamente se aplican todos en el recorder actual; el consumer debe filtrar explicitamente por cama, residente y tipo.
- El sistema debe observar `eventId` como identidad global y no construir dedupe solo con timestamps.
- Los nombres de eventos y campos son versionados: ante un cambio incompatible debe aparecer una nueva version de contrato.

## 14. Checklist de entrega

- [ ] Consumer durable configurado para los subjects necesarios.
- [ ] Reconexion y redelivery probados.
- [ ] Dedupe por `eventId` probado.
- [ ] Reducer de episodios y notificaciones probado fuera de orden.
- [ ] Audio probado sin duplicaciones.
- [ ] Accesibilidad visual: color no es el unico indicador.
- [ ] Confirmacion y resolucion integradas con Hub.
- [ ] Historial y auditoria local implementados.
- [ ] Metricas y health status visibles.
- [ ] Escenarios `01` a `10` ejecutados con veredictos separados.
- [ ] Runbook de reconexion, dead-letter y fallos de audio publicado.

## 15. Decisiones que debe cerrar el equipo

- URL, credenciales, TLS y permisos NATS para una estacion de enfermeria.
- Nombre del durable consumer y politica de retencion local.
- Mapeo de `severity` a colores, sonidos y prioridad operacional.
- Tiempo de repeticion de audio y politica de mute.
- Contrato definitivo de acknowledge, confirmacion y resolucion en Hub.
- Que hacer si no hay conectividad con Hub pero la estacion sigue recibiendo NATS.
- Si el residente se identifica por `residentId`, por cama, o por ambos en la UI.
- Politica de privacidad para mostrar residente, contexto y clips de video.
- Requisito de auditoria: retencion, exportacion y permisos para consultar eventos crudos.
