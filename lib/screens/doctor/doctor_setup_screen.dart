// lib/screens/doctor/doctor_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/game_settings.dart';
import '../../providers/doctor_game_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';
import 'doctor_game_screen.dart';

class DoctorSetupScreen extends StatefulWidget {
  const DoctorSetupScreen({super.key});

  @override
  State<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends State<DoctorSetupScreen> {
  final _nameCtrl = TextEditingController();
  bool _showSettings = false;

  static const _doctorGreen = Color(0xFF1A8C6A);
  static const _doctorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A8C6A), Color(0xFF0D4D3A)],
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addPlayer(DoctorGameProvider gp) {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) return;
    gp.addPlayer(n);
    _nameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final isMultiplayer = gp.players.any((p) => p.endpointId != null);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                const SizedBox(height: 12),
                _buildHeader(isMultiplayer: isMultiplayer).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                const SizedBox(height: 28),
                if (!isMultiplayer) ...[
                  _buildAddCard(gp).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildMultiplayerBanner(gp).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                ],
                if (gp.players.isNotEmpty) ...[
                  _buildPlayerList(gp).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                ],
                if (gp.players.length >= 3) ...[
                  _buildRolesPreview(gp).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 20),
                ],
                _buildSettingsToggle(gp).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 28),
                GradientButton(
                  text: 'INICIAR JUEGO',
                  icon: Icons.play_arrow_rounded,
                  width: double.infinity,
                  gradient: _doctorGradient,
                  onPressed: gp.canStart
                      ? () {
                          AudioService.instance.playClick();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: gp,
                              child: const DoctorGameScreen(),
                            ),
                          ));
                        }
                      : null,
                ).animate().fadeIn(delay: 500.ms),
                if (!gp.canStart && !isMultiplayer) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Necesitas mínimo ${gp.settings.minPlayers} jugadores',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                // Firma
                const Center(
                  child: Text(
                    'by ChrizDev',
                    style: TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      shadows: [Shadow(color: Color(0xFF39FF14), blurRadius: 4)],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 28),
              ],
            ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({bool isMultiplayer = false}) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        ),
        Expanded(
          child: Column(
            children: [
              const Text('💉', style: TextStyle(fontSize: 40)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'MÓDULO DOCTOR',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Text(
                isMultiplayer ? 'Modo Red 🌐' : 'Asesino, Doctor y Civiles',
                style: const TextStyle(color: _doctorGreen, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildMultiplayerBanner(DoctorGameProvider gp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _doctorGreen.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: _doctorGreen.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: _doctorGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Jugadores en red (${gp.players.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: gp.players.map((p) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFF39FF14), size: 8),
                const SizedBox(width: 6),
                Text(
                  p.endpointId != null ? '${p.name} (Red)' : '${p.name} (Host)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard(DoctorGameProvider gp) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _doctorGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.group_add_rounded, color: _doctorGreen, size: 22),
            const SizedBox(width: 10),
            Text('Jugadores (${gp.players.length}/${gp.settings.maxPlayers})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nombre del jugador...',
                  prefixIcon: const Icon(Icons.person_rounded, color: _doctorGreen),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _doctorGreen, width: 2),
                  ),
                ),
                onSubmitted: (_) => _addPlayer(gp),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: _doctorGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => _addPlayer(gp),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPlayerList(DoctorGameProvider gp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: gp.players.asMap().entries.map((e) {
          final p = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              PlayerAvatar(name: p.name, size: 42),
              const SizedBox(width: 12),
              Expanded(child: Text(p.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary))),
              IconButton(
                onPressed: () => gp.removePlayer(p.id),
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.impostorRed, size: 20),
                splashRadius: 20,
              ),
            ]).animate().fadeIn(delay: (e.key * 60).ms),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRolesPreview(DoctorGameProvider gp) {
    final total = gp.players.length;
    final assassins = gp.assassinCount.clamp(1, (total ~/ 3).clamp(1, 3));
    final citizens = total - assassins - 1; // -1 doctor

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _doctorGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Distribución de roles',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _roleChip('🔪', 'Asesino${assassins > 1 ? "s" : ""}', assassins,
                AppTheme.impostorRed),
            _roleChip('💉', 'Doctor', 1, _doctorGreen),
            _roleChip('👥', 'Ciudadano${citizens > 1 ? "s" : ""}',
                citizens < 0 ? 0 : citizens, AppTheme.textSecondary),
          ]),
          if (total >= 3) ...[
            const SizedBox(height: 14),
            // Slider asesinos
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Número de asesinos',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.impostorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$assassins',
                    style: const TextStyle(
                        color: AppTheme.impostorRed, fontWeight: FontWeight.w700)),
              ),
            ]),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.impostorRed,
                inactiveTrackColor: AppTheme.surfaceLight,
                thumbColor: AppTheme.impostorRed,
                overlayColor: AppTheme.impostorRed.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: assassins.toDouble(),
                min: 1,
                max: (total ~/ 3).clamp(1, 3).toDouble(),
                divisions: ((total ~/ 3).clamp(1, 3) - 1).clamp(1, 5),
                onChanged: (v) => gp.setAssassinCount(v.toInt()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleChip(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildSettingsToggle(DoctorGameProvider gp) {
    return GestureDetector(
      onTap: () => setState(() => _showSettings = !_showSettings),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Row(children: [
              const Icon(Icons.settings_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Configuración del juego',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ),
              Icon(_showSettings ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.textSecondary),
            ]),
          ),
          if (_showSettings) ...[
            const SizedBox(height: 8),
            _buildSettingsPanel(gp),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(DoctorGameProvider gp) {
    final s = gp.settings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(children: [
        _slider('Puntos por voto correcto', s.pointsForCorrectVote.toDouble(),
            1, 5, 4, (v) => gp.updateSettings(s.copyWith(pointsForCorrectVote: v.toInt()))),
        const SizedBox(height: 14),
        _slider('Puntos asesino por noche', s.pointsForSurviving.toDouble(),
            1, 5, 4, (v) => gp.updateSettings(s.copyWith(pointsForSurviving: v.toInt()))),
        const SizedBox(height: 14),
        _slider('Puntos para ganar', s.pointsToWin.toDouble(),
            5, 30, 5, (v) => gp.updateSettings(s.copyWith(pointsToWin: v.toInt()))),
      ]),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      int divisions, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _doctorGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value.toInt().toString(),
              style: const TextStyle(color: _doctorGreen, fontWeight: FontWeight.w700)),
        ),
      ]),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: _doctorGreen,
          inactiveTrackColor: AppTheme.surfaceLight,
          thumbColor: _doctorGreen,
          trackHeight: 4,
        ),
        child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
      ),
    ]);
  }
}
