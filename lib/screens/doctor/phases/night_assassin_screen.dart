// lib/screens/doctor/phases/night_assassin_screen.dart
// El asesino elige a su víctima (privado, confirmar identidad primero)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_player.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class NightAssassinScreen extends StatefulWidget {
  const NightAssassinScreen({super.key});

  @override
  State<NightAssassinScreen> createState() => _NightAssassinScreenState();
}

class _NightAssassinScreenState extends State<NightAssassinScreen> {
  // 0 = confirmación; 1 = elegir víctima
  int _step = 0;
  bool _confirming = false;
  String? _selectedTargetId;

  void _confirm() {
    setState(() => _confirming = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() { _step = 1; _confirming = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final assassins = gp.players.where((p) => p.role == DoctorRole.asesino).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0000), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: _step == 0
              ? _buildConfirm(assassins)
              : _buildChoose(gp, assassins),
        ),
      ),
    );
  }

  // ── Confirmación ─────────────────────────────────────────────────────────
  Widget _buildConfirm(List<DoctorPlayer> assassins) {
    final names = assassins.map((a) => a.name).join(' y ');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔪', style: TextStyle(fontSize: 72))
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 600.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 28),
          const Text('El asesino despierta...', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            assassins.length > 1 ? 'Pasa el celular a:\n$names' : 'Pasa el celular a:',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
          if (assassins.length == 1) ...[
            const SizedBox(height: 8),
            Text(assassins.first.name,
                style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w900,
                  color: AppTheme.impostorRed)),
          ],
          const SizedBox(height: 48),
          GradientButton(
            text: _confirming ? '¡Despierto!' : 'Soy el Asesino 🔪',
            icon: _confirming ? Icons.check_circle_rounded : Icons.dark_mode_rounded,
            width: double.infinity,
            gradient: const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFFE84040)]),
            onPressed: _confirming ? null : () {
              AudioService.instance.playClick();
              _confirm();
            },
          ),
        ],
      ),
    );
  }

  // ── Elegir víctima ────────────────────────────────────────────────────────
  Widget _buildChoose(DoctorGameProvider gp, List<DoctorPlayer> assassins) {
    // El asesino no puede elegirse a sí mismo
    final assassinIds = assassins.map((a) => a.id).toSet();
    final targets = gp.alivePlayers.where((p) => !assassinIds.contains(p.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.impostorRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.impostorRed.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Text('🔪', style: TextStyle(fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Elige a tu víctima de esta noche.\nNadie más puede ver.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          const Text('¿A quién eliminas?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: targets.length,
              itemBuilder: (ctx, i) {
                final t = targets[i];
                final selected = _selectedTargetId == t.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTargetId = t.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFE84040)])
                            : null,
                        color: selected ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppTheme.surfaceLight,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppTheme.impostorRed.withValues(alpha: 0.4),
                                blurRadius: 16, offset: const Offset(0, 6))]
                            : [],
                      ),
                      child: Row(children: [
                        PlayerAvatar(name: t.name, size: 48),
                        const SizedBox(width: 14),
                        Expanded(child: Text(t.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppTheme.textPrimary))),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
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
            text: 'CONFIRMAR VÍCTIMA',
            icon: Icons.check_rounded,
            width: double.infinity,
            gradient: const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFFE84040)]),
            onPressed: _selectedTargetId != null
                ? () {
                    AudioService.instance.playEliminate();
                    gp.assassinChoose(_selectedTargetId!);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
