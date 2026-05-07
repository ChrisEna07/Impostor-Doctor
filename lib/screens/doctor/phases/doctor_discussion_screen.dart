// lib/screens/doctor/phases/doctor_discussion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/multiplayer_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class DoctorDiscussionScreen extends StatefulWidget {
  const DoctorDiscussionScreen({super.key});

  @override
  State<DoctorDiscussionScreen> createState() => _DoctorDiscussionScreenState();
}

class _DoctorDiscussionScreenState extends State<DoctorDiscussionScreen> {
  int _seconds = 120;
  Timer? _timer;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    AudioService.instance.startSuspense();
    // Avisar a todos
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

  String get _timeStr {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final alive = gp.alivePlayers;
    final dead = gp.eliminatedHistory;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(children: [
                  const Text('☀️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ronda ${gp.currentRound} — Discusión',
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      Text('${alive.length} jugadores vivos • ${dead.length} eliminados',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
                  ),
                ]).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Temporizador
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _seconds <= 20
                          ? AppTheme.impostorRed.withValues(alpha: 0.6)
                          : AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(children: [
                    Text(_timeStr,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: _seconds <= 20 ? AppTheme.impostorRed : AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      OutlinedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_timerRunning ? 'Pausar' : 'Iniciar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppTheme.textSecondary),
                      ),
                    ]),
                  ]),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),

                // Vivos
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jugadores vivos',
                            style: TextStyle(color: AppTheme.textSecondary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: alive.map((p) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlayerAvatar(name: p.name, size: 50),
                              const SizedBox(height: 4),
                              Text(p.name,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          )).toList(),
                        ),
                        if (dead.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('Eliminados',
                              style: TextStyle(color: AppTheme.textSecondary,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: dead.map((p) => Opacity(
                              opacity: 0.4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(children: [
                                    PlayerAvatar(name: p.name, size: 44),
                                    const Positioned(right: 0, top: 0,
                                        child: Text('💀', style: TextStyle(fontSize: 14))),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(p.name,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'VOTAR AL ASESINO',
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
