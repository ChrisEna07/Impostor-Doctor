// lib/screens/doctor/phases/night_intro_screen.dart
// Pantalla de transición: todos cierran los ojos
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';

class NightIntroScreen extends StatefulWidget {
  const NightIntroScreen({super.key});

  @override
  State<NightIntroScreen> createState() => _NightIntroScreenState();
}

class _NightIntroScreenState extends State<NightIntroScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.startNight();
  }

  @override
  void dispose() {
    AudioService.instance.stopBackground();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050510), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge de ronda
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Noche ${gp.currentRound}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 48),

                // Luna
                const Text('🌙', style: TextStyle(fontSize: 90))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.08, duration: 2000.ms, curve: Curves.easeInOut)
                    .animate()
                    .fadeIn(duration: 800.ms),
                const SizedBox(height: 32),

                const Text(
                  'Cae la noche...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: 12),

                const Text(
                  '¡Todos cierren los ojos!\nNo abran hasta que se les indique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),

                // Estrellas decorativas
                const Text('✨ ⭐ 🌟 ⭐ ✨',
                    style: TextStyle(fontSize: 20))
                    .animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 64),

                GradientButton(
                  text: 'EL ASESINO DESPIERTA',
                  icon: Icons.dark_mode_rounded,
                  width: double.infinity,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFFE84040)],
                  ),
                  onPressed: () {
                    AudioService.instance.playClick();
                    gp.beginNightAssassin();
                  },
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
