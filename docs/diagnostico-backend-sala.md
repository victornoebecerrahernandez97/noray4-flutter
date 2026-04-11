# Diagnóstico Backend — Sala Activa
**Fecha:** 2026-04-11  
**Versión auditada:** noray4-fastapi (estado actual)  
**Objetivo:** Determinar el estado real del backend para planear la implementación del mapa en tiempo real, chat y PTT en Flutter.

---

## 1. Arquitectura Real

### Estructura de módulos

```
noray4-fastapi/
├── main.py                    ← App, lifespan, CORS, router registration
├── shared/
│   ├── auth.py               ← JWT create/verify, bcrypt hashing
│   ├── config.py             ← Pydantic Settings desde .env
│   ├── database.py           ← Motor async MongoDB, collection accessors
│   ├── dependencies.py       ← get_current_user(), get_current_rider()
│   ├── exceptions.py         ← Global exception handlers
│   └── models.py             ← NorayBase (base Pydantic)
│
├── ms_auth/                  ← Register, login, guest tokens, /auth/me
├── ms_riders/                ← Profile CRUD, follow/unfollow, stats
├── ms_salas/                 ← Room lifecycle, QR, miembros
├── ms_realtime/              ← WebSocket endpoint + MQTT bridge
│   ├── router.py             ← POST /realtime/{sala_id}/ubicacion, /evento
│   ├── mqtt_client.py        ← Paho-MQTT wrapper, TLS, auto-reconnect
│   └── ws_bridge.py          ← WS handler + MQTT<→>WS bridge
├── ms_location/              ← TrackStore in-memory, POIs, GPX export
│   └── track_store.py        ← Dict[sala_id][rider_id] = deque(maxlen=10_000)
├── ms_voice/                 ← PTT state, WebRTC signaling, channels
│   └── ptt_store.py          ← In-memory PTT state per canal
├── ms_chat/                  ← CRUD mensajes + ACK + Cloudinary
├── ms_amarres/               ← Viajes guardados, fotos, likes, clone
└── ms_groups/                ← Comunidades permanentes
```

### Comunicación entre microservicios
- **No hay llamadas HTTP entre microservicios.** Todo está en el mismo proceso FastAPI.
- La comunicación "real-time" entre módulos es:
  - `ms_location` → MQTT (publica ubicacion)
  - `ms_chat` → MQTT (publica chat)
  - `ms_voice` → MQTT (publica voz/señalización WebRTC)
  - `ms_realtime/ws_bridge` → suscrito a `noray4/{sala_id}/#` → reenvía a WebSocket clientes
- Imports circulares resueltos con local imports (ej: ms_auth importa ms_riders dentro de función)

---

## 2. WebSocket

### Endpoint
```
ws://<host>/ws/{sala_id}?token=<JWT>
```

### Autenticación
1. JWT en query param `?token=`
2. Token verificado en `ws_bridge.endpoint()` — código 4001 si inválido
3. Rider profile requerido — código 4003 si no existe

### Formato de mensajes (servidor → cliente)
Todos los mensajes son JSON envelopes:
```json
{
  "topic": "noray4/{sala_id}/ubicacion",
  "payload": { ... }
}
```

### Topicos que llegan al cliente vía WebSocket
| Topic suffix | Cuándo llega | Payload |
|---|---|---|
| `/ubicacion` | Cada update GPS de cualquier rider | `{rider_id, lat, lng, heading?, speed?, timestamp}` |
| `/chat` | Mensaje nuevo en la sala | Objeto MensajeOut completo |
| `/voz` | PTT start/stop o señal WebRTC | `{type, canal_id, speaker_id, ...}` |
| `/eventos` | Evento admin (system message) | `{type, data, timestamp}` |
| `/presencia` | Rider conecta/desconecta WS | `{rider_id, display_name, status: online/offline, timestamp}` |

### Mensajes del cliente → servidor vía WebSocket
```json
{
  "topic": "noray4/{sala_id}/...",  // opcional; default: /eventos
  "payload": { ... }
}
```

