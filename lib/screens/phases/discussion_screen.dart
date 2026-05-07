// lib/screens/phases/discussion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../services/multiplayer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  int _seconds = 120;
  Timer? _timer;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    // Iniciar música de suspenso durante la discusión
    AudioService.instance.startSuspense();
    // Al entrar a discusión, avisar a todos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MultiplayerService.instance.broadcastData({
        'type': 'phase_update',
        'phase': 'discussion',
        'time': _seconds,
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.instance.stopBackground();
    super.dispose();
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_seconds <= 0) {
          t.cancel();
          setState(() { _timerRunning = false; _seconds = 0; });
        } else {
          setState(() => _seconds--);
          // Broadcast timer update
          MultiplayerService.instance.broadcastData({
            'type': 'timer_update',
            'time': _seconds,
          });
        }
      });
      setState(() => _timerRunning = true);
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() { _seconds = 120; _timerRunning = false; });
  }

  String get _timeString {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_seconds > 60) return AppTheme.safeGreen;
    if (_seconds > 30) return const Color(0xFFE8A83D);
    return AppTheme.impostorRed;
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ronda ${gp.currentRound}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.forum_rounded,
                              color: AppTheme.accent, size: 16),
                          const SizedBox(width: 6),
                          const Text('Discusión',
                              style: TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 32),

                // Temporizador
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _timerColor.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _timerColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _timeString,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: _timerColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _timerRunning
                              ? 'Toca para pausar'
                              : 'Toca para iniciar',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppTheme.textSecondary, size: 18),
                      label: const Text('Reiniciar',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instrucción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded,
                          color: AppTheme.accent, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Discutan en grupo y traten de descubrir quién es el impostor. '
                          '¡El impostor intentará camuflarse!',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),

                // Jugadores
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: gp.players.length,
                    itemBuilder: (ctx, i) {
                      final p = gp.players[i];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayerAvatar(name: p.name, size: 56),
                          const SizedBox(height: 6),
                          Text(
                            p.name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${p.points} pts',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: (i * 80).ms);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                GradientButton(
                  text: 'PASAR A VOTACIÓN',
                  icon: Icons.how_to_vote_rounded,
                  width: double.infinity,
                  onPressed: () {
                    AudioService.instance.playClick();
                    MultiplayerService.instance.broadcastData({
                      'type': 'phase_update',
                      'phase': 'voting',
                    });
                    gp.startVoting();
                  },
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
