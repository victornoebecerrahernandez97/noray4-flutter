import 'dart:async';

import 'package:dio/dio.dart';

import 'package:noray4/core/network/api_client.dart';
import 'package:noray4/core/network/api_endpoints.dart';

class PttState {
  final String canalId;
  final String? speakerId;
  final String? speakerName;
  final bool isSpeaking;

  const PttState({
    required this.canalId,
    this.speakerId,
    this.speakerName,
    required this.isSpeaking,
  });

  factory PttState.fromJson(Map<String, dynamic> json) => PttState(
        canalId: json['canal_id'] as String? ?? 'general',
        speakerId: json['speaker_id'] as String?,
        speakerName: json['speaker_name'] as String?,
        isSpeaking: json['is_speaking'] as bool? ?? false,
      );
}

class VoiceService {
  final String salaId;
  final String myRiderId;
  final void Function(PttState state) onPttStateChanged;

  final Dio _dio = ApiClient.instance.dio;
  Timer? _autoReleaseTimer;
  bool _isSpeaking = false;

  static const _autoReleaseDuration = Duration(seconds: 30);
  static const _defaultCanal = 'general';

  VoiceService({
    required this.salaId,
    required this.myRiderId,
    required this.onPttStateChanged,
  });

  Future<void> startPtt({String canalId = _defaultCanal}) async {
    if (_isSpeaking) return;
    try {
      final res = await _dio.post(
        ApiEndpoints.voicePtt(salaId),
        data: {'action': 'start', 'canal_id': canalId},
      );
      final pttState = PttState.fromJson(res.data as Map<String, dynamic>);
      if (pttState.speakerId == myRiderId) {
        _isSpeaking = true;
        _autoReleaseTimer = Timer(_autoReleaseDuration, () => stopPtt(canalId: canalId));
        onPttStateChanged(pttState);
      } else {
        onPttStateChanged(pttState);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Canal ocupado — ignorar silenciosamente
      }
    }
  }

  Future<void> stopPtt({String canalId = _defaultCanal}) async {
    if (!_isSpeaking) return;
    _autoReleaseTimer?.cancel();
    _isSpeaking = false;
    try {
      final res = await _dio.post(
        ApiEndpoints.voicePtt(salaId),
        data: {'action': 'stop', 'canal_id': canalId},
      );
      final pttState = PttState.fromJson(res.data as Map<String, dynamic>);
      onPttStateChanged(pttState);
    } catch (_) {
      // Fallo silencioso — estado local ya reseteado
    }
  }

  void dispose() {
    _autoReleaseTimer?.cancel();
    if (_isSpeaking) {
      stopPtt();
    }
  }
}
