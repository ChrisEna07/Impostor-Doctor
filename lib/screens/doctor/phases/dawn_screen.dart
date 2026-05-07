// lib/screens/doctor/phases/dawn_screen.dart
// Amanece — se revela si alguien murió o fue salvado
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

class DawnScreen extends StatefulWidget {
  const DawnScreen({super.key});

  @override
  State<DawnScreen> createState() => _DawnScreenState();
}

class _DawnScreenState extends State<DawnScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    final gp = context.read<DoctorGameProvider>();
    if (gp.savedThisNight) {
      _confetti.play();
      AudioService.instance.playSave();
    } else {
      AudioService.instance.playEliminate();
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
    final saved = gp.savedThisNight;
    final victim = gp.dawnVictim;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo dinámico
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: saved
                    ? [const Color(0xFF003020), AppTheme.bgDark]
                    : [const Color(0xFF1A0000), AppTheme.bgDark],
              ),
            ),
          ),

          // Confetti si fue salvado
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF1A8C6A), Colors.white, Color(0xFF40E87A),
                Color(0xFF3DE8D4), Color(0xFF6C3DE8),
              ],
              numberOfParticles: 30,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Ícono principal
                  Text(saved ? '☀️' : '💀', style: const TextStyle(fontSize: 90))
                      .animate()
                      .scale(begin: const Offset(0.3, 0.3), duration: 700.ms,
                          curve: Curves.elasticOut),
                  const SizedBox(height: 24),

                  Text(
                    saved ? '¡El Doctor Salvó a Alguien!' : 'Alguien ha muerto...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: saved ? const Color(0xFF40E87A) : AppTheme.impostorRed,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  const SizedBox(height: 28),

                  if (saved) ...[
                    // Nadie murió
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A8C6A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF1A8C6A).withValues(alpha: 0.5)),
                      ),
                      child: const Column(
                        children: [
                          Text('💉', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 8),
                          Text(
                            'El Doctor intervino a tiempo.\n¡Esta noche nadie murió!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(
                        begin: const Offset(0.8, 0.8), duration: 400.ms),
                  ] else if (victim != null) ...[
                    // Alguien murió
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.impostorRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.impostorRed.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          PlayerAvatar(name: victim.name, size: 70),
                          const SizedBox(height: 12),
                          Text(victim.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            'fue eliminado${victim.name.endsWith('a') ? 'a' : ''} por el asesino',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.impostorRed.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${victim.role.emoji} Era ${victim.role.label}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Esta noche no hubo víctimas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                    ),
                  ],

                  const Spacer(),
                  GradientButton(
                    text: 'IR A LA DISCUSIÓN',
                    icon: Icons.wb_sunny_rounded,
                    width: double.infinity,
                    onPressed: () {
                      AudioService.instance.playClick();
                      gp.startDiscussion();
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
}
