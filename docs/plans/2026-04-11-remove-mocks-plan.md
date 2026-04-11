# Remove Mocks — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Reemplazar todos los mock data en los providers de amarres, sala, rutas y home con llamadas reales a la API de Railway (FastAPI + MongoDB).

**Architecture:** Riverpod `StateNotifier` — mismo patrón que `PerfilProvider`/`RidersService`.

**Dependencies:** Ninguna nueva — ya están `dio`, `flutter_riverpod`, `flutter_secure_storage`.

**Base URL:** `https://web-production-66456.up.railway.app`

---

## BLOQUE 1 — Amarres (independiente, mayor impacto)

### Task 1: Extender modelo `Amarre` con `fromJson`

**Layer:** Data Model

**Files:**
- Modify: `lib/features/amarres/models/amarres_models.dart`

**What & Why:**
El backend devuelve `AmarreOut` con campos distintos a los del modelo Flutter actual. Necesitamos `fromJson` para deserializar y añadir `salaId`/`tags`/`privacy`. Mantenemos `km` como `int` haciendo `.round()` sobre `km_total`.

**Implementation:**

```dart
class Amarre {
  final String id;
  final String nombre;
  final DateTime fecha;
  final int km;
  final String duracion;
  final List<String> participantes;
  final String zona;
  final String? salaId;
  final List<String> tags;
  final String privacy;

  const Amarre({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.km,
    required this.duracion,
    this.participantes = const [],
    required this.zona,
    this.salaId,
    this.tags = const [],
    this.privacy = 'private',
  });

  factory Amarre.fromJson(Map<String, dynamic> json) {
    final duracionMin = json['duracion_min'] as int? ?? 0;
    final h = duracionMin ~/ 60;
    final m = duracionMin % 60;
    final duracionStr = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';

    final ridersDisplay = (json['riders_display'] as List?) ?? [];
    final participantes = ridersDisplay
        .map((e) => (e as Map<String, dynamic>)['display_name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final tags = (json['tags'] as List?)?.cast<String>() ?? [];

    return Amarre(
      id: json['_id'] as String,
      nombre: json['title'] as String,
      fecha: DateTime.parse(json['created_at'] as String),
      km: ((json['km_total'] as num?) ?? 0).round(),
      duracion: duracionStr,
      participantes: participantes,
      zona: tags.isNotEmpty ? tags.first : '',
      salaId: json['sala_id'] as String?,
      tags: tags,
      privacy: json['privacy'] as String? ?? 'private',
    );
  }

  String get fechaFormateada {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}

class AmarresState {
  final List<Amarre> amarres;
  final int totalKm;
  final bool isLoading;
  final String? error;

  const AmarresState({
    this.amarres = const [],
    this.totalKm = 0,
    this.isLoading = false,
    this.error,
  });

  AmarresState copyWith({
    List<Amarre>? amarres,
    int? totalKm,
    bool? isLoading,
    String? error,
  }) =>
      AmarresState(
        amarres: amarres ?? this.amarres,
        totalKm: totalKm ?? this.totalKm,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
```

**Verification:**
```bash
flutter analyze lib/features/amarres/models/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/amarres/models/amarres_models.dart
git commit -m "feat(amarres): add fromJson to Amarre model, add isLoading/error to state"
```

---

### Task 2: Crear `AmarresService`

**Layer:** Data Service

**Files:**
- Create: `lib/features/amarres/services/amarres_service.dart`

**What & Why:**
Servicio que envuelve los endpoints del `ms_amarres` backend. Mismo patrón que `RidersService`. El endpoint `GET /api/v1/amarres/me` devuelve `PaginatedAmarres` con estructura `{items, total, skip, limit, has_more}`.

**Implementation:**