### Bridge MQTT → WebSocket: IMPLEMENTADO
- `ws_bridge.py` usa `asyncio.Queue(maxsize=256)` por cliente
- Suscripción al patrón `noray4/{sala_id}/#` en HiveMQ
- Dos tasks concurrentes: `broker_to_ws()` y `ws_to_broker()`
- Exit on first failure (disconnect limpio)
- Presencia publicada en MQTT al conectar y desconectar

---

## 3. MQTT

### Broker
- HiveMQ Cloud — TLS 8883
- Auto-reconnect con backoff 1s → 10s
- QoS 1 (at-least-once)
- Client ID: `noray4-api-{random_hex}`

### Topics activos
| Topic | Estado | Publicado por | Payload |
|---|---|---|---|
| `noray4/{sala_id}/ubicacion` | **IMPLEMENTADO** | POST /location/salas/{sala_id}/update | `{rider_id, lat, lng, heading, speed, timestamp}` |
| `noray4/{sala_id}/chat` | **IMPLEMENTADO** | POST /chat/{sala_id}/mensajes | MensajeOut completo |
| `noray4/{sala_id}/voz` | **IMPLEMENTADO** | POST /voice/{sala_id}/ptt y /signal | `{type, canal_id, speaker_id, ...}` |
| `noray4/{sala_id}/eventos` | **IMPLEMENTADO** | POST /realtime/{sala_id}/evento (admin) | `{type, data, timestamp}` |
| `noray4/{sala_id}/presencia` | **IMPLEMENTADO** | ws_bridge on connect/disconnect | `{rider_id, display_name, status}` |

**Todos los topics están implementados.**

---

## 4. Location Service

### TrackStore — estructura en memoria
```python
# track_store.py
_tracks: Dict[str, Dict[str, deque]]
# tracks[sala_id][rider_id] = deque(maxlen=10_000)
```
- Ring buffer de 10,000 puntos por rider por sala
- Sin locks (asyncio single-thread)
- Se limpia con `clear_sala()` al cerrar sala
- **No persiste en MongoDB durante la sesión** — solo el GPX final en el Amarre

### POST /api/v1/location/salas/{sala_id}/update

**Request:**
```json
{
  "lat": float,      // -90 a 90
  "lng": float,      // -180 a 180
  "heading": float,  // 0-360, opcional
  "speed": float,    // ≥0, opcional
  "timestamp": datetime  // default: now
}
```

**Lo que hace internamente:**
1. Override `rider_id` desde JWT (anti-spoof)
2. `TrackStore.add_point(sala_id, rider_id, point)`
3. Publica en MQTT `noray4/{sala_id}/ubicacion` (fire-and-forget)
4. Retorna últimas posiciones de TODOS los riders

**Response — retorna posiciones de TODOS los riders:**
```json
{
  "status": "ok",
  "last_positions": {
    "rider_id_1": {
      "lat": 19.4326, "lng": -99.1332,
      "heading": 270.0, "speed": 45.0,
      "timestamp": "2026-04-11T..."
    },
    "rider_id_2": { ... }
  }
}
```

> **Clave:** El REST polling de `/update` ya retorna posiciones de TODOS los riders.  
> No es necesario un endpoint separado solo para leer posiciones durante la sesión.

### Rate limiting
**NINGUNO implementado.** No hay throttling en publicación de coordenadas.

---

## 5. Voice Service

### PTT — estado en memoria
```python
# ptt_store.py
_states: Dict[canal_id, PTTState]       # speaker actual por canal
_participants: Dict[canal_id, Set[str]] # riders que hablaron en sesión
```
- **100% en memoria, efímero**
- Se limpia con `cleanup_sala()` al cerrar sala
- Canales en MongoDB (`canales_voz`): persisten nombre/sala_id, no el estado PTT

### Señalización WebRTC
- El servidor es **relay de señalización solamente** — no maneja audio
- Flow:
  1. Rider A → POST /voice/{sala_id}/signal `{type: "offer", target_rider_id: B, payload: SDP}`
  2. Servidor publica en MQTT `noray4/{sala_id}/voz`
  3. Rider B recibe vía WebSocket, extrae offer, responde con answer
  4. ICE candidates se intercambian igual
- **Audio P2P directo** entre riders via WebRTC — el servidor no participa

