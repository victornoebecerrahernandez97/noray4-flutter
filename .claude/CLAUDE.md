# Noray4 Mobile — Claude Brain

## Identity
- **Stack target:** Flutter 3.24+ / Dart 3.5+
- **App principal de riders** — experiencia completa: convocar salidas, push-to-talk, mapa en vivo, chat, registros de viaje
- **Plataformas:** iOS + Android (desktop/web fuera de scope MVP)

> Este archivo hereda del `CLAUDE.md` raíz de `noray4/`. El glosario oficial de UI, design tokens y filosofía Functional Stoicism aplican aquí SIN excepción.

---

## Flujo de trabajo obligatorio
1. **Plan Mode** (`Shift+Tab ×2`) antes de tocar cualquier feature con más de un archivo
2. **context7** → SIEMPRE antes de escribir código con Flutter, Riverpod, GoRouter, freezed, dio, mqtt_client o cualquier paquete externo (las APIs cambian entre versiones)
3. **sequential-thinking** → para arquitectura de providers, flujos async complejos, o bugs de estado multi-screen
4. `flutter analyze` y `flutter test` antes de considerar cualquier tarea terminada

---

## Stack definitivo

| Área              | Paquete                          | Justificación                                   |
|-------------------|----------------------------------|-------------------------------------------------|
| Estado            | `flutter_riverpod` + `riverpod_generator` | Code-gen, AsyncValue, autoDispose        |
| Modelos           | `freezed` + `json_serializable`  | Immutables, union types, equality               |
| Navegación        | `go_router`                      | Declarativa, deep links, guards                 |
| HTTP              | `dio` + `dio_cache_interceptor`  | Interceptors, retry, cache                      |
| Auth              | `firebase_auth` + `flutter_secure_storage` | Google sign-in + token local seguro   |
| Realtime          | `mqtt_client` (TLS)              | Bridge vía backend a HiveMQ Cloud               |
| Mapa              | `flutter_map` + `latlong2`       | OSM, sin costos por tile                        |
| Voz (PTT)         | `flutter_sound` + WebRTC         | Push-to-talk en sala                            |
| Imágenes          | `cloudinary_flutter`             | Upload directo, transformaciones                |
| Iconos            | `Icons` Material Symbols outlined | Peso 400, thin stroke                          |
| Fuente            | `google_fonts` → Inter           | Weight 500 global                               |

---

## Arquitectura: Features-first + Clean layering

```
noray4-flutter/
├── lib/
│   ├── main.dart                  ← runApp + ProviderScope
│   ├── app.dart                   ← MaterialApp.router + theme + observers
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart     ← ThemeData light/dark
│   │   │   ├── app_colors.dart    ← ThemeExtension<AppColors>
│   │   │   ├── app_text.dart      ← TextTheme con Inter
│   │   │   └── app_spacing.dart   ← ThemeExtension<AppSpacing>
│   │   ├── router/
│   │   │   ├── app_router.dart    ← GoRouter + refreshListenable
│   │   │   ├── routes.dart        ← Enum de rutas (type-safe)
│   │   │   └── guards.dart        ← redirect para auth
│   │   ├── network/
│   │   │   ├── dio_client.dart    ← Factory con interceptors
│   │   │   ├── auth_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart
│   │   ├── mqtt/
│   │   │   └── mqtt_client_provider.dart
│   │   └── widgets/
│   │       ├── n4_button.dart
│   │       ├── n4_card.dart
│   │       ├── n4_pill.dart
│   │       ├── n4_hairline.dart
│   │       ├── n4_app_bar.dart
│   │       ├── n4_bottom_nav.dart
│   │       ├── n4_ptt_button.dart
│   │       └── n4_empty_state.dart
│   ├── features/
│   │   ├── auth/                  ← Sprint 1 — ms_auth
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_api.dart
│   │   │   ├── domain/
│   │   │   │   └── user.dart
│   │   │   ├── application/
│   │   │   │   └── auth_controller.dart   ← @riverpod Notifier
│   │   │   └── presentation/
│   │   │       ├── login_screen.dart
│   │   │       └── onboarding_screen.dart
│   │   ├── riders/                ← Sprint 1 — ms_riders (perfil propio + tripulación)
│   │   ├── salidas/               ← Sprint 1 — ms_salas (convocar, listar, unirse)
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   │   ├── salida.dart
│   │   │   │   └── visibilidad.dart
│   │   │   ├── application/
│   │   │   │   ├── salidas_list_controller.dart
│   │   │   │   └── convocar_controller.dart
│   │   │   └── presentation/
│   │   │       ├── home_screen.dart           ← próximas salidas + convocar
│   │   │       ├── convocar_screen.dart
│   │   │       ├── salida_en_curso_screen.dart
│   │   │       └── widgets/
│   │   ├── realtime/              ← Sprint 1 — ms_realtime (MQTT bridge)
│   │   ├── chat/                  ← Sprint 1 — ms_chat
│   │   ├── location/              ← Sprint 2 — ms_location (mapa compartido)
│   │   ├── voice/                 ← Sprint 2 — ms_voice (PTT)
│   │   ├── amarres/               ← Sprint 2 — ms_amarres (Registros de viaje)
│   │   ├── groups/                ← Sprint 3 — ms_groups (Tripulaciones)
│   │   └── settings/
│   └── shared/
│       ├── models/                ← Modelos compartidos entre features
│       ├── extensions/
│       └── utils/
├── test/
├── assets/
│   ├── fonts/
│   └── images/
├── pubspec.yaml
├── analysis_options.yaml          ← very_good_analysis + reglas custom
└── .env.example
```