```dart
import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';

class AmarresService {
  final _dio = ApiClient.instance.dio;

  /// Mis amarres paginados. Devuelve máximo [limit] registros desde [skip].
  Future<List<Amarre>> getMyAmarres({int skip = 0, int limit = 20}) async {
    final res = await _dio.get(
      ApiEndpoints.amaresMios,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    return items
        .map((e) => Amarre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Feed público de amarres (para la pantalla Rutas).
  Future<List<Map<String, dynamic>>> getFeed({
    int skip = 0,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.amaresFeed,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    // El feed puede devolver lista directa o paginado — manejar ambos
    final raw = res.data;
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    final data = raw as Map<String, dynamic>;
    return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  /// Detalle completo de un amarre por ID.
  Future<Amarre> getAmarre(String id) async {
    final res = await _dio.get(ApiEndpoints.amarre(id));
    return Amarre.fromJson(res.data as Map<String, dynamic>);
  }
}
```

**Verification:**
```bash
flutter analyze lib/features/amarres/services/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/amarres/services/amarres_service.dart
git commit -m "feat(amarres): create AmarresService wrapping ms_amarres API"
```

---

### Task 3: Migrar `AmarresNotifier` a API real

**Layer:** Presentation State

**Files:**
- Modify: `lib/features/amarres/providers/amarres_provider.dart`

**What & Why:**
Reemplazar `_loadMockData()` con `_load()` que llama `AmarresService`. Seguir exactamente el patrón de `PerfilNotifier._load()`. El `totalKm` se calcula localmente sumando los `km` de los amarres retornados.

**Implementation:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/amarres/models/amarres_models.dart';
import 'package:noray4/features/amarres/services/amarres_service.dart';

class AmarresNotifier extends StateNotifier<AmarresState> {
  final _service = AmarresService();

