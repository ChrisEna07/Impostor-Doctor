// lib/screens/doctor/phases/night_doctor_screen.dart
// El doctor elige a quién salvar (privado)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_player.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class NightDoctorScreen extends StatefulWidget {
  const NightDoctorScreen({super.key});

  @override
  State<NightDoctorScreen> createState() => _NightDoctorScreenState();
}

class _NightDoctorScreenState extends State<NightDoctorScreen> {
  int _step = 0;
  bool _confirming = false;
  String? _selectedSaveId;

  static const _doctorGreen = Color(0xFF1A8C6A);
  static const _doctorGradient = LinearGradient(
    colors: [Color(0xFF1A8C6A), Color(0xFF0D4D3A)],
  );

  void _confirm() {
    setState(() => _confirming = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() { _step = 1; _confirming = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final doctor = gp.players.firstWhere((p) => p.role == DoctorRole.doctor);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF001A10), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: _step == 0
              ? _buildConfirm(doctor)
              : _buildChoose(gp, doctor),
        ),
      ),
    );
  }

  Widget _buildConfirm(DoctorPlayer doctor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💉', style: TextStyle(fontSize: 72))
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 600.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 28),
          const Text('El doctor despierta...', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Pasa el celular a:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          Text(doctor.name,
              style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900, color: _doctorGreen)),
          const SizedBox(height: 48),
          GradientButton(
            text: _confirming ? '¡Despierto!' : 'Soy el Doctor 💉',
            icon: _confirming ? Icons.check_circle_rounded : Icons.medical_services_rounded,
            width: double.infinity,
            gradient: _doctorGradient,
            onPressed: _confirming ? null : () {
              AudioService.instance.playClick();
              _confirm();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoose(DoctorGameProvider gp, DoctorPlayer doctor) {
    final targets = gp.alivePlayers; // el doctor puede salvarse a sí mismo

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _doctorGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _doctorGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Text('💉', style: TextStyle(fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Elige a quién salvar esta noche.\nNadie más puede ver tu elección.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          const Text('¿A quién salvas?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: targets.length,
              itemBuilder: (ctx, i) {
                final t = targets[i];
                final selected = _selectedSaveId == t.id;
                final isMe = t.id == doctor.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSaveId = t.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: selected ? _doctorGradient : null,
                        color: selected ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppTheme.surfaceLight,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: _doctorGreen.withValues(alpha: 0.4),
                                blurRadius: 16, offset: const Offset(0, 6))]
                            : [],
                      ),
                      child: Row(children: [
                        PlayerAvatar(name: t.name, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : AppTheme.textPrimary)),
                              if (isMe)
                                Text('(Yo mismo)',
                                    style: TextStyle(fontSize: 12,
                                        color: selected
                                            ? Colors.white70
                                            : AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 26),
                      ]),
                    ).animate().fadeIn(delay: (i * 80).ms),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: 'CONFIRMAR SALVACIÓN',
            icon: Icons.medical_services_rounded,
            width: double.infinity,
            gradient: _doctorGradient,
            onPressed: _selectedSaveId != null
                ? () {
                    AudioService.instance.playSave();
                    gp.doctorChoose(_selectedSaveId!);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
