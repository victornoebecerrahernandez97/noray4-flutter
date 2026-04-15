import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:noray4/features/sala/models/ws_events.dart';

enum WsStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  final String salaId;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _retryCount = 0;

  final _eventController = StreamController<WsEvent>.broadcast();
  final _statusController = StreamController<WsStatus>.broadcast();

  Stream<WsEvent> get events => _eventController.stream;
  Stream<WsStatus> get status => _statusController.stream;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _baseWsUrl = 'wss://web-production-66456.up.railway.app';

  WebSocketManager({required this.salaId});

  Future<void> connect() async {
    if (_disposed) return;
    _statusController.add(WsStatus.connecting);

    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      _statusController.add(WsStatus.error);
      return;
    }

    final uri = Uri.parse('$_baseWsUrl/ws/$salaId?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _retryCount = 0;
      _statusController.add(WsStatus.connected);

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _onDisconnected(),
        onDone: _onDisconnected,
        cancelOnError: true,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    if (_disposed) return;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = parseWsEnvelope(map);
      if (event != null) _eventController.add(event);
    } catch (_) {
      // malformed frame — ignorar
    }
  }

  void _onDisconnected() {
    if (_disposed) return;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(WsStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final delay = Duration(seconds: min(30, pow(2, _retryCount).toInt()));
    _retryCount++;
    _reconnectTimer = Timer(delay, connect);
  }

  /// Envía un frame JSON upstream por el canal WS activo.
  /// No-op si el canal está cerrado o el manager fue disposed.
  void send(Map<String, dynamic> frame) {
    if (_disposed || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(frame));
    } catch (_) {
      // Canal cerrado entre la comprobación y el envío — ignorar
    }
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _eventController.close();
    _statusController.close();
  }
}