  AmarresNotifier() : super(const AmarresState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final amarres = await _service.getMyAmarres();
      final totalKm = amarres.fold(0, (sum, a) => sum + a.km);
      state = AmarresState(amarres: amarres, totalKm: totalKm);
    } catch (e) {
      state = AmarresState(error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final amarresProvider = StateNotifierProvider<AmarresNotifier, AmarresState>(
  (_) => AmarresNotifier(),
);
```

**Verification:**
```bash
flutter analyze lib/features/amarres/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/amarres/providers/amarres_provider.dart
git commit -m "feat(amarres): replace mock data with AmarresService API call"
```

---

### Task 4: Actualizar `AmarresScreen` para manejar `isLoading` y `error`

**Layer:** Presentation UI

**Files:**
- Read first: `lib/features/amarres/amarres_screen.dart`
- Modify: `lib/features/amarres/amarres_screen.dart`

**What & Why:**
La pantalla actualmente renderiza la lista directamente. Con el API real necesita manejar estado de carga y error. Añadir un `CircularProgressIndicator` mientras carga y un mensaje de error si falla.

**Implementation — reemplazar el body del `build` en `AmarresScreen`:**

Localizar el bloque donde se hace `state.amarres.isEmpty` y envolverlo así:

```dart
// Dentro del build, donde se renderiza el contenido:
if (state.isLoading) ...[
  const Expanded(
    child: Center(
      child: CircularProgressIndicator(strokeWidth: 1.5),
    ),
  ),
] else if (state.error != null) ...[
  Expanded(
    child: Center(
      child: Text(
        'Sin conexión',
        style: Noray4TextStyles.body.copyWith(
          color: Noray4Colors.darkSecondary,
        ),
      ),
    ),
  ),
] else if (state.amarres.isEmpty) ...[
  const Expanded(child: _EmptyState()),
] else ...[
  // Lista existente de amarres
  Expanded(
    child: ListView.separated(
      // ... código existente sin cambios
    ),
  ),
],
```

**Verification:**
```bash
flutter analyze lib/features/amarres/amarres_screen.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/amarres/amarres_screen.dart
git commit -m "feat(amarres): handle loading and error states in AmarresScreen"
```

---

## BLOQUE 2 — Sala Core (servicios ya existen, solo conectar)

### Task 5: Extender `SalaState` y `SalaMessage` con campos reales

**Layer:** Data Model

**Files:**
- Modify: `lib/features/sala/models/sala_models.dart`

**What & Why:**
`SalaRider` actualmente solo tiene `initials` (string de 2 letras). El backend devuelve `MiembroOut` con `riderId`, `displayName`, `role`. Extender para soportar ambos casos. Añadir `isLoading` y `error` al `SalaState`. Añadir `riderId` a `SalaMessage` para saber si el mensaje es "outgoing" comparando con el rider autenticado.

**Implementation:**

```dart
enum SalaTab { mapa, chat, voz, archivos }

class SalaMessage {
  final String id;
  final String sender;
  final String riderId;
  final String text;
  final String time;
  final bool isOutgoing;
  final String? mediaUrl;

  const SalaMessage({
    required this.id,
    required this.sender,
    required this.riderId,
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.mediaUrl,
  });

  factory SalaMessage.fromApi(Map<String, dynamic> json, String myRiderId) {
    final riderId = json['rider_id'] as String;
    final createdAt = DateTime.parse(json['created_at'] as String);
    final time =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    return SalaMessage(
      id: json['_id'] as String,
      sender: (json['display_name'] as String).toUpperCase(),
      riderId: riderId,
      text: json['content'] as String? ?? '',
      time: time,
      isOutgoing: riderId == myRiderId,
      mediaUrl: json['media_url'] as String?,
    );
  }
}

class SalaRider {
  final String initials;
  final String? riderId;
  final String? displayName;
  final String role;

  const SalaRider(
    this.initials, {
    this.riderId,
    this.displayName,
    this.role = 'rider',
  });

  factory SalaRider.fromMiembro(Map<String, dynamic> json) {
    final name = json['display_name'] as String? ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return SalaRider(
      initials,
      riderId: json['rider_id'] as String?,
      displayName: name,
      role: json['role'] as String? ?? 'rider',
    );
  }
}

class SalaState {
  final String salaId;
  final String nombre;
  final SalaTab activeTab;
  final List<SalaMessage> messages;
  final List<SalaRider> riders;
  final String tiempo;
  final String distancia;
  final bool isPttActive;
  final bool isVoiceActive;
  final bool isLoading;
  final String? error;

  const SalaState({
    required this.salaId,
    this.nombre = '',
    this.activeTab = SalaTab.mapa,
    this.messages = const [],
    this.riders = const [],
    this.tiempo = '0h 00m',
    this.distancia = '0 km',
    this.isPttActive = false,
    this.isVoiceActive = true,
    this.isLoading = false,
    this.error,
  });

  SalaState copyWith({
    SalaTab? activeTab,
    List<SalaMessage>? messages,
    List<SalaRider>? riders,
    bool? isPttActive,
    bool? isVoiceActive,
    String? tiempo,
    String? distancia,
    bool? isLoading,
    String? error,
    String? nombre,
  }) =>
      SalaState(
        salaId: salaId,
        nombre: nombre ?? this.nombre,
        activeTab: activeTab ?? this.activeTab,
        messages: messages ?? this.messages,
        riders: riders ?? this.riders,
        tiempo: tiempo ?? this.tiempo,
        distancia: distancia ?? this.distancia,
        isPttActive: isPttActive ?? this.isPttActive,
        isVoiceActive: isVoiceActive ?? this.isVoiceActive,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
```

**Verification:**
```bash
flutter analyze lib/features/sala/models/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/models/sala_models.dart
git commit -m "feat(sala): extend SalaState/SalaMessage/SalaRider with API fields"
```

---

### Task 6: Migrar `SalaNotifier` — init desde API

**Layer:** Presentation State

**Files:**
- Modify: `lib/features/sala/providers/sala_provider.dart`

**What & Why:**
Reemplazar el constructor con mock data por `_init()` que llama `SalasService.getSala()` + `ChatService.getMensajes()` en paralelo. El rider autenticado viene del `authProvider` — para eso el notifier necesita acceso a `Ref`. Usar `StateNotifierProviderFamily` con `AsyncValue`-style init.

Para saber si un mensaje es "outgoing" necesitamos el `riderId` del usuario actual. Este está en `authProvider` → `state.user?.id`. Lo pasamos como segundo parámetro del family.

**Implementation:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/features/sala/services/chat_service.dart';
import 'package:noray4/features/sala/services/salas_service.dart';

class SalaNotifier extends StateNotifier<SalaState> {
  final String _salaId;
  final String _myRiderId;
  final _salasService = SalasService();
  final _chatService = ChatService();

  SalaNotifier(this._salaId, this._myRiderId)
      : super(SalaState(salaId: _salaId, isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        _salasService.getSala(_salaId),
        _chatService.getMensajes(_salaId, limit: 50),
      ]);

      final sala = results[0] as SalaOut;
      final paginado = results[1] as PaginatedMensajes;

      final riders = sala.miembros
          .map((m) => SalaRider.fromMiembro({
                'rider_id': m.riderId,
                'display_name': m.displayName,
                'role': m.role,
              }))
          .toList();

      final messages = paginado.items
          .where((m) => !m.deleted && m.content != null)
          .map((m) => SalaMessage.fromApi({
                '_id': m.id,
                'rider_id': m.riderId,
                'display_name': m.displayName,
                'content': m.content,
                'created_at': m.createdAt,
                'media_url': m.mediaUrl,
              }, _myRiderId))
          .toList();

      final tiempoStr = _calcTiempo(sala.createdAt);

      state = state.copyWith(
        nombre: sala.name,
        riders: riders,
        messages: messages,
        tiempo: tiempoStr,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _init();

  void switchTab(SalaTab tab) => state = state.copyWith(activeTab: tab);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final optimistic = SalaMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'Tú',
      riderId: _myRiderId,
      text: text.trim(),
      time: _formatTime(DateTime.now()),
      isOutgoing: true,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);
    try {
      await _chatService.sendText(_salaId, text.trim());
    } catch (_) {
      // Mantener el mensaje optimista — sin rollback para no degradar UX
    }
  }

  void setPtt(bool active) => state = state.copyWith(isPttActive: active);

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _calcTiempo(String createdAtIso) {
    try {
      final start = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(start);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    } catch (_) {
      return '0h 00m';
    }
  }
}

// El family recibe salaId como parámetro; myRiderId se lee del authProvider
final salaProvider =
    StateNotifierProvider.family<SalaNotifier, SalaState, String>(
  (ref, salaId) {
    final myRiderId = ref.watch(authProvider).user?.id ?? '';
    return SalaNotifier(salaId, myRiderId);
  },
);
```

**Verification:**
```bash
flutter analyze lib/features/sala/providers/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/providers/sala_provider.dart
git commit -m "feat(sala): init SalaNotifier from API — getSala + getMensajes"
```

---

### Task 7: Wire `CrearSalaScreen` a `SalasService.createSala()`

**Layer:** Presentation UI

**Files:**
- Modify: `lib/features/sala/screens/crear_sala_screen.dart`

**What & Why:**
Actualmente `_crearSala()` genera un ID falso y navega inmediatamente. Necesita llamar `SalasService.createSala()`, obtener el ID real de MongoDB, y luego navegar. Convertir `_CrearSalaScreenState` a `ConsumerStatefulWidget`.

**Implementation — reemplazar el método `_crearSala` y el tipo del widget:**

1. Cambiar `StatefulWidget` → `ConsumerStatefulWidget`, `State<...>` → `ConsumerState<...>`

2. Añadir `_isLoading` field al state:
```dart
bool _isLoading = false;
```

3. Reemplazar el método `_crearSala`:
```dart
Future<void> _crearSala() async {
  if (!_formKey.currentState!.validate()) return;
  if (_isLoading) return;
  setState(() => _isLoading = true);
  await N4Haptics.medium();
  try {
    final sala = await SalasService().createSala(
      name: _nombreCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      isPrivate: _privacidad == _Privacidad.privada,
    );
    if (!mounted) return;
    context.push('/sala/${sala.id}');
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No se pudo convocar la salida',
          style: Noray4TextStyles.body.copyWith(
            color: Noray4Colors.darkPrimary,
          ),
        ),
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

4. En `_BotonCrear`, pasar `isLoading` para mostrar spinner:
```dart
_BotonCrear(onTap: _isLoading ? null : _crearSala, isLoading: _isLoading),
```

5. Actualizar `_BotonCrear` para recibir `isLoading`:
```dart
class _BotonCrear extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _BotonCrear({required this.onTap, this.isLoading = false});
  // ... dentro del build, reemplazar el texto con:
  // isLoading ? SizedBox(w:20,h:20, child: CircularProgressIndicator(strokeWidth:1.5, color: Color(0xFF111110))) : Text('Convocar salida', ...)
}
```

6. Añadir import:
```dart
import 'package:noray4/features/sala/services/salas_service.dart';
```

**Verification:**
```bash
flutter analyze lib/features/sala/screens/crear_sala_screen.dart
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/sala/screens/crear_sala_screen.dart
git commit -m "feat(sala): wire CrearSalaScreen to SalasService.createSala()"
```

---

## BLOQUE 3 — Rutas (reutiliza amarres feed)

### Task 8: Extender modelo `Ruta` con `fromJson` mapeando `AmarrePublicOut`

**Layer:** Data Model

**Files:**
- Modify: `lib/features/rutas/models/rutas_models.dart`

**What & Why:**
La pantalla Rutas muestra amarres públicos como "rutas de comunidad". `AmarrePublicOut` no tiene `zona` ni `dificultad` — derivamos `zona` del primer tag, y `dificultad` por km (< 100 = fácil, < 300 = moderada, ≥ 300 = exigente). Añadir `isLoading`/`error` a `RutasState`.

**Implementation — añadir al final de `rutas_models.dart`:**

```dart
// Añadir en la clase Ruta:
factory Ruta.fromJson(Map<String, dynamic> json) {
  final kmTotal = ((json['km_total'] as num?) ?? 0).round();
  final durMin = json['duracion_min'] as int? ?? 0;
  final h = durMin ~/ 60;
  final m = durMin % 60;
  final durStr = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';

  final tags = (json['tags'] as List?)?.cast<String>() ?? [];
  final ridersDisplay = (json['riders_display'] as List?) ?? [];
  final participantes = ridersDisplay.length;

  RutaDificultad dificultad;
  if (kmTotal < 100) {
    dificultad = RutaDificultad.facil;
  } else if (kmTotal < 300) {
    dificultad = RutaDificultad.moderada;
  } else {
    dificultad = RutaDificultad.exigente;
  }

  String autor = '@rider';
  if (ridersDisplay.isNotEmpty) {
    final first = ridersDisplay.first as Map<String, dynamic>;
    final name = first['display_name'] as String? ?? '';
    if (name.isNotEmpty) autor = '@${name.toLowerCase().replaceAll(' ', '_')}';
  }

  return Ruta(
    id: json['_id'] as String,
    nombre: json['title'] as String,
    autor: autor,
    km: kmTotal,
    duracion: durStr,
    zona: tags.isNotEmpty ? tags.first : '',
    dificultad: dificultad,
    participantes: participantes,
  );
}
```

**En `RutasState`, añadir campos:**
```dart
class RutasState {
  final List<Ruta> rutas;
  final RutaFiltro filtroActivo;
  final String query;
  final bool isLoading;
  final String? error;

  const RutasState({
    this.rutas = const [],
    this.filtroActivo = RutaFiltro.todas,
    this.query = '',
    this.isLoading = false,
    this.error,
  });

  // Actualizar copyWith:
  RutasState copyWith({
    List<Ruta>? rutas,
    RutaFiltro? filtroActivo,
    String? query,
    bool? isLoading,
    String? error,
  }) =>
      RutasState(
        rutas: rutas ?? this.rutas,
        filtroActivo: filtroActivo ?? this.filtroActivo,
        query: query ?? this.query,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
  
  // Mantener rutasFiltradas sin cambios
}
```

**Verification:**
```bash
flutter analyze lib/features/rutas/models/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/rutas/models/rutas_models.dart
git commit -m "feat(rutas): add fromJson to Ruta model mapping AmarrePublicOut fields"
```

---

### Task 9: Crear `RutasService` y migrar `RutasNotifier`

**Layer:** Data Service + Presentation State

**Files:**
- Create: `lib/features/rutas/services/rutas_service.dart`
- Modify: `lib/features/rutas/providers/rutas_provider.dart`

**What & Why:**
`RutasService` delega a `AmarresService.getFeed()` y mapea cada `AmarrePublicOut` a `Ruta`. El `RutasNotifier` sigue el mismo patrón que `AmarresNotifier`.

**`rutas_service.dart`:**
```dart
import 'package:noray4/features/amarres/services/amarres_service.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';

class RutasService {
  final _amarresService = AmarresService();

  Future<List<Ruta>> getFeed({int skip = 0, int limit = 20}) async {
    final raw = await _amarresService.getFeed(skip: skip, limit: limit);
    return raw.map(Ruta.fromJson).toList();
  }
}
```

**`rutas_provider.dart` (reemplazar completamente):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/rutas/models/rutas_models.dart';
import 'package:noray4/features/rutas/services/rutas_service.dart';

class RutasNotifier extends StateNotifier<RutasState> {
  final _service = RutasService();

  RutasNotifier() : super(const RutasState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rutas = await _service.getFeed();
      state = state.copyWith(rutas: rutas, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  void setFiltro(RutaFiltro filtro) =>
      state = state.copyWith(filtroActivo: filtro);

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleFavorita(String id) {
    // Favorito local (persistencia en Sprint 2 via PUT /amarres/{id})
    state = state.copyWith(
      rutas: state.rutas.map((r) {
        if (r.id == id) return r.copyWith(isFavorita: !r.isFavorita);
        return r;
      }).toList(),
    );
  }
}

final rutasProvider = StateNotifierProvider<RutasNotifier, RutasState>(
  (_) => RutasNotifier(),
);
```

**Verification:**
```bash
flutter analyze lib/features/rutas/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/rutas/services/rutas_service.dart lib/features/rutas/providers/rutas_provider.dart
git commit -m "feat(rutas): replace mock with RutasService using amarres/feed endpoint"
```

---

## BLOQUE 4 — Home (compone datos de Salas + Amarres)

### Task 10: Crear `HomeService` y migrar `HomeNotifier`

**Layer:** Data Service + Presentation State

**Files:**
- Create: `lib/features/home/services/home_service.dart`
- Modify: `lib/features/home/providers/home_provider.dart`

**What & Why:**
`HomeService` hace 2 llamadas en paralelo: `SalasService.listSalas()` para el noray activo y la lista de salas próximas, y `AmarresService.getFeed()` para las rutas de comunidad. Si no hay sala activa, `norayActivo` es `null`.

El modelo `ProximoAmarre` tenía campos `dia`, `diaSemana`, `puntoReunion` que mapeamos desde `SalaOut` usando `createdAt` para fecha y `description` para punto de reunión.

**`home_service.dart`:**
```dart
import 'package:noray4/features/amarres/services/amarres_service.dart';
import 'package:noray4/features/home/models/home_models.dart';
import 'package:noray4/features/sala/services/salas_service.dart';

class HomeService {
  final _salas = SalasService();
  final _amarres = AmarresService();

  Future<HomeData> load() async {
    final results = await Future.wait([
      _salas.listSalas(limit: 10),
      _amarres.getFeed(limit: 5),
    ]);

    final salas = results[0] as List<SalaOut>;
    final feedRaw = results[1] as List<Map<String, dynamic>>;

    // norayActivo — primera sala activa
    final salaActiva = salas.isNotEmpty ? salas.first : null;
    final norayActivo = salaActiva != null
        ? NorayActivo(
            id: salaActiva.id,
            nombre: salaActiva.name,
            km: 0, // km real viene de ms_location en Sprint 2
            tiempo: _calcTiempo(salaActiva.createdAt),
          )
        : null;

    // próximos amarres → salas restantes como "próximas salidas"
    final proximasSalas = salaActiva != null ? salas.skip(1).toList() : salas;
    final proximosAmarres = proximasSalas.map((s) {
      final fecha = DateTime.tryParse(s.createdAt) ?? DateTime.now();
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return ProximoAmarre(
        id: s.id,
        nombre: s.name,
        dia: fecha.day,
        diaSemana: dias[fecha.weekday - 1],
        puntoReunion: s.description ?? 'Ver detalles en la sala',
      );
    }).toList();

    // rutas comunidad desde feed de amarres públicos
    final rutas = feedRaw.map((json) {
      final hace = _calcHace(json['created_at'] as String? ?? '');
      final ridersDisplay = (json['riders_display'] as List?) ?? [];
      String autor = '@rider';
      if (ridersDisplay.isNotEmpty) {
        final first = ridersDisplay.first as Map<String, dynamic>;
        final name = first['display_name'] as String? ?? '';
        if (name.isNotEmpty) {
          autor = '@${name.toLowerCase().replaceAll(' ', '_')}';
        }
      }
      return RutaComunidad(
        id: json['_id'] as String,
        nombre: json['title'] as String,
        autor: autor,
        km: ((json['km_total'] as num?) ?? 0).round(),
        hace: hace,
      );
    }).toList();

    return HomeData(
      norayActivo: norayActivo,
      proximosAmarres: proximosAmarres,
      rutas: rutas,
    );
  }

  String _calcTiempo(String createdAtIso) {
    try {
      final start = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(start);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}h';
    } catch (_) {
      return '00:00h';
    }
  }

  String _calcHace(String createdAtIso) {
    try {
      final dt = DateTime.parse(createdAtIso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'hace ${diff.inHours}h';
      if (diff.inDays == 1) return 'ayer';
      return 'hace ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

class HomeData {
  final NorayActivo? norayActivo;
  final List<ProximoAmarre> proximosAmarres;
  final List<RutaComunidad> rutas;

  const HomeData({
    this.norayActivo,
    this.proximosAmarres = const [],
    this.rutas = const [],
  });
}
```

**`home_provider.dart` (reemplazar completamente):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/home/models/home_models.dart';
import 'package:noray4/features/home/services/home_service.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final _service = HomeService();

  HomeNotifier() : super(const HomeState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.load();
      state = HomeState(
        norayActivo: data.norayActivo,
        proximosAmarres: data.proximosAmarres,
        rutas: data.rutas,
        isLoading: false,
      );
    } catch (e) {
      state = HomeState(isLoading: false);
    }
  }

  Future<void> refresh() => _load();

  void toggleFavorita(String rutaId) {
    state = state.copyWith(
      rutas: state.rutas.map((r) {
        if (r.id == rutaId) return r.copyWith(isFavorita: !r.isFavorita);
        return r;
      }).toList(),
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (_) => HomeNotifier(),
);
```

**Verification:**
```bash
flutter analyze lib/features/home/
# Expected: No issues found!
```

**Commit:**
```bash
git add lib/features/home/services/home_service.dart lib/features/home/providers/home_provider.dart
git commit -m "feat(home): replace mock with HomeService composing salas + amarres API"
```

---

## Verificación Final

### Task 11: Análisis estático + smoke test

**Layer:** Verification

**Commands:**
```bash
# Análisis completo del proyecto
flutter analyze

# Si hay errores de compilación en sala_screen.dart por SalaMessage sin riderId:
# Buscar cualquier creación de SalaMessage(...) sin riderId y añadir riderId: ''

# Build debug para verificar que compila
flutter build apk --debug

# Smoke test manual:
# 1. Abrir app → Login
# 2. Ir a Registros → debe mostrar spinner → luego amarres reales (o vacío)
# 3. Ir a Rutas → debe mostrar spinner → luego feed real (o vacío)
# 4. Ir a Home → debe mostrar spinner → luego datos reales
# 5. Ir a Sala (si hay salaId real) → debe cargar datos reales
```

**Commit:**
```bash
git add -A
git commit -m "fix: resolve any remaining SalaMessage/SalaRider field mismatches after model extension"
```

---

## Resumen de archivos por bloque

| Bloque | Archivos creados | Archivos modificados |
|--------|-----------------|---------------------|
| **Amarres** | `amarres/services/amarres_service.dart` | `amarres/models/amarres_models.dart`, `amarres/providers/amarres_provider.dart`, `amarres/amarres_screen.dart` |
| **Sala** | — | `sala/models/sala_models.dart`, `sala/providers/sala_provider.dart`, `sala/screens/crear_sala_screen.dart` |
| **Rutas** | `rutas/services/rutas_service.dart` | `rutas/models/rutas_models.dart`, `rutas/providers/rutas_provider.dart` |
| **Home** | `home/services/home_service.dart` | `home/providers/home_provider.dart` |

**Total: 4 archivos nuevos, 8 archivos modificados, 11 commits atómicos.**

---

*Plan generado el 2026-04-11. Ejecutar con `flutter-craft:flutter-executing`.*
