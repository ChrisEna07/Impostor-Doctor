// lib/screens/phases/result_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../services/multiplayer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    final gp = context.read<GameProvider>();
    if (gp.impostorCaught) {
      _confetti.play();
      AudioService.instance.playVictory();
    } else {
      AudioService.instance.playDefeat();
    }

    // Broadcast result phase
    MultiplayerService.instance.broadcastData({
      'type': 'phase_update',
      'phase': 'result',
      'caught': gp.impostorCaught,
      'eliminatedName': gp.eliminatedPlayer?.name ?? "Nadie",
      'normalWord': gp.currentWordPair?.normal ?? "",
      'impostorWord': gp.currentWordPair?.impostor ?? "",
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final eliminated = gp.eliminatedPlayer!;
    final impostor = gp.players[gp.impostorIndex];
    final caught = gp.impostorCaught;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: BoxDecoration(
              gradient: caught ? AppGradients.safe : AppGradients.impostor,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.bgDark],
                stops: [0.3, 1.0],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primary,
                AppTheme.secondary,
                AppTheme.accent,
                AppTheme.safeGreen,
                Colors.white,
              ],
              numberOfParticles: 40,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Resultado principal
                  Column(
                    children: [
                      Text(
                        caught ? '🎉 ¡Impostor Atrapado!' : '😈 El Impostor Sobrevivió',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: caught ? 32 : 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
                      const SizedBox(height: 32),

                      // Avatar eliminado
                      PlayerAvatar(
                        name: eliminated.name,
                        isImpostor: eliminated.isImpostor,
                        revealed: true,
                        size: 100,
                      ).animate().scale(
                          begin: const Offset(0.3, 0.3),
                          delay: 300.ms,
                          duration: 600.ms,
                          curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(
                        eliminated.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      Text(
                        eliminated.isImpostor ? '👿 Era el Impostor' : '😇 Era inocente',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Palabra del impostor revelada
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Las palabras eran:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _wordTile(
                                label: 'Jugadores',
                                word: gp.currentWordPair!.normal,
                                color: AppTheme.safeGreen,
                                icon: Icons.people_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _wordTile(
                                label: 'Impostor',
                                word: gp.currentWordPair!.impostor,
                                color: AppTheme.impostorRed,
                                icon: Icons.masks_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Categoría: ${gp.currentWordPair!.category}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),

                  const SizedBox(height: 24),

                  // El impostor era (si es que el eliminado era inocente)
                  if (!caught) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.impostorRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.impostorRed.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(name: impostor.name, size: 44),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('El impostor era:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                impostor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.impostorRed,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text('👿',
                              style: TextStyle(fontSize: 28)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 16),
                  ],

                  // Puntos ganados
                  _buildPointsEarned(gp, caught)
                      .animate()
                      .fadeIn(delay: 900.ms)
                      .slideY(begin: 0.2),

                  const Spacer(),
                  GradientButton(
                    text: 'VER MARCADOR',
                    icon: Icons.leaderboard_rounded,
                    width: double.infinity,
                    onPressed: () {
                      AudioService.instance.playClick();
                      gp.continueAfterResult();
                    },
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordTile({
    required String label,
    required String word,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsEarned(GameProvider gp, bool caught) {
    final lines = <String>[];
    if (caught) {
      for (final e in gp.votes.entries) {
        if (e.value == gp.players[gp.impostorIndex].id) {
          final voter = gp.players.firstWhere((p) => p.id == e.key);
          lines.add(
              '${voter.name} +${gp.settings.pointsForCorrectVote} pts');
        }
      }
    } else {
      lines.add(
          '${gp.players[gp.impostorIndex].name} +${gp.settings.pointsForSurviving} pts');
    }
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Puntos ganados',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(l,
                    style: const TextStyle(
                        color: AppTheme.safeGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              )),
        ],
      ),
    );
  }
}
