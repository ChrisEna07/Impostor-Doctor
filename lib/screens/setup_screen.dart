// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/player_avatar.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _nameController = TextEditingController();
  bool _showSettings = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer(GameProvider gp) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (gp.players.length >= gp.settings.maxPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo ${gp.settings.maxPlayers} jugadores'),
          backgroundColor: AppTheme.impostorRed,
        ),
      );
      return;
    }
    gp.addPlayer(name);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final isMultiplayer = gp.players.any((p) => p.endpointId != null);

    return PopScope(
      canPop: isMultiplayer,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isMultiplayer) {
          final leave = await _confirmAppExit(context);
          if (leave) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.dark),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // ── LOGO / TÍTULO ───────────────────────────────────────────
                  _buildHeader(isMultiplayer: isMultiplayer)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.3),
                  const SizedBox(height: 32),

                  // ── AGREGAR JUGADOR (solo modo local) ──────────────────────
                  if (!isMultiplayer) ...[
                    _buildAddPlayerCard(gp)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildMultiplayerBanner(gp)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── LISTA JUGADORES ─────────────────────────────────────────
                  if (gp.players.isNotEmpty) ...[
                    _buildPlayerList(gp)
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── CONFIGURACIÓN ───────────────────────────────────────────
                  _buildSettingsToggle(gp)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 32),

                  // ── BOTÓN INICIAR ───────────────────────────────────────────
                  GradientButton(
                    text: 'INICIAR JUEGO',
                    icon: Icons.play_arrow_rounded,
                    width: double.infinity,
                    onPressed: gp.canStartGame
                        ? () {
                            AudioService.instance.playClick();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: gp,
                                  child: const GameScreen(),
                                ),
                              ),
                            );
                          }
                        : null,
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  if (!gp.canStartGame && !isMultiplayer) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Necesitas mínimo ${gp.settings.minPlayers} jugadores',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Diálogo de confirmación para salir de la app
  Future<bool> _confirmAppExit(BuildContext context) async {
    AudioService.instance.playClick();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: const Column(
              children: [
                Text(
                  '😈',
                  style: TextStyle(fontSize: 52),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '¿Seguro que quieres salir?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Si sales ahora, \u00a1el Impostor quedará suelto! 🎭\n\n'
              '¿Realmente quieres dejar que escape?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAAAAF),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quedarse
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 18),
                      label: const Text(
                        '¡Quedarse y atrapar al Impostor!',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Salir
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Salir y dejar al Impostor libre 😈',
                      style: TextStyle(
                          color: Color(0xFFE84040), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeader({bool isMultiplayer = false}) {
    return Column(
      children: [
        if (isMultiplayer)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.masks_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'IMPOSTOR',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: 6,
          ),
        ),
        const Text(
          '& DOCTOR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondary,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isMultiplayer ? 'Impostor · Modo Red 🌐' : 'Módulo Impostor',
            style: const TextStyle(color: AppTheme.accent, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplayerBanner(GameProvider gp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: AppTheme.primary, size: 22),
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

  Widget _buildAddPlayerCard(GameProvider gp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Jugadores (${gp.players.length}/${gp.settings.maxPlayers})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Nombre del jugador...',
                    prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
                  ),
                  onSubmitted: (_) => _addPlayer(gp),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => _addPlayer(gp),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(GameProvider gp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: gp.players.asMap().entries.map((entry) {
          final idx = entry.key;
          final player = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                PlayerAvatar(name: player.name, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${idx + 1}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => gp.removePlayer(player.id),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.impostorRed, size: 20),
                  splashRadius: 20,
                ),
              ],
            ).animate().fadeIn(delay: (idx * 60).ms),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsToggle(GameProvider gp) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSettings = !_showSettings),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded, color: AppTheme.accent, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Configuración del juego',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _showSettings
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_showSettings) ...[
          const SizedBox(height: 8),
          _buildSettingsPanel(gp),
        ],
      ],
    );
  }

  Widget _buildSettingsPanel(GameProvider gp) {
    final s = gp.settings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          _settingSlider(
            label: 'Jugadores máximos',
            value: s.maxPlayers.toDouble(),
            min: 3,
            max: 10,
            divisions: 7,
            onChanged: (v) =>
                gp.updateSettings(s.copyWith(maxPlayers: v.toInt())),
          ),
          const SizedBox(height: 16),
          _settingSlider(
            label: 'Puntos para ganar',
            value: s.pointsToWin.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            onChanged: (v) =>
                gp.updateSettings(s.copyWith(pointsToWin: v.toInt())),
          ),
          const SizedBox(height: 16),
          _settingSlider(
            label: 'Puntos por voto correcto',
            value: s.pointsForCorrectVote.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) =>
                gp.updateSettings(s.copyWith(pointsForCorrectVote: v.toInt())),
          ),
          const SizedBox(height: 16),
          _settingSlider(
            label: 'Puntos impostor sobrevive',
            value: s.pointsForSurviving.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) =>
                gp.updateSettings(s.copyWith(pointsForSurviving: v.toInt())),
          ),
          const SizedBox(height: 20),
          // Modo de fin
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Fin de partida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  label: 'Acumulación\nde puntos',
                  icon: Icons.star_rounded,
                  selected: s.endMode == GameEndMode.points,
                  onTap: () => gp.updateSettings(
                      s.copyWith(endMode: GameEndMode.points)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeButton(
                  label: 'Con\npenitencia',
                  icon: Icons.warning_amber_rounded,
                  selected: s.endMode == GameEndMode.penalty,
                  onTap: () => gp.updateSettings(
                      s.copyWith(endMode: GameEndMode.penalty)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.surfaceLight,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected ? null : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : AppTheme.surfaceLight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppTheme.textSecondary,
                size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