### Timeout de PTT
**NINGUNO implementado.** El hablante retiene el turno indefinidamente hasta que llame con `action=stop`.

### Endpoints clave
| Endpoint | Función | Response |
|---|---|---|
| `POST /voice/{sala_id}/ptt` | start/stop PTT | `PTTState {canal_id, speaker_id, speaker_name, is_speaking, timestamp}` |
| `GET /voice/{sala_id}/status` | Estado actual de todos los canales | `List[VozStatusOut]` |
| `POST /voice/{sala_id}/signal` | Relay señal WebRTC | `{status: "sent"}` |
| `POST /voice/{sala_id}/force-release/{canal_id}` | Admin: liberar PTT | `{status: "released"}` |
| `POST /voice/{sala_id}/canales` | Crear canal | CanalOut |
| `GET /voice/{sala_id}/canales` | Listar canales | `List[CanalOut]` |

**Canales auto-creados al abrir sala:** general, lideres, emergencia.

**Conflicto PTT:** Si ya hay un hablante, retorna 409 con el nombre del hablante actual.

---

## 6. Chat Service

### Modelo de entrega
1. **REST POST** → persiste en MongoDB → retorna mensaje
2. **MQTT fire-and-forget** → `noray4/{sala_id}/chat` simultáneo
3. **WebSocket bridge** → clientes reciben en tiempo real
4. **GET polling** como fallback para clientes offline

### ACK
- Campo `delivered_to: List[rider_id]` en documento MongoDB
- `POST /chat/{sala_id}/mensajes/{id}/ack` → `$addToSet` (idempotente)
- **No hay garantía de entrega** — MQTT es fire-and-forget, el ACK es solo tracking

### Tipos de mensaje
```
"text" | "image" | "coords" | "file" | "system"
```

### Paginación
- Default: 50 mensajes, max: 100
- Ordenados por `created_at DESC` en MongoDB, revertidos a cronológico en response

### Upload de imágenes
- Cloudinary: max 10MB, formatos jpeg/png/webp
- Genera thumbnail width=400
- Retorna `{media_url, thumb_url, public_id}`

---

## 7. Gaps Críticos para Sala Activa

### Mapa en tiempo real

| Componente | Estado | Gap |
|---|---|---|
| Backend publica GPS vía MQTT | IMPLEMENTADO | — |
| WebSocket recibe topic /ubicacion | IMPLEMENTADO | — |
| Flutter consume WebSocket | **PENDIENTE** | Implementar WebSocketChannel en sala_provider |
| Flutter renderiza mapa con riders | **PENDIENTE** | google_maps_flutter + marcadores dinámicos |
| Rate limiting en updates | **FALTA** | Sin throttling — riesgo de saturación |
| Validación de membership en /update | **FALTA** | Cualquier rider autenticado puede publicar ubicación |

**Lo que falta para mapa real:** Solo el cliente Flutter. El backend está listo.

### Chat en tiempo real

| Componente | Estado | Gap |
|---|---|---|
| Backend publica chat vía MQTT | IMPLEMENTADO | — |
| WebSocket recibe topic /chat | IMPLEMENTADO | — |
| Flutter consume WebSocket para chat | **PENDIENTE** | Parsear envelope y manejar MensajeOut |
| Scroll to bottom on new message | **PENDIENTE** | Flutter UX |
| Optimistic updates | **PENDIENTE** | Opcional pero recomendado |
| Read receipts granulares | **PARCIAL** | ACK existe pero no se expone en UI |

**Lo que falta para chat real:** Solo el cliente Flutter.

### PTT funcional

| Componente | Estado | Gap |
|---|---|---|
| PTT state en servidor | IMPLEMENTADO | — |
| MQTT publica PTT events | IMPLEMENTADO | — |
| WebRTC signaling relay | IMPLEMENTADO | — |
| **Audio codec en Flutter** | **NO EXISTE** | Requiere flutter_webrtc o record package |
| PTT timeout automático | **FALTA** | Rider puede bloquear canal indefinidamente |
| Flutter UI PTT button hold | **PENDIENTE** | GestureDetector onLongPress → PTT start/stop |
| Indicador visual hablante activo | **PENDIENTE** | Consumir WebSocket /voz topic |

