# Plan: Reemplazar Mock Data → API Real
**Fecha:** 2026-04-11  
**Estado:** En planificación  
**Autor:** Noé

---

## Estado Actual del Proyecto

### Infraestructura base (COMPLETA)
- `ApiClient` — Dio singleton, base URL Railway, JWT interceptor automático
- `ApiEndpoints` — 50+ endpoints definidos
- `AuthProvider` — Login, register, guest, Google Auth (100% real)
- `PerfilProvider` → `RidersService` — GET/PUT /riders/me, stats (100% real)

### Resumen por Feature

| Feature | Estado | Proveedor actual | Servicio API | Endpoints disponibles |
|---------|--------|-----------------|--------------|----------------------|
| **onboarding** | ✅ 100% real | `authProvider` | `auth_repository.dart` | POST /auth/register, /login, /guest-token, /login/google |
| **perfil** | ✅ 100% real | `perfilProvider` | `riders_service.dart` | GET/PUT /riders/me, POST /riders/me/moto, GET /riders/{id}/stats |
| **sala** | ⚡ Parcial | `salaProvider` (mock init) | `salas_service.dart` + `chat_service.dart` (orphaned) | 8 salas + 6 chat + 3 realtime + 6 voice endpoints |
| **amarres** | ❌ 100% mock | `amarresProvider` | Ninguno | 11 endpoints disponibles en ms_amarres |
| **rutas** | ❌ 100% mock | `rutasProvider` | Ninguno | Tracks via ms_location (GPX export) |
| **home** | ❌ 100% mock | `homeProvider` | Ninguno | Compuesto: salas + amarres + riders |
| **foro** | ❌ 100% mock | `foroProvider` | Ninguno | ⚠️ Sin backend propio (ver nota) |

---

## Mapa Completo: Mock → Endpoint Real

### Feature: `sala`

| Dato mock actual | Endpoint real | Servicio disponible |
|-----------------|---------------|---------------------|
| `nombre: 'Sierra Gorda Norte'` (hardcoded) | GET `/api/v1/salas/{sala_id}` → `name` | `SalasService.getSala()` ✅ |
| `tiempo: '2h 14m'` (hardcoded) | Calcular desde `sala.created_at` | Local calc |
| `distancia: '138 km'` (hardcoded) | GET `/api/v1/location/salas/{id}/tracks` → sum distances | `ms_location` |
| `riders: [SalaRider('JD'), ...]` (hardcoded) | GET `/api/v1/salas/{sala_id}/miembros` | `SalasService.getMiembros()` (crear) |
| `messages: [SalaMessage(...)]` (hardcoded) | GET `/api/v1/chat/{sala_id}/mensajes` | `ChatService.getMensajes()` ✅ |
| `sendMessage()` → local only | POST `/api/v1/chat/{sala_id}/mensajes` | `ChatService.sendText()` ✅ |
| Crear sala → ninguno | POST `/api/v1/salas` | `SalasService.createSala()` ✅ |
| Cerrar sala → ninguno | POST `/api/v1/salas/{id}/close` | `SalasService.closeSala()` ✅ |
| PTT → local toggle | POST `/api/v1/voice/{sala_id}/ptt` | Crear `VoiceService` |

### Feature: `amarres`

| Dato mock actual | Endpoint real | Acción requerida |
|-----------------|---------------|-----------------|
| Lista hardcoded (4 registros) | GET `/api/v1/amarres/me` | Crear `AmarresService` |
| `totalKm` calculado localmente | Viene en respuesta API | Usar `km_total` del servidor |
| Sin detalle expandido | GET `/api/v1/amarres/{id}` | Crear `AmarresService.getAmarre()` |
| Sin fotos | GET `/api/v1/amarres/{id}` → `fotos` array | Expandir modelo |

### Feature: `rutas`

| Dato mock actual | Endpoint real | Acción requerida |
|-----------------|---------------|-----------------|
| Lista hardcoded (5 rutas) | GET `/api/v1/amarres/feed` (rutas públicas) | Crear `RutasService` usando amarres públicos |
| `isFavorita` → local toggle | PUT `/api/v1/amarres/{id}` (tags: ['favorita']) | Persistir en backend |
| Sin detalle de track | GET `/api/v1/location/salas/{id}/export` → GPX | Expandir detalle screen |

### Feature: `home`

| Bloque mock actual | Endpoint real | Composición |
|-------------------|---------------|-------------|
| `norayActivo` (sala hardcoded) | GET `/api/v1/salas` → primera activa del rider | `SalasService.listSalas()` ✅ |
| `proximosAmarres` (hardcoded) | GET `/api/v1/amarres/me` → filtrar próximos | `AmarresService.getMyAmarres()` |
| `rutas` (hardcoded) | GET `/api/v1/amarres/feed` → recientes | `RutasService.getFeed()` |

### Feature: `foro`

| Estado actual | Situación backend | Opciones |
|--------------|-------------------|---------|
| 5 posts hardcoded con título, preview, tags, respuestas | ⚠️ **No existe ms_foro** | Opción A: Crear ms_foro en Sprint 2 |
| Sin persistencia, sin búsqueda | El CLAUDE.md no menciona foro como servicio planeado | Opción B: Reutilizar feed de amarres públicos como "comunidad" |
| | | **Decisión pendiente de Noé** |

---

## Orden de Prioridad (por dependencias)

