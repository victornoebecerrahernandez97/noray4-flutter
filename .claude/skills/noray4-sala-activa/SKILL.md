---
name: noray4-sala-activa
description: Skill de implementación para SalaScreen en Noray4. Usar cuando se
  trabaje en sala_screen.dart, MapTab, VozTab, ChatTab, ArchivosTab, BottomPanel
  collapsable, WebSocketManager, GPS tracking en tiempo real, PTT o cualquier
  feature de la sala activa. Define arquitectura, estados, tokens visuales y
  patrones de responsabilidad para todos los componentes.
---

# Noray4 — Sala Activa Skill

## Arquitectura general

```
features/sala/
├── sala_screen.dart              ← Shell: mapa full-screen + overlays flotantes
├── providers/
│   ├── sala_provider.dart        ← Estado de la sala (miembros, status)
│   ├── map_provider.dart         ← RiderPositions, POIs, autoFollow
│   ├── chat_provider.dart        ← Mensajes, pagination, ACK
│   └── voz_provider.dart         ← PTT state, canales, speaking
├── services/
│   ├── websocket_manager.dart    ← Singleton WS + streams tipados
│   ├── location_service.dart     ← Timer GPS + POST /update
│   └── ptt_service.dart          ← POST /ptt start|stop + timeout 30s
└── widgets/
    ├── bottom_panel.dart         ← Panel collapsable (3 estados)
    ├── stats_overlay.dart        ← Velocidad + KM flotante top-center
    ├── header_sala.dart          ← AppBar glass + riders pill
    ├── map_fabs.dart             ← FABs flotantes derecha
    ├── toast_incoming.dart       ← Toast mensaje entrante
    ├── toast_rider_joined.dart   ← Toast rider se unió
    ├── tabs/
    │   ├── map_tab.dart          ← flutter_map OSM (ya implementado)
    │   ├── chat_tab.dart         ← Lista mensajes + input
    │   ├── voz_tab.dart          ← Channels + PTT + riders row
    │   └── archivos_tab.dart     ← Lista archivos (ya implementado)
    └── map/
        ├── rider_marker.dart     ← Marker animado con heading
        └── poi_marker.dart       ← Marker POI con categoría
```

## Tokens visuales (Monolith Framework)

```dart
// Colores base
const kBg         = Color(0xFF0A0A0A);
const kSurface    = Color(0xFF1A1A1A);
const kSurfaceEl  = Color(0xFF242424);
const kPrimary    = Color(0xFFFFFFFF);
const kSecondary  = Color(0xFF8E8E93);
const kAccentRed  = Color(0xFFFF3B30);
const kGreen      = Color(0xFF34C759);
const kMapBg      = Color(0xFF111111);

// Rider colors (determinísticos por hash de riderId)
const kRiderColors = [
  Color(0xFF4A90E2), // azul
  Color(0xFFF5A623), // naranja
  Color(0xFF7ED321), // verde
  Color(0xFF9B59B6), // morado
  Color(0xFFE74C3C), // rojo
  Color(0xFF1ABC9C), // teal
];

// POI colors
const kPoiFuel     = Color(0xFFF5A623);
const kPoiMechanic = Color(0xFF4A90E2);
const kPoiView     = Color(0xFF7ED321);
const kPoiDanger   = Color(0xFFD0021B);
const kPoiFood     = Color(0xFFFF9F0A);
const kPoiHotel    = Color(0xFF9B59B6);

// Glass decoration
BoxDecoration glassDecoration() => BoxDecoration(
  color: const Color(0xFF0F0F0F).withOpacity(0.72),
  border: Border.all(color: Colors.white.withOpacity(0.08)),
  borderRadius: BorderRadius.circular(20),
);

// Glass header
BoxDecoration glassHeaderDecoration() => BoxDecoration(
  color: const Color(0xFF0A0A0A).withOpacity(0.80),
);
```

## SalaScreen — shell principal

```dart
// sala_screen.dart — Stack con mapa full-screen + overlays flotantes
Scaffold(
  resizeToAvoidBottomInset: false, // CRÍTICO — mapa no se mueve con teclado
  body: Stack(
    children: [
      // 1. Mapa full screen (base)
      Positioned.fill(child: MapTab()),
      
      // 2. Header flotante (top)
      Positioned(top: 0, left: 0, right: 0, child: HeaderSala()),
      
      // 3. Stats overlay (top-center, debajo del header)
      Positioned(top: 68, left: 0, right: 0, child: StatsOverlay()),
      
      // 4. FABs (derecha, centro vertical)
      Positioned(right: 16, top: MediaQuery.of(context).size.height * 0.45,
        child: MapFABs()),
      
      // 5. Toast rider joined (top, debajo del header)
      Positioned(top: 68, left: 0, right: 0, child: ToastRiderJoined()),
      
      // 6. Toast mensaje entrante (sobre el panel)
      Positioned(bottom: panelHeight + 8, left: 16, right: 16,
        child: ToastIncoming()),
      
      // 7. Bottom panel collapsable (bottom)
      Positioned(bottom: 0, left: 0, right: 0, child: BottomPanel()),
    ],
  ),
);
```

