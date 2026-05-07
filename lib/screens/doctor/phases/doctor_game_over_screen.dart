// lib/screens/doctor/phases/doctor_game_over_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_player.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class DoctorGameOverScreen extends StatefulWidget {
  const DoctorGameOverScreen({super.key});

  @override
  State<DoctorGameOverScreen> createState() => _DoctorGameOverScreenState();
}

class _DoctorGameOverScreenState extends State<DoctorGameOverScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    final gp = context.read<DoctorGameProvider>();
    _confetti.play();
    if (gp.winner == DoctorWinner.village) {
      AudioService.instance.playVictory();
    } else {
      AudioService.instance.playDefeat();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final villageWon = gp.winner == DoctorWinner.village;
    final sorted = gp.sortedByPoints;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: villageWon
                    ? [const Color(0xFF003020), AppTheme.bgDark]
                    : [const Color(0xFF1A0000), AppTheme.bgDark],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
              numberOfParticles: villageWon ? 30 : 10,
              colors: villageWon
                  ? const [
                      Color(0xFF1A8C6A), Colors.white, Color(0xFFFFD700),
                      Color(0xFF3DE8D4), Color(0xFF6C3DE8)]
                  : const [Color(0xFF8B0000), Colors.red, Colors.black],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Resultado principal
                  Column(
                    children: [
                      Text(villageWon ? '🏆' : '🔪',
                          style: const TextStyle(fontSize: 80))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(end: 1.1, duration: 1000.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 16),
                      Text(
                        villageWon ? '¡El Pueblo Ganó!' : '¡El Asesino Ganó!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: villageWon ? const Color(0xFF40E87A) : AppTheme.impostorRed,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 6),
                      Text(
                        villageWon
                            ? 'Todos los asesinos fueron descubiertos 🎉'
                            : 'El asesino se apoderó del pueblo 😈',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Marcador
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.surfaceLight),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Text('Marcador Final',
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 16),
                            ...sorted.asMap().entries.map((e) {
                              final i = e.key;
                              final p = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(children: [
                                  Text(_rankEmoji(i),
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  PlayerAvatar(name: p.name, size: 38),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: p.isAlive
                                                  ? AppTheme.textPrimary
                                                  : AppTheme.textSecondary,
                                            )),
                                        Text(
                                          '${p.role.emoji} ${p.role.label}'
                                          '${p.isAlive ? "" : " · ☠️"}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${p.points} pts',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: p.role == DoctorRole.asesino
                                            ? AppTheme.impostorRed
                                            : AppTheme.primary,
                                      )),
                                ]).animate().fadeIn(delay: (i * 80).ms),
                              );
                            }),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  ),
                  const SizedBox(height: 20),

                  // Botones
                  GradientButton(
                    text: 'JUGAR DE NUEVO',
                    icon: Icons.refresh_rounded,
                    width: double.infinity,
                    gradient: villageWon
                        ? const LinearGradient(
                            colors: [Color(0xFF1A8C6A), Color(0xFF0D4D3A)])
                        : const LinearGradient(
                            colors: [Color(0xFF8B0000), Color(0xFFE84040)]),
                    onPressed: () {
                      AudioService.instance.playClick();
                      gp.resetGame();
                      Navigator.of(context).pop();
                    },
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      AudioService.instance.playClick();
                      gp.fullReset();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.home_rounded,
                        color: AppTheme.textSecondary),
                    label: const Text('Cambiar jugadores',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rankEmoji(int i) {
    switch (i) { case 0: return '🥇'; case 1: return '🥈'; case 2: return '🥉';
    default: return '${i + 1}°'; }
  }
}
