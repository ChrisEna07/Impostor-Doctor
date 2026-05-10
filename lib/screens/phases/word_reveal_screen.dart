// lib/screens/phases/word_reveal_screen.dart
//
// Fase de revelación de palabras:
// - Confirma que eres tú con "¿Seguro eres [Nombre]?"
// - Botón TOCAR para ver la palabra (oculta si no se toca)
// - Siguiente turno
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class WordRevealScreen extends StatefulWidget {
  const WordRevealScreen({super.key});

  @override
  State<WordRevealScreen> createState() => _WordRevealScreenState();
}

class _WordRevealScreenState extends State<WordRevealScreen> {
  // Paso del mini-flujo:
  // 0 = confirmación de identidad
  // 1 = mostrar palabra (oculta hasta tocar)
  int _step = 0;
  bool _confirming = false;

  // Guardamos el índice del turno que ya vimos.
  // Solo reseteamos _step cuando el índice REALMENTE cambió.
  int _lastSeenTurn = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gp = context.read<GameProvider>();
    final currentTurn = gp.currentRevealTurn;
    final currentPlayer = gp.players[currentTurn];
    
    // Si el jugador es remoto, el Host NO debe ver su palabra. 
    // Saltamos su turno en el dispositivo del Host inmediatamente.
    if (currentPlayer.endpointId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          gp.nextRevealTurn();
        }
      });
      return;
    }

    // En modo RED, si es el Host local, no confirmamos identidad (ya sabe que es él)
    bool isMultiplayer = gp.players.any((p) => p.endpointId != null);
    if (isMultiplayer && _step == 0) {
      _step = 1; 
    }

    if (currentTurn != _lastSeenTurn) {
      _lastSeenTurn = currentTurn;
      if (!isMultiplayer) _step = 0; 
      _confirming = false;
    }
  }

  void _confirmIdentity() {
    setState(() {
      _confirming = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() { _step = 1; _confirming = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final player = gp.currentRevealPlayer;
    final isLast = gp.currentRevealTurn == gp.players.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: _step == 0
              ? _buildConfirmStep(gp, player)
              : _buildWordStep(gp, player, isLast),
        ),
      ),
    );
  }

  // ── Paso 0: Confirmación de identidad ────────────────────────────────────
  Widget _buildConfirmStep(GameProvider gp, player) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progreso
          _buildProgress(gp),
          const SizedBox(height: 48),

          // Ícono de escudo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.lock_person_rounded,
                color: Colors.white, size: 52),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 36),

          const Text(
            'Pasa el celular a:',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 8),

          const Text(
            'Toca el botón cuando estés listo',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),

          // Botón de confirmación
          GestureDetector(
            onTap: _confirming ? null : _confirmIdentity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                gradient: _confirming ? AppGradients.safe : AppGradients.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _confirming ? Icons.check_circle_rounded : Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _confirming
                        ? '¡Confirmado!'
                        : 'Sí, soy ${player.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paso 1: Ver / Ocultar palabra ────────────────────────────────────────
  Widget _buildWordStep(GameProvider gp, player, bool isLast) {
    final wordVisible = gp.wordVisible;
    final word = gp.currentPlayerWord;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgress(gp),
          const SizedBox(height: 36),

          PlayerAvatar(name: player.name, size: 72),
          const SizedBox(height: 16),
          Text(
            player.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 36),

          // Tarjeta de palabra
          GestureDetector(
            onTapDown: (_) => gp.showWord(),
            onTapUp: (_) => gp.hideWord(),
            onTapCancel: () => gp.hideWord(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: wordVisible ? AppGradients.primary : null,
                color: wordVisible ? null : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: wordVisible
                      ? Colors.transparent
                      : AppTheme.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: wordVisible
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: wordVisible
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ).animate().fadeIn(duration: 200.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 200.ms),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded,
                              color: AppTheme.primary, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'MANTÉN PRESIONADO\npara ver tu palabra',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Suelta para ocultar • Nadie más puede ver',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 48),

          GradientButton(
            text: isLast ? 'INICIAR DISCUSIÓN' : 'SIGUIENTE JUGADOR',
            icon: isLast ? Icons.forum_rounded : Icons.arrow_forward_rounded,
            width: double.infinity,
            onPressed: () {
              gp.nextRevealTurn(); // didChangeDependencies se encarga del reset
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(GameProvider gp) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ronda ${gp.currentRound}  •  '
                '${gp.currentRevealTurn + 1}/${gp.players.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (gp.currentRevealTurn + 1) / gp.players.length,
            backgroundColor: AppTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