```
BLOQUE 1 — Independiente, máximo impacto visual
├── [P1] Amarres: _loadMockData() → GET /amarres/me
└── [P2] Sala: SalaProvider init → GET /salas/{id} + GET /chat/{id}/mensajes

BLOQUE 2 — Depende de Amarres completado
├── [P3] Home: norayActivo → GET /salas (activa)
│           proximosAmarres → GET /amarres/me
│           rutas → GET /amarres/feed
└── [P4] Rutas: _loadMockData() → GET /amarres/feed

BLOQUE 3 — Decisión de diseño pendiente
└── [P5] Foro: Decidir arquitectura (ms_foro vs reutilizar amarres)

BLOQUE 4 — Funcionalidades nuevas en sala
└── [P6] Sala completo: PTT real + GPS real + Miembros live
```

### Justificación del orden

1. **Amarres primero** — feature independiente, servicio limpio, patrón igual a `RidersService`. Alta prioridad porque es donde los riders ven su historial.
2. **Sala segundo** — servicios ya existen (`ChatService`, `SalasService`), solo hay que conectar el provider. Es el corazón del producto.
3. **Home tercero** — depende de que Amarres y Salas funcionen (compone datos de ambos).
4. **Rutas cuarto** — puede reusar el servicio de Amarres (feed público). Bajo esfuerzo si Amarres ya está.
5. **Foro quinto** — requiere decisión de arquitectura backend primero.
6. **Sala completo sexto** — PTT, GPS, miembros live son Sprint 2 (MQTT, WebRTC).

---

## Patrón de Migración (template)

El patrón exitoso de `PerfilProvider` → `RidersService` es el template a seguir:

```dart
// ANTES (mock)
class AmarresNotifier extends StateNotifier<AmarresState> {
  AmarresNotifier() : super(const AmarresState()) {
    _loadMockData(); // ← eliminar
  }
  void _loadMockData() { /* hardcoded */ }
}

// DESPUÉS (real)
class AmarresNotifier extends StateNotifier<AmarresState> {
  final AmarresService _service;
  AmarresNotifier(this._service) : super(const AmarresState(isLoading: true)) {
    _load();
  }
  Future<void> _load() async {
    try {
      final amarres = await _service.getMyAmarres();
      state = AmarresState(amarres: amarres, isLoading: false);
    } catch (e) {
      state = AmarresState(error: e.toString(), isLoading: false);
    }
  }
}
```

---

## Archivos a Crear (nuevos servicios)

| Archivo | Feature | Endpoints que envuelve |
|---------|---------|------------------------|
| `lib/features/amarres/services/amarres_service.dart` | amarres | GET /amarres/me, GET /amarres/feed, GET /amarres/{id} |
| `lib/features/rutas/services/rutas_service.dart` | rutas | GET /amarres/feed (reutiliza AmarresService) |
| `lib/features/sala/services/voice_service.dart` | sala | POST /voice/{id}/ptt, GET /voice/{id}/status |
| `lib/features/sala/services/miembros_service.dart` | sala | GET /salas/{id}/miembros |

---

## Archivos a Modificar (providers existentes)

| Archivo | Cambio |
|---------|--------|
| `lib/features/amarres/providers/amarres_provider.dart` | `_loadMockData()` → `_load()` con `AmarresService` |
| `lib/features/sala/providers/sala_provider.dart` | Init state desde `SalasService.getSala()` + `ChatService.getMensajes()` |
| `lib/features/home/providers/home_provider.dart` | Componer datos desde 3 servicios reales |
| `lib/features/rutas/providers/rutas_provider.dart` | `_loadMockData()` → `_load()` con `RutasService` |

---

## Definición de "Completo" por Feature

| Feature | Criterio de éxito |
|---------|-------------------|
| **amarres** | Lista real desde MongoDB. Sin datos hardcoded. Estado vacío si no hay registros. |
| **sala (core)** | Sala se carga desde ID real. Chat persiste en MongoDB. Crear sala funcional. |
| **home** | 3 bloques muestran datos reales. Sin fallback a mock. |
| **rutas** | Feed de amarres públicos. Favorito persiste al backend. |
| **foro** | Pendiente decisión arquitectura |

---

## Nota sobre el Foro

El `foro` no tiene microservicio definido en el backend. Opciones:

- **Opción A:** Crear `ms_foro` en Sprint 2 (posts, comentarios, tags, búsqueda)
- **Opción B:** Reutilizar `GET /api/v1/amarres/feed` como feed de comunidad (amarres públicos = "posts")
- **Opción C:** Eliminar foro del Sprint 1 y reemplazar con la pantalla de "Tripulación/Grupos"

**Acción requerida:** Decisión de Noé antes de iniciar implementación del foro.

---

## Checklist de Ejecución

### Sprint 1 — Remove Mocks

- [ ] **P1** Crear `AmarresService` + migrar `AmarresNotifier`
- [ ] **P2** Migrar `SalaProvider` → `SalasService.getSala()` + `ChatService.getMensajes()`
- [ ] **P2** Conectar `sendMessage()` → `ChatService.sendText()`
- [ ] **P3** Migrar `HomeProvider` → componer datos reales
- [ ] **P4** Crear `RutasService` + migrar `RutasNotifier`
- [ ] **P5** Decidir arquitectura foro

### Sprint 2 — Sala Completo

- [ ] **P6** PTT real → `VoiceService`
- [ ] **P6** Miembros live → `GET /salas/{id}/miembros`
- [ ] **P6** GPS MQTT → `ms_realtime` + `ms_location`
- [ ] **P6** Crear sala funcional end-to-end

---

*Plan generado el 2026-04-11. Actualizar checklist conforme avance la implementación.*
