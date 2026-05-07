// lib/screens/doctor/phases/doctor_vote_result_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_player.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/multiplayer_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class DoctorVoteResultScreen extends StatefulWidget {
  const DoctorVoteResultScreen({super.key});

  @override
  State<DoctorVoteResultScreen> createState() => _DoctorVoteResultScreenState();
}

class _DoctorVoteResultScreenState extends State<DoctorVoteResultScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    final gp = context.read<DoctorGameProvider>();
    if (gp.eliminatedThisVote?.role == DoctorRole.asesino) {
      _confetti.play();
      AudioService.instance.playVictory();
    } else {
      AudioService.instance.playEliminate();
    }

    // Broadcast result
    MultiplayerService.instance.broadcastData({
      'type': 'phase_update',
      'phase': 'voteResult',
      'caught': gp.eliminatedThisVote?.role == DoctorRole.asesino,
      'eliminatedName': gp.eliminatedThisVote?.name ?? "Nadie",
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final eliminated = gp.eliminatedThisVote;
    final wasAssassin = eliminated?.role == DoctorRole.asesino;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: wasAssassin
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
              shouldLoop: false,
              numberOfParticles: 30,
              colors: const [
                Color(0xFF1A8C6A), Colors.white, Color(0xFFFFD700),
                Color(0xFF6C3DE8), AppTheme.secondary,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  if (eliminated != null) ...[
                    Text(wasAssassin ? '🎉' : '😢',
                        style: const TextStyle(fontSize: 80))
                        .animate()
                        .scale(begin: const Offset(0.3, 0.3), duration: 700.ms,
                            curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      wasAssassin
                          ? '¡Atraparon al Asesino!'
                          : 'El pueblo eliminó a un inocente...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: wasAssassin ? const Color(0xFF40E87A) : AppTheme.impostorRed,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 28),

                    // Card del eliminado
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: wasAssassin
                              ? const Color(0xFF1A8C6A).withValues(alpha: 0.5)
                              : AppTheme.impostorRed.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (wasAssassin
                                ? const Color(0xFF1A8C6A)
                                : AppTheme.impostorRed).withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(children: [
                        PlayerAvatar(name: eliminated.name, size: 80),
                        const SizedBox(height: 14),
                        Text(eliminated.name,
                            style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: wasAssassin
                                ? const LinearGradient(
                                    colors: [Color(0xFF1A8C6A), Color(0xFF0D4D3A)])
                                : const LinearGradient(
                                    colors: [Color(0xFF8B0000), Color(0xFFE84040)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${eliminated.role.emoji} ${eliminated.role.label}',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                    // Conteo de votos
                    const SizedBox(height: 20),
                    _buildVoteSummary(gp),
                  ] else ...[
                    const Text('Sin consenso — empate en votos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                  ],
                  const Spacer(),
                  GradientButton(
                    text: 'CONTINUAR',
                    icon: Icons.arrow_forward_rounded,
                    width: double.infinity,
                    onPressed: () {
                      AudioService.instance.playClick();
                      gp.continueAfterVoteResult();
                    },
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSummary(DoctorGameProvider gp) {
    final votes = gp.votes;
    if (votes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recuento de votos',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...gp.alivePlayers.where((p) => p.votesReceived > 0).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              PlayerAvatar(name: p.name, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(p.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
              Text('${p.votesReceived} voto${p.votesReceived > 1 ? "s" : ""}',
                  style: const TextStyle(color: AppTheme.primary,
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          )),
          ...gp.eliminatedHistory
              .where((p) => p.votesReceived > 0 &&
                  gp.eliminatedThisVote?.id == p.id)
              .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  PlayerAvatar(name: p.name, size: 30),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                  Text('${p.votesReceived} voto${p.votesReceived > 1 ? "s" : ""}',
                      style: const TextStyle(color: AppTheme.primary,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}
