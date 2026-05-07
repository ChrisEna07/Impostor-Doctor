// lib/screens/doctor/doctor_game_screen.dart
// Router de fases del módulo Doctor
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/doctor_game_provider.dart';
import '../../services/multiplayer_service.dart';
import '../../models/doctor_player.dart';
import '../../theme/app_theme.dart';
import 'phases/night_intro_screen.dart';
import 'phases/night_assassin_screen.dart';
import 'phases/night_doctor_screen.dart';
import 'phases/dawn_screen.dart';
import 'phases/doctor_discussion_screen.dart';
import 'phases/doctor_voting_screen.dart';
import 'phases/doctor_vote_result_screen.dart';
import 'phases/doctor_game_over_screen.dart';

class DoctorGameScreen extends StatefulWidget {
  const DoctorGameScreen({super.key});

  @override
  State<DoctorGameScreen> createState() => _DoctorGameScreenState();
}

class _DoctorGameScreenState extends State<DoctorGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dgp = context.read<DoctorGameProvider>();
      
      // Escuchar cambios de fase para transmitir
      dgp.addListener(() {
        if (mounted) {
          MultiplayerService.instance.broadcastData({
            'type': 'phase_update',
            'phase': dgp.phase.name, 
          });
        }
      });

      dgp.startGame();
      
      for (var p in dgp.players) {
        if (p.endpointId != null) {
          MultiplayerService.instance.sendDataTo(p.endpointId!, {
            'type': 'game_data',
            'role': p.role.label,
            'secret': p.role.emoji,
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<DoctorGameProvider>().phase;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (leave && context.mounted) {
          context.read<DoctorGameProvider>().resetGame();
          Navigator.of(context).pop();
        }
      },
      child: _buildPhase(phase),
    );
  }

  Widget _buildPhase(DoctorPhase phase) {
    final dgp = context.read<DoctorGameProvider>();
    
    // Si la fase actual requiere acción de un rol que es REMOTO, saltarla en el host visualmente
    if (phase == DoctorPhase.nightAssassin) {
      final assassins = dgp.players.where((p) => p.role == DoctorRole.asesino).toList();
      if (assassins.isNotEmpty && assassins.every((a) => a.endpointId != null)) {
        return _waitingScreen("El Asesino está actuando...");
      }
    } else if (phase == DoctorPhase.nightDoctor) {
      final doctors = dgp.players.where((p) => p.role == DoctorRole.doctor).toList();
      if (doctors.isNotEmpty && doctors.every((d) => d.endpointId != null)) {
        return _waitingScreen("El Doctor está actuando...");
      }
    }

    switch (phase) {
      case DoctorPhase.setup:
        return const Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Center(child: CircularProgressIndicator()),
        );
      case DoctorPhase.nightIntro:
        return const NightIntroScreen();
      case DoctorPhase.nightAssassin:
        return const NightAssassinScreen();
      case DoctorPhase.nightDoctor:
        return const NightDoctorScreen();
      case DoctorPhase.dawn:
        return const DawnScreen();
      case DoctorPhase.discussion:
        return const DoctorDiscussionScreen();
      case DoctorPhase.voting:
        return const DoctorVotingScreen();
      case DoctorPhase.voteResult:
        return const DoctorVoteResultScreen();
      case DoctorPhase.gameOver:
        return const DoctorGameOverScreen();
    }
  }

  Widget _waitingScreen(String msg) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(msg, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('¿Salir del juego?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: const Text('Se perderá el progreso de esta partida.',
                style: TextStyle(color: Color(0xFFAAAAAF))),
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
