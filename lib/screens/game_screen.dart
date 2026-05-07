// lib/screens/game_screen.dart
//
// Pantalla principal que enruta a la fase correcta del juego.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/multiplayer_service.dart';
import 'phases/word_reveal_screen.dart';
import 'phases/discussion_screen.dart';
import 'phases/voting_screen.dart';
import 'phases/result_screen.dart';
import 'phases/round_end_screen.dart';
import 'phases/game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gp = context.read<GameProvider>();
      String _lastPhase = '';
      
      // Escuchar cambios de fase y transmitir SOLO cuando cambia
      gp.addListener(() {
        if (mounted) {
          final phaseName = gp.phase.name;
          if (phaseName != _lastPhase) {
            _lastPhase = phaseName;
            MultiplayerService.instance.broadcastData({
              'type': 'phase_update',
              'phase': phaseName,
            });
          }
        }
      });

      await gp.startRound();
      
      for (var p in gp.players) {
        if (p.endpointId != null) {
          final word = p.isImpostor ? gp.currentWordPair?.impostor : gp.currentWordPair?.normal;
          if (word != null) {
            MultiplayerService.instance.sendDataTo(p.endpointId!, {
              'type': 'game_data',
              'secret': word,
              'role': p.isImpostor ? 'Impostor' : 'Inocente',
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<GameProvider>().phase;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          context.read<GameProvider>().resetGame();
          Navigator.of(context).pop();
        }
      },
      child: _buildPhase(phase),
    );
  }

  Widget _buildPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return const SizedBox.shrink();
      case GamePhase.wordReveal:
        return const WordRevealScreen();
      case GamePhase.discussion:
        return const DiscussionScreen();
      case GamePhase.voting:
        return const VotingScreen();
      case GamePhase.result:
        return const ResultScreen();
      case GamePhase.roundEnd:
        return const RoundEndScreen();
      case GamePhase.gameOver:
        return const GameOverScreen();
    }
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              '¿Salir del juego?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'Se perderá el progreso de la partida actual.',
              style: TextStyle(color: Color(0xFFAAAAAF)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFFAAAAAF))),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Salir',
                    style: TextStyle(color: Color(0xFFE84040))),
              ),
            ],
          ),
        ) ??
        false;
  }
}