## BottomPanel — estados y responsabilidad

### 3 estados
```dart
enum PanelState { expanded, collapsed, pttActive }
```

### Alturas
```dart
const kPanelExpanded  = 290.0;
const kPanelCollapsed = 72.0;
const kPanelPttActive = 310.0;
```

### Animación de colapso
```dart
AnimationController _controller; // duration: 300ms
late Animation<double> _heightAnim;

// En initState:
_heightAnim = Tween<double>(
  begin: kPanelExpanded,
  end: kPanelCollapsed,
).animate(CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut, // NO linear — se nota rígido
));
```

### Estructura del panel expandido (top→bottom)
1. DragHandle (8px top padding, pill 36×4px rgba(255,255,255,0.2))
2. SpeakingBanner (solo visible en pttActive)
3. MetricsRow (height: 64px, 4 columnas con divisores)
4. TabsRow (height: 44px, sin emojis en labels)
5. TabContent (padding: 12px 16px 0)

### Estructura del panel collapsed
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 4 iconos sin texto
    Row(children: TAB_ICONS.map((icon) => 
      IconButton(icon: icon, size: 22, color: kPrimary/kSecondary)
    ).toList()),
    // Mini avatars overlapping
    CollapsedAvatars(),
  ],
)
```

### CollapsedAvatars — overlap pattern
```dart
SizedBox(
  width: riders.length * 16.0 + 8, // width dinámico
  child: Stack(
    children: riders.asMap().entries.map((e) =>
      Positioned(
        left: e.key * 16.0,
        child: MiniAvatar(rider: e.value, zIndex: riders.length - e.key),
      )
    ).toList(),
  ),
)
```

## VozTab — responsabilidad y estados

### ChannelPills
```dart
// Active: bg blanco, texto negro
// Inactive: borde rgba(255,255,255,0.15), texto gris
// NO usar OutlinedButton — usar Container + GestureDetector para control total
```

### PTT Button — 3 estados visuales
```dart
// IDLE
Container(
  width: 72, height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withOpacity(0.08),
    border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
  ),
  child: Icon(Icons.mic, color: kPrimary, size: 28),
)

// ACTIVE (pttActive)
Container(
  width: 80, height: 80,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: kAccentRed,
    border: Border.all(color: kAccentRed, width: 2),
  ),
  child: Column(children: [
    Icon(Icons.mic, color: kPrimary, size: 28),
    Text('0:12', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
  ]),
)

// LOADING (esperando respuesta del servidor)
// Mostrar CircularProgressIndicator pequeño dentro del botón
```

### PTT Pulse rings (solo en pttActive)
```dart
// 3 AnimationControllers con delay 0ms, 333ms, 666ms
// Cada ring: Container con BoxDecoration circle, color: kAccentRed.withOpacity(0.25)
// Scale: 1.0 → 1.8, Opacity: 0.3 → 0.0, duration: 1000ms, loop
```

### PTT timeout local
```dart
// En ptt_service.dart:
Timer? _timeoutTimer;

void startPTT(String canalId) {
  _timeoutTimer = Timer(const Duration(seconds: 30), () {
    stopPTT(canalId); // auto-release
  });
  // POST /voice/{sala_id}/ptt action=start
}

void stopPTT(String canalId) {
  _timeoutTimer?.cancel();
  // POST /voice/{sala_id}/ptt action=stop
}
```

## RiderAvatar — variantes

```dart
// En sala (32px)
CircleAvatar(
  radius: 16,
  backgroundColor: kSurfaceEl,
  child: Text(initials, style: SpaceMono 10px bold),
)

// Borde activo PTT (speaker)
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: kAccentRed, width: 2),
    boxShadow: [BoxShadow(color: kAccentRed.withOpacity(0.3), blurRadius: 6)],
  ),
)

// Offline
Opacity(opacity: 0.4, child: avatar)

// Mini collapsed (24px, overlap -8px)
// isMe: borde blanco
// otros: color por hash del riderId
```

## StatsOverlay — responsabilidad

```dart
// Solo muestra velocidad y km — NO riders ni tiempo (esos van en el panel)
// Actualiza desde mapProvider.currentSpeed y mapProvider.distanceTraveled
// Si speed == null → ocultar el stat de velocidad (sin GPS aún)
// Usar Consumer<MapNotifier> con select para no reconstruir todo
```

## WebSocketManager — contratos

```dart
// Envelope del backend:
// {"type": "ubicacion|chat|voz|presencia|evento", "data": {...}}

