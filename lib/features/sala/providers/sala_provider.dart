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

      state = state.copyWith(
        nombre: sala.name,
        riders: riders,
        messages: messages,
        tiempo: _calcTiempo(sala.createdAt),
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
      // Mantener mensaje optimista sin rollback para no degradar UX
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

final salaProvider =
    StateNotifierProvider.family<SalaNotifier, SalaState, String>(
  (ref, salaId) {
    final myRiderId = ref.watch(authProvider).user?.id ?? '';
    return SalaNotifier(salaId, myRiderId);
  },
);
