// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/multiplayer_service.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'multiplayer_lobby_screen.dart';
import '../providers/doctor_game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'setup_screen.dart';
import 'doctor/doctor_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _muted = false;
  bool _isMultiplayer = false;
  String _version = '1.0.0';
  String _userName = 'Jugador';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _userName = 'Jugador_${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<bool> _confirmExit() async {
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
                Text('😈', style: TextStyle(fontSize: 52),
                    textAlign: TextAlign.center),
                SizedBox(height: 8),
                Text('¿Seguro que quieres salir?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            content: const Text(
              'Si sales ahora, ¡el Impostor quedará suelto! 🎭\n\n'
              '¿Realmente quieres dejar que escape?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAAAAF), fontSize: 14, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 18),
                      label: const Text('¡Quedarse y jugar!',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Salir 😈',
                        style: TextStyle(
                            color: Color(0xFFE84040), fontSize: 13)),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit();
        if (leave) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.dark),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── LOGO ──────────────────────────────────────────────────
                  _buildLogo().animate().fadeIn(duration: 700.ms).slideY(begin: -0.2),

                  const SizedBox(height: 48),

                  // ── MÓDULOS ───────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Selector de Modo (Local vs Multiplayer)
                        _buildModeSelector(),
                        const SizedBox(height: 32),

                        // Módulo Impostor
                        _moduleCard(
                          emoji: '😈',
                          title: 'Impostor',
                          subtitle: 'Descubre quién tiene la\npalabra diferente',
                          gradient: AppGradients.primary,
                          glowColor: AppTheme.primary,
                          delay: 200,
                          onTap: () {
                            AudioService.instance.playClick();
                            if (_isMultiplayer) {
                              _goToLobby('Impostor');
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider(
                                    create: (_) => GameProvider(),
                                    child: const SetupScreen(),
                                  ),
                                ),
                              );
                            }
                          },
                        ).animate()
                         .fadeIn(duration: 600.ms, delay: 200.ms)
                         .slideX(begin: 0.2, curve: Curves.easeOutQuart)
                         .shimmer(delay: 1500.ms, duration: 1200.ms, color: Colors.white24),

                        const SizedBox(height: 24),

                        // Módulo Doctor
                        _moduleCard(
                          emoji: '💉',
                          title: 'Doctor',
                          subtitle: 'El pueblo contra\nel asesino oculto',
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A8C6A), Color(0xFF0D4D3A)],
                          ),
                          glowColor: const Color(0xFF1A8C6A),
                          delay: 350,
                          onTap: () {
                            AudioService.instance.playClick();
                            if (_isMultiplayer) {
                              _goToLobby('Doctor');
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider(
                                    create: (_) => DoctorGameProvider(),
                                    child: const DoctorSetupScreen(),
                                  ),
                                ),
                              );
                            }
                          },
                        ).animate()
                         .fadeIn(duration: 600.ms, delay: 400.ms)
                         .slideX(begin: -0.2, curve: Curves.easeOutQuart)
                         .shimmer(delay: 2000.ms, duration: 1200.ms, color: Colors.white24),
                      ],
                    ),
                  ),

                  // ── FOOTER ────────────────────────────────────────────────
                  Column(
                    children: [
                      // Firma ChrizDev
                      const Text(
                        'by ChrizDev',
                        style: TextStyle(
                          color: Color(0xFF39FF14), // Neon Green
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(color: Color(0xFF39FF14), blurRadius: 10),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .scale(end: const Offset(1.1, 1.1), duration: 1000.ms),
                      
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'v$_version',
                            style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                                fontSize: 12),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() => _muted = !_muted);
                                  AudioService.instance.toggleMute();
                                },
                                icon: Icon(
                                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                              Text(
                                _muted ? 'OFF' : 'ON',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLobby(String gameType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiplayerLobbyScreen(gameType: gameType, userName: _userName),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeToggleBtn('LOCAL', !_isMultiplayer, Icons.person_rounded),
          _modeToggleBtn('RED', _isMultiplayer, Icons.bluetooth_connected_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _modeToggleBtn(String label, bool active, IconData icon) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playClick();
        setState(() => _isMultiplayer = label == 'RED');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.primary : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: active ? [
            BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo image — si no existe el archivo muestra el ícono
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/logo.png',
            width: 110,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 110,
              height: 110,
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
              child: const Icon(Icons.masks_rounded,
                  color: Colors.white, size: 56),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'IMPOSTOR',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: 6,
          ),
        ),
        const Text(
          '& DOCTOR',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondary,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Elige tu modo de juego',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _moduleCard({
    required String emoji,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required Color glowColor,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    )
        .animate()
        .shimmer(delay: 400.ms, duration: 1800.ms, color: Colors.white12);
  }
}