### Capas por feature
- **data/** → `*_repository.dart` (interfaz) + `*_api.dart` (Dio calls) + DTOs
- **domain/** → Entidades (freezed), enums, excepciones específicas
- **application/** → Controllers Riverpod (`@riverpod` con code-gen), casos de uso
- **presentation/** → Screens + widgets específicos del feature

> Regla: un widget de feature NO puede importar de otro feature. Si lo necesita, sube a `core/widgets/` o `shared/`.

---

## Routing con GoRouter

### Patrón type-safe
```dart
enum AppRoute {
  login('/login'),
  home('/'),
  convocar('/convocar'),
  salidaEnCurso('/salida/:id'),
  registros('/registros'),
  tripulacion('/tripulacion'),
  perfil('/perfil');

  final String path;
  const AppRoute(this.path);
}
```

### Guards
- `redirect` en `GoRouter` → si no autenticado y la ruta no es `/login`, redirigir a `/login`
- `refreshListenable` conectado al `authControllerProvider` para reaccionar a logout
- Rutas protegidas se declaran en un `ShellRoute` con `BottomNav` persistente

---

## Estado con Riverpod (code-gen)

### Regla de oro
- **SIEMPRE** `@riverpod` con generador — nunca `StateProvider` manual a menos que sea trivial
- **SIEMPRE** `autoDispose` por defecto — mantener `keepAlive` solo para auth y perfil propio
- **NUNCA** `setState` a nivel de Screen — siempre via Notifier

### Patrón Controller (con code-gen)
```dart
@riverpod
class SalidasListController extends _$SalidasListController {
  @override
  Future<List<Salida>> build({required Visibilidad filtro}) async {
    final repo = ref.watch(salidasRepositoryProvider);
    return repo.listar(filtro: filtro);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(filtro: Visibilidad.publica));
  }
}
```

### Consumo en UI
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salidas = ref.watch(salidasListControllerProvider(filtro: Visibilidad.publica));
    return salidas.when(
      data: (list) => _SalidasList(items: list),
      loading: () => const _SalidasSkeleton(),
      error: (e, _) => N4EmptyState.error(onRetry: () => ref.invalidate(...)),
    );
  }
}
```

---

## Theming: Monolith Framework en Flutter

### `AppColors` como `ThemeExtension`
```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surfaceCard;
  final Color surfaceMuted;
  final Color border;          // SIEMPRE se usa con width: 0.5
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // copyWith, lerp, y dos fábricas: AppColors.light() y AppColors.dark()
}
```

### Uso en widgets
```dart
final colors = Theme.of(context).extension<AppColors>()!;
Container(
  decoration: BoxDecoration(
    color: colors.surfaceCard,
    border: Border.all(color: colors.border, width: 0.5),
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### Tipografía
- `GoogleFonts.interTextTheme()` como base → aplicar weight 500 global
- `letterSpacing: -0.02` en headlines y body
- `textTheme` con roles definidos: `displayLarge` (wordmark), `headlineLarge` (32px), `titleMedium` (20px), `bodyLarge` (14px), `labelSmall` (10px caps tracking +0.05)

---

## Reglas absolutas Flutter

### Siempre
- `const` constructors por defecto — el linter debe marcar cualquier widget sin const como warning
- Widgets stateless salvo que haya razón concreta para stateful
- `ConsumerWidget` / `ConsumerStatefulWidget` — nunca `StatefulWidget` puro si hay acceso a providers
- Nombrar archivos `snake_case.dart`, clases `PascalCase`, selectores de prefix para widgets custom: `N4Button`, `N4Card`
- Máximo **200 líneas por widget** — si crece, extraer a sub-widgets privados (`_SalidaCard`, `_SalidaHeader`)
- Animaciones usan `AnimatedSwitcher`, `AnimatedOpacity`, `AnimatedContainer` — nunca implícitas con `Tween` manual salvo necesidad real
- Loading states con **skeleton** custom (`ShimmerBox`), nunca `CircularProgressIndicator` centrado

### Nunca
- **Nunca** `setState` a nivel de `Screen` — usar Riverpod Notifier
- **Nunca** hardcodear colores — siempre via `Theme.of(context).extension<AppColors>()!`
- **Nunca** hardcodear strings de UI — via `AppStrings` (y en el futuro `intl`)
- **Nunca** usar `print` — `debugPrint` o logger estructurado
- **Nunca** shadows (`BoxShadow`) — tonal shifts con `surface-*` tokens
- **Nunca** `BorderRadius.circular(>12)` excepto pills (`StadiumBorder`)
- **Nunca** iconos coloreados — Material Symbols outlined, peso 400, `color: colors.textPrimary`
- **Nunca** `FutureBuilder` / `StreamBuilder` en UI de feature — envolver en Riverpod provider
- **Nunca** llamadas HTTP directas desde UI — siempre via Repository

---

## Design decisions específicas

### Bottom Navigation
- `N4BottomNav` custom — NO `BottomNavigationBar` de Material
- Glassmorphism: `BackdropFilter(sigmaX: 20, sigmaY: 20)` + color al 80% opacity
- Border top: `0.5px` con `border.withOpacity(0.4)`
- Iconos Material Symbols: FILL 0 inactivo, FILL 1 activo + `scale: 1.1`
- 4 tabs: Salidas, Mapa, Registros, Tripulación

### Botón PTT (Push-to-Talk)
- `GestureDetector` con `onLongPressStart` / `onLongPressEnd`
- Haptic feedback en start (`HapticFeedback.mediumImpact`)
- Ring animado durante grabación (`CustomPainter`)
- Ancho completo, height 64px, radius 12, peso de texto 700 (única excepción al no-700)

### Live indicator
- Dot 6px, color `#E11D48`, `animate-pulse` via `AnimationController` 1.2s loop
- Siempre pareado con texto "Salida en curso" en `labelSmall` uppercase tracking +0.05

---

## Integración con backend

### Base URL
- Dev: `http://10.0.2.2:8000/api/v1` (Android emulador) / `http://localhost:8000/api/v1` (iOS sim)
- Prod: `https://api.noray4.com/api/v1`
- Inyectada via `--dart-define=API_URL=...` en build

### Headers obligatorios
- `Authorization: Bearer <jwt>` → via `auth_interceptor`
- `X-Client: noray4-flutter/{version}` → via interceptor global
- `Accept: application/json`

### Mapeo de módulos backend → features
| Módulo FastAPI    | Feature Flutter | Sprint |
|-------------------|-----------------|--------|
| ms_auth           | auth            | 1      |
| ms_riders         | riders          | 1      |
| ms_salas          | salidas         | 1      |
| ms_realtime       | realtime        | 1      |
| ms_chat           | chat            | 1      |
| ms_location       | location        | 2      |
| ms_voice          | voice           | 2      |
| ms_amarres        | amarres         | 2      |
| ms_groups         | groups          | 3      |

### Realtime / MQTT
- Conexión al WebSocket bridge expuesto por `ms_realtime` (TLS, auth via JWT como query param)
- Provider `mqttClientProvider` (keepAlive: true) — conecta en login, desconecta en logout
- Topics: `salida/{id}/chat`, `salida/{id}/location`, `salida/{id}/voice`

---

## Build Commands

```bash
# Dev
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1

# Code-gen (Riverpod + freezed + json_serializable)
dart run build_runner watch --delete-conflicting-outputs

# Análisis estático
flutter analyze
dart format lib test

# Tests
flutter test
flutter test --coverage

# Build Android
flutter build apk --release --dart-define=API_URL=https://api.noray4.com/api/v1
flutter build appbundle --release --dart-define=API_URL=https://api.noray4.com/api/v1

# Build iOS
flutter build ipa --release --dart-define=API_URL=https://api.noray4.com/api/v1

# Limpiar cache cuando algo se rompa inexplicablemente
flutter clean && flutter pub get
```

---

## Testing mínimo exigido

- **Widget tests** para cada componente en `core/widgets/`
- **Unit tests** para cada Controller Riverpod (usar `ProviderContainer` + overrides)
- **Golden tests** para pantallas clave (login, home, convocar, salida en curso) — uno en light, uno en dark
- **Integration test** del happy path completo: login → convocar → unirse → cerrar salida

---

## Orden de implementación recomendado (Sprint 1)

1. `core/theme/` + `core/widgets/` base (n4_button, n4_card, n4_hairline, n4_app_bar)
2. `features/auth/` → Google Sign-In + JWT storage
3. `core/router/` → GoRouter con guard de auth
4. `features/salidas/` → listar, convocar, detalle
5. `features/riders/` → perfil propio mínimo
6. `core/mqtt/` + `features/realtime/` → conexión al bridge
7. `features/chat/` → chat en salida activa
8. Integration test end-to-end
