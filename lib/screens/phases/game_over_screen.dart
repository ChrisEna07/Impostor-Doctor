// lib/screens/phases/game_over_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _confetti.play();
    AudioService.instance.playVictory();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final winner = gp.winner;
    final sorted = gp.sortedByPoints;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppGradients.dark)),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
              numberOfParticles: 30,
              colors: const [
                AppTheme.primary, AppTheme.secondary, AppTheme.accent,
                Colors.white, Color(0xFFFFD700),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Trophy
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '🏆',
                          style: TextStyle(fontSize: 80),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(
                                end: 1.1,
                                duration: 1000.ms,
                                curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        const Text(
                          '¡Juego Terminado!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 8),
                        if (winner != null) ...[
                          const Text(
                            'Ganador',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          PlayerAvatar(name: winner.name, size: 80),
                          const SizedBox(height: 10),
                          Text(
                            winner.name,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD700),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                          Text(
                            '${winner.points} puntos',
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Marcador final
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Marcador Final',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...sorted.asMap().entries.map((e) {
                          final i = e.key;
                          final p = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Text(_rankEmoji(i),
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 12),
                                PlayerAvatar(name: p.name, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${p.points} pts',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: (i * 100).ms),
                          );
                        }),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                  const Spacer(),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: 'JUGAR DE NUEVO',
                          icon: Icons.refresh_rounded,
                          onPressed: () {
                            AudioService.instance.playClick();
                            gp.resetGame();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 12),
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

  String _rankEmoji(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}°';
    }
  }
}