class WebSocketManager {
  static final WebSocketManager instance = WebSocketManager._();
  
  // Streams tipados — NO exponer el WS raw
  Stream<UbicacionEvent> get ubicaciones => _ubicacionController.stream;
  Stream<MensajeOut> get chatMessages => _chatController.stream;
  Stream<PTTState> get vozEvents => _vozController.stream;
  Stream<PresenciaEvent> get presencia => _presenciaController.stream;
  
  // Reconexión backoff exponencial
  final List<int> _backoffSeconds = [1, 2, 4, 8, 16, 30];
  int _backoffIndex = 0;
  
  void connect(String salaId, String token) {
    final uri = Uri.parse(
      'wss://web-production-66456.up.railway.app/ws/$salaId?token=$token'
    );
    // _channel = WebSocketChannel.connect(uri);
    // _channel.stream.listen(_onMessage, onDone: _reconnect, onError: _reconnect);
  }
  
  void _onMessage(dynamic data) {
    final json = jsonDecode(data);
    switch (json['type']) {
      case 'ubicacion': _ubicacionController.add(UbicacionEvent.fromJson(json['data']));
      case 'chat':      _chatController.add(MensajeOut.fromJson(json['data']));
      case 'voz':       _vozController.add(PTTState.fromJson(json['data']));
      case 'presencia': _presenciaController.add(PresenciaEvent.fromJson(json['data']));
    }
  }
}
```

## MapNotifier — patrones obligatorios

```dart
class MapState {
  final Map<String, RiderPosition> riders; // key: riderId
  final List<POIOut> pois;
  final bool autoFollow;
  final double? currentSpeed;
  final double distanceTraveled;
  
  // NO List<Marker> — los markers se construyen en el widget desde riders
}

// Actualización parcial — NUNCA reemplazar todo el map
void updateRiderPosition(String riderId, CoordUpdate coord) {
  final prev = state.riders[riderId];
  state = state.copyWith(
    riders: {
      ...state.riders,
      riderId: RiderPosition(
        riderId: riderId,
        previousPosition: prev?.position,
        position: LatLng(coord.lat, coord.lng),
        heading: coord.heading,
        speed: coord.speed,
        timestamp: coord.timestamp,
        isOnline: true,
      ),
    },
  );
}
```

## LocationService — GPS timer

```dart
// Publicar cada 3s si distancia > 5m del último punto
// En background: cada 10s (cuando app no está en primer plano)
// Validar coordenadas antes de publicar:
bool _isValidCoord(double lat, double lng) =>
  lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 && lat != 0 && lng != 0;

// La response de POST /update incluye last_positions → actualizar mapProvider
// NO usar el WebSocket para tu propia posición
```

## Anti-patrones prohibidos

- ❌ `setState` para updates de posición de riders
- ❌ Reconstruir MapTab en cada GPS update
- ❌ Crear nuevos `Marker` objects en cada update (reusar con key)
- ❌ Mover cámara en cada update de otro rider
- ❌ `resizeToAvoidBottomInset: true` en SalaScreen (rompe el mapa)
- ❌ Abrir teclado en sala sin `ClampingScrollPhysics` en el chat input
- ❌ Llamar `ApiClient` directamente desde widgets
- ❌ PTT sin timeout local de 30s
- ❌ Publicar GPS sin validar coordenadas

## Dependencias requeridas

```yaml
# Ya instaladas:
flutter_map: ^6.x
latlong2: ^0.9.x
flutter_riverpod: ^2.x
dio: ^5.x
flutter_secure_storage: ^9.x
google_sign_in: ^6.x

# Agregar para WebSocket y GPS:
web_socket_channel: ^2.4.0
geolocator: ^11.0.0
permission_handler: ^11.0.0
```

## Permisos Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## Orden de implementación

1. `WebSocketManager` + modelos de eventos
2. `MapNotifier` + `LocationService` (GPS real en mapa)
3. `BottomPanel` collapsable con animación
4. `StatsOverlay` + `HeaderSala` + `MapFABs`
5. `VozTab` + `PTTService` + señalización
6. `ChatTab` conectado a WebSocket
7. Toasts (`ToastIncoming`, `ToastRiderJoined`)
8. POIs en mapa

## Performance targets

- 60fps durante tracking activo
- Marker update < 500ms desde publicación GPS
- Panel collapse animation: exactamente 300ms easeInOut
- WebSocket reconexión < 3s
- Memoria estable con 20+ riders activos
