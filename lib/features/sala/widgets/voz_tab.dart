import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/auth/auth_provider.dart';
import 'package:noray4/core/services/haptics.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/shared/widgets/rider_avatar.dart';

class VozTab extends StatefulWidget {
  final SalaState sala;
  final VoidCallback onPttPressed;
  final VoidCallback onPttReleased;

  const VozTab({
    super.key,
    required this.sala,
    required this.onPttPressed,
    required this.onPttReleased,
  });

  @override
  State<VozTab> createState() => _VozTabState();
}

class _VozTabState extends State<VozTab> with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sala = widget.sala;
    return Padding(
      padding: const EdgeInsets.all(Noray4Spacing.s6),
      child: Column(
        children: [
          const SizedBox(height: Noray4Spacing.s4),
          // Status bar
          _VoiceStatusBar(isActive: sala.isVoiceActive, wave: _wave, activeSpeakerName: sala.activeSpeakerName),
          const SizedBox(height: Noray4Spacing.s8),
          // Riders list
          Expanded(
            child: ListView.separated(
              itemCount: sala.riders.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: Noray4Spacing.s4),
              itemBuilder: (context, i) {
                final sala = widget.sala;
                if (i == 0) {
                  return _RiderVoiceRow(
                    riderId: null,
                    initials: 'YO',
                    displayName: 'Tú',
                    isSpeaking: sala.isPttActive,
                    isYou: true,
                  );
                }
                final idx = i - 1;
                if (idx < sala.riders.length) {
                  final rider = sala.riders[idx];
                  final isSpeaking = rider.riderId != null &&
                      rider.riderId == sala.activeSpeakerId;
                  final isOnline = rider.riderId != null &&
                      sala.onlineRiderIds.contains(rider.riderId);
                  return _RiderVoiceRow(
                    riderId: rider.riderId,
                    initials: rider.initials,
                    displayName: rider.displayName ?? rider.initials,
                    isSpeaking: isSpeaking,
                    isOnline: isOnline,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: Noray4Spacing.s6),
          // PTT button
          _PttButton(
            isActive: sala.isPttActive,
            onPressed: () {
              N4Haptics.heavy();
              widget.onPttPressed();
            },
            onReleased: () {
              N4Haptics.light();
              widget.onPttReleased();
            },
          ),
        ],
      ),
    );
  }
}

class _VoiceStatusBar extends StatelessWidget {
  final bool isActive;
  final AnimationController wave;
  final String? activeSpeakerName;
  const _VoiceStatusBar({required this.isActive, required this.wave, this.activeSpeakerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Noray4Spacing.s4),
      decoration: BoxDecoration(
        color: Noray4Colors.darkSurfaceContainerLow,
        borderRadius: Noray4Radius.primary,
        border: Border.all(
          color: Noray4Colors.darkOutlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: wave,
            builder: (context, child) => Icon(
              Symbols.graphic_eq,
              fill: 1,
              size: 22,
              color: Noray4Colors.darkOnSurfaceVariant
                  .withValues(alpha: isActive ? 0.4 + wave.value * 0.6 : 0.2),
            ),
          ),
          const SizedBox(width: Noray4Spacing.s4),
          Text(
            activeSpeakerName != null
                ? '$activeSpeakerName habla...'
                : (isActive ? 'Canal de voz activo' : 'Canal listo'),
            style: Noray4TextStyles.body.copyWith(
              color: Noray4Colors.darkOnSurfaceVariant,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4ADE80)
                  : Noray4Colors.darkOutlineVariant,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderVoiceRow extends ConsumerWidget {
  final String? riderId;
  final String initials;
  final String? displayName;
  final bool isSpeaking;
  final bool isYou;
  final bool isOnline;

  const _RiderVoiceRow({
    required this.riderId,
    required this.initials,
    this.displayName,
    required this.isSpeaking,
    this.isYou = false,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isOnline
        ? Noray4Colors.darkPrimary
        : Noray4Colors.darkOnSurfaceVariant;
    final ownAvatar = isYou
        ? ref.watch(authProvider).user?.avatarUrl
        : null;
    return Opacity(
      opacity: isOnline ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(Noray4Spacing.s4),
        decoration: BoxDecoration(
          color: isSpeaking
              ? Noray4Colors.darkSurfaceContainerLow
              : Noray4Colors.darkSurfaceContainerLowest,
          borderRadius: Noray4Radius.primary,
          border: Border.all(
            color: isSpeaking
                ? Noray4Colors.darkPrimary.withValues(alpha: 0.15)
                : Noray4Colors.darkOutlineVariant.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSpeaking
                    ? Border.all(
                        color: Noray4Colors.darkPrimary.withValues(alpha: 0.4),
                        width: 1.5)
                    : null,
              ),
              padding: EdgeInsets.all(isSpeaking ? 1.5 : 0),
              child: RiderAvatarCircle(
                riderId: riderId,
                initials: initials,
                size: isSpeaking ? 37 : 40,
                overrideUrl: ownAvatar,
                backgroundColor: Noray4Colors.darkSurfaceContainerHighest,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Noray4Spacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isYou ? 'Tú' : (displayName ?? initials),
                    style: Noray4TextStyles.body.copyWith(
                      color: textColor,
                      fontWeight:
                          isSpeaking ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (!isYou && !isOnline)
                    Text(
                      'Sin señal',
                      style: Noray4TextStyles.bodySmall.copyWith(
                        color: Noray4Colors.darkOutline,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (isSpeaking)
              const Icon(Symbols.mic, fill: 1, size: 18,
                  color: Noray4Colors.darkPrimary)
            else
              Icon(
                isOnline ? Symbols.mic_off : Symbols.wifi_off,
                size: 18,
                color: const Color(0xFF474747),
              ),
          ],
        ),
      ),
    );
  }
}

class _PttButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  const _PttButton({
    required this.isActive,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased(),
      onTapCancel: onReleased,
      child: AnimatedScale(
        scale: isActive ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isActive
                  ? Noray4Colors.darkAccent
                  : Noray4Colors.darkAccent.withValues(alpha: 0.85),
            borderRadius: Noray4Radius.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActive ? Symbols.mic : Symbols.mic,
                  fill: isActive ? 1 : 0,
                  size: 24, color: const Color(0xFF0C1C20)),
              const SizedBox(width: 12),
              Text(isActive ? 'Hablando...' : 'Mantén para hablar',
                  style: Noray4TextStyles.headlineM.copyWith(
                    color: const Color(0xFF0C1C20),
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
