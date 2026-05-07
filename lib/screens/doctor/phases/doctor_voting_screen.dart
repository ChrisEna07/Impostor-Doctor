// lib/screens/doctor/phases/doctor_voting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_player.dart';
import '../../../providers/doctor_game_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/multiplayer_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/player_avatar.dart';

class DoctorVotingScreen extends StatefulWidget {
  const DoctorVotingScreen({super.key});

  @override
  State<DoctorVotingScreen> createState() => _DoctorVotingScreenState();
}

class _DoctorVotingScreenState extends State<DoctorVotingScreen> {
  int _step = 0;        // 0 = confirmar identidad, 1 = votar
  int _lastTurn = -1;
  String? _selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gp = context.read<DoctorGameProvider>();
    final turn = gp.votingTurnIndex;
    bool isMultiplayer = gp.players.any((p) => p.endpointId != null);

    if (isMultiplayer) {
      _step = 1; // Directo a votar
      
      // Enviar lista de candidatos a todos los remotos
      MultiplayerService.instance.broadcastData({
        'type': 'phase_update',
        'phase': 'voting',
        'candidates': gp.players.where((p) => p.isAlive).map((p) => {'id': p.id, 'name': p.name}).toList(),
      });
      
      // Escuchar votos remotos
      MultiplayerService.instance.onDataReceived = (id, data) {
        if (data is Map && data['type'] == 'vote_cast') {
          gp.castVote(data['targetId']);
        }
      };
    } else {
      if (turn != _lastTurn) {
        _lastTurn = turn;
        _step = 0;
        _selectedId = null;
      }
    }
  }

  void _castVote(DoctorGameProvider gp) {
    if (_selectedId == null) return;
    AudioService.instance.playVote();
    gp.castVote(_selectedId!);
    setState(() { _step = 0; _selectedId = null; });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<DoctorGameProvider>();
    final alive = gp.alivePlayers;
    final totalVoters = alive.length;
    final voterIdx = gp.votingTurnIndex < totalVoters ? gp.votingTurnIndex : totalVoters - 1;
    final voter = alive[voterIdx];
    final isRemoteVoter = voter.endpointId != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progreso
                _buildProgress(gp).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                Expanded(
                  child: isRemoteVoter
                      ? _buildRemoteWaiting(voter)
                      : (_step == 0 ? _buildConfirm(voter) : _buildVote(gp, voter)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteWaiting(DoctorPlayer voter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.redAccent),
          const SizedBox(height: 32),
          Text(
            "Esperando el voto de ${voter.name}...",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Se notificará cuando el jugador haya votado.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildProgress(DoctorGameProvider gp) {
    final alive = gp.alivePlayers;
    final total = alive.length;
    final done = gp.votingTurnIndex.clamp(0, total);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(20)),
          child: Text('Votación  $done/$total',
              style: const TextStyle(color: AppTheme.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: total > 0 ? done / total : 0,
          backgroundColor: AppTheme.surfaceLight,
          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          minHeight: 6,
        ),
      ),
    ]);
  }

  Widget _buildConfirm(dynamic voter) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.5),
              blurRadius: 28, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 50),
        ).animate().scale(begin: const Offset(0.5, 0.5), duration: 400.ms,
            curve: Curves.elasticOut),
        const SizedBox(height: 28),
        const Text('Pasa el celular a:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        Text(voter.name,
            style: const TextStyle(
                fontSize: 38, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        const Text('Vota en privado. Nadie verá tu voto aún.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 48),
        GradientButton(
          text: 'Soy ${voter.name} — Votar',
          icon: Icons.verified_user_rounded,
          width: double.infinity,
          onPressed: () {
            AudioService.instance.playClick();
            setState(() => _step = 1);
          },
        ),
      ],
    );
  }

  Widget _buildVote(DoctorGameProvider gp, dynamic voter) {
    final candidates = gp.alivePlayers.where((p) => p.id != voter.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            PlayerAvatar(name: voter.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text('¿Quién crees que es el asesino, ${voter.name}?',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ),
          ]),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (_, i) {
              final c = candidates[i];
              final selected = _selectedId == c.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedId = c.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: selected ? AppGradients.primary : null,
                      color: selected ? null : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppTheme.surfaceLight,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 14, offset: const Offset(0, 6))]
                          : [],
                    ),
                    child: Row(children: [
                      PlayerAvatar(name: c.name, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(c.name,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppTheme.textPrimary)),
                      ),
                      if (selected)
                        const Icon(Icons.how_to_vote_rounded,
                            color: Colors.white, size: 24),
                    ]),
                  ).animate().fadeIn(delay: (i * 70).ms),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        GradientButton(
          text: 'CONFIRMAR VOTO',
          icon: Icons.check_circle_rounded,
          width: double.infinity,
          onPressed: _selectedId != null ? () => _castVote(gp) : null,
        ),
      ],
    );
  }
}
