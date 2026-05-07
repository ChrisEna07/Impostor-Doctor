// lib/screens/phases/round_end_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class RoundEndScreen extends StatelessWidget {
  const RoundEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final sorted = gp.sortedByPoints;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Fin de Ronda ${gp.currentRound}',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Marcador',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                // Podio top 3
                if (sorted.length >= 3)
                  _buildPodium(sorted).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Lista completa
                Expanded(
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (ctx, i) {
                      final p = sorted[i];
                      final isFirst = i == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isFirst ? AppGradients.primary : null,
                            color: isFirst ? null : AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFirst
                                  ? Colors.transparent
                                  : AppTheme.surfaceLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Posición
                              SizedBox(
                                width: 32,
                                child: Text(
                                  _rankEmoji(i),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              PlayerAvatar(name: p.name, size: 44),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isFirst
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              // Puntos
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${p.points} pts',
                                  style: TextStyle(
                                    color: isFirst
                                        ? Colors.white
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: -0.2),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AudioService.instance.playClick();
                          gp.resetGame();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('Inicio'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.surfaceLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        text: 'SIG. RONDA',
                        icon: Icons.play_arrow_rounded,
                        compact: true,
                        onPressed: () {
                          AudioService.instance.playClick();
                          gp.startNextRound();
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<dynamic> sorted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2do puesto
        if (sorted.length > 1)
          _podiumItem(sorted[1], 2, 70),
        const SizedBox(width: 12),
        // 1er puesto
        _podiumItem(sorted[0], 1, 100),
        const SizedBox(width: 12),
        // 3er puesto
        if (sorted.length > 2)
          _podiumItem(sorted[2], 3, 55),
      ],
    );
  }

  Widget _podiumItem(dynamic player, int rank, double height) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(name: player.name, size: rank == 1 ? 56 : 44),
        const SizedBox(height: 6),
        Text(
          player.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${player.points} pts',
          style: TextStyle(
            fontSize: 11,
            color: colors[rank],
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: colors[rank]!.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: colors[rank]!.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              _rankEmoji(rank - 1),
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
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