**PTT es el gap más grande:** El backend hace señalización pero Flutter necesita implementar WebRTC completo para audio real.

---

## 8. Recomendaciones de Arquitectura

### WebSocket vs Polling para el mapa

**Recomendación: WebSocket con fallback a polling**

| Criterio | WebSocket | Polling (1s interval) |
|---|---|---|
| Latencia | ~50-150ms | ~500ms-1s |
| Batería | Mejor (conexión persistente) | Peor (requests frecuentes) |
| Implementación Flutter | `web_socket_channel` package | http package existente |
| Reconexión | Requiere retry logic | Automático por naturaleza |
| Estado del backend | LISTO | LISTO (polling via /update response) |

**Estrategia híbrida recomendada:**
```
WebSocket conectado:
  → Recibir ubicaciones de otros riders vía topic /ubicacion
  → Publicar propia ubicación vía REST POST /location/salas/{sala_id}/update
  
WebSocket desconectado:
  → Fallback: Timer(1s) → POST /update (el response ya incluye todos los riders)
```

El POST `/update` retorna `last_positions` de todos los riders — sirve como polling completo.

### Frecuencia recomendada de publicación GPS

| Escenario | Frecuencia | Justificación |
|---|---|---|
| Riding activo (>30 km/h) | **cada 3s** | Actualización fluida sin saturar |
| Riding lento (<30 km/h) | **cada 5s** | Menos movimiento, menos datos |
| Detenido | **cada 15s** | Heartbeat de presencia |
| App en background | **cada 30s** | Conservar batería |

**Implementar en Flutter:** `Geolocator.getPositionStream(distanceFilter: 10)` — publica solo si se movió >10 metros.

### Manejo de riders offline

El backend no tiene estado de presencia persistido — solo en memoria via MQTT `/presencia`. Estrategia recomendada:

```
1. WebSocket disconnect → backend publica noray4/{sala_id}/presencia {status: offline}
2. Flutter: riders con último update >30s → mostrar icono "offline" en mapa
3. last_positions retorna timestamp → Flutter puede calcular "hace X segundos"
4. Rider reconecta → presencia online publicada automáticamente
```

**Recomendación adicional para backend:** Agregar `heartbeat_at` a `last_positions` response para que Flutter pueda mostrar "rider offline" sin timestamp adicional.

### Orden de implementación Flutter — Sala Activa

```
Sprint 1A (MVP funcional):
  1. WebSocketChannel connection en sala_provider
  2. Parse envelope topic/payload
  3. Chat en tiempo real (WebSocket /chat topic)
  4. Indicador PTT visual (WebSocket /voz topic)
  5. POST /location/update cada 3s con Timer

Sprint 1B (Mapa):
  6. google_maps_flutter integration
  7. Marcadores dinámicos por rider_id
  8. Fallback polling si WS desconectado

Sprint 2 (Audio):
  9. flutter_webrtc para audio PTT real
  10. GestureDetector hold → PTT start/stop
  11. PTT timeout local (30s max) como safety
```

---

## Apéndice: Endpoints clave para Flutter — Sala Activa

```
# Conectar WebSocket
WS  /ws/{sala_id}?token=<JWT>

# Publicar ubicación (y recibir todas las posiciones)
POST /api/v1/location/salas/{sala_id}/update
  Body: {lat, lng, heading?, speed?}
  Returns: {status, last_positions: {rider_id: {lat, lng, ...}}}

# Enviar mensaje de chat
POST /api/v1/chat/{sala_id}/mensajes
  Body: {type: "text", content: "..."}

# Historial de chat (al abrir sala)
GET  /api/v1/chat/{sala_id}/mensajes?limit=50

# PTT start
POST /api/v1/voice/{sala_id}/ptt
  Body: {action: "start", canal_id: "general"}

# PTT stop
POST /api/v1/voice/{sala_id}/ptt
  Body: {action: "stop", canal_id: "general"}

# Estado de voz (al abrir sala)
GET  /api/v1/voice/{sala_id}/status

# Cerrar sala
POST /api/v1/salas/{sala_id}/close
```

---

*Reporte generado por auditoría técnica completa del código fuente. Todos los hallazgos basados en lectura directa de archivos.*
