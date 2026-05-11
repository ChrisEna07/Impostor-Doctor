// lib/screens/phases/voting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../services/multiplayer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/player_avatar.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  // Paso interno:
  // 0 = confirmación de identidad del votante
  // 1 = elegir a quién votar
  int _step = 0;
  String? _selectedSuspectId;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gp = context.read<GameProvider>();
      bool isMultiplayer = gp.players.any((p) => p.endpointId != null);
      if (isMultiplayer) {
        MultiplayerService.instance.onDataReceived = (id, data) {
          if (data is Map && data['type'] == 'vote_cast' && mounted) {
            context.read<GameProvider>().castVote(data['targetId'], voterId: id);
          }
        };
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gp = context.read<GameProvider>();
    bool isMultiplayer = gp.players.any((p) => p.endpointId != null);

    if (isMultiplayer) {
      // Enviar lista de candidatos una sola vez al entrar
      MultiplayerService.instance.broadcastData({
        'type': 'phase_update',
        'phase': 'voting',
        'candidates': gp.players.map((p) => {'id': p.id, 'name': p.name}).toList(),
      });
    }
    _selectedSuspectId = null;
  }

  void _confirmIdentity() {
    setState(() => _confirming = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() { _step = 1; _confirming = false; });
    });
  }

  void _castVote(GameProvider gp) {
    if (_selectedSuspectId == null) return;
    AudioService.instance.playVote();
    gp.castVote(_selectedSuspectId!);
    setState(() {
      _step = 0;
      _selectedSuspectId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    bool isMultiplayer = gp.players.any((p) => p.endpointId != null);
    
    if (gp.votingTurnIndex >= gp.players.length && !isMultiplayer) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final voter = gp.currentVoter;
    final isRemoteVoter = voter.endpointId != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: isMultiplayer 
              ? _buildMultiplayerHostStatus(gp)
              : (isRemoteVoter
                  ? _buildRemoteWaiting(voter)
                  : (_step == 0 ? _buildConfirmStep(voter) : _buildVoteStep(gp, voter))),
        ),
      ),
    );
  }

  Widget _buildRemoteWaiting(dynamic voter) {
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

  // ── Confirmación ─────────────────────────────────────────────────────────
  Widget _buildConfirmStep(dynamic player) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.how_to_vote_rounded,
                color: Colors.white, size: 48),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 400.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 36),
          const Text(
            'Hora de votar',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              '¿Quién es el\nImpostor?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Pasa el celular a:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppTheme.secondary,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 48),
          GradientButton(
            text: _confirming ? '¡Listo!' : 'Soy ${player.name}',
            icon: _confirming
                ? Icons.check_circle_rounded
                : Icons.how_to_vote_rounded,
            width: double.infinity,
            gradient: _confirming ? AppGradients.safe : AppGradients.primary,
            onPressed: _confirming ? null : _confirmIdentity,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerHostStatus(GameProvider gp) {
    int totalVotes = gp.votes.length;
    int totalPlayers = gp.players.length;

    // Si el Host está votando ahora mismo, mostramos solo la lista de votación para evitar lag y desorden
    if (_step == 1) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _step = 0), 
                  icon: const Icon(Icons.arrow_back, color: Colors.white)
                ),
                const Text("REGRESAR AL ESTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: _buildVoteStep(gp, gp.players.firstWhere((p) => p.id == 'local_host'))),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.how_to_vote_rounded, size: 80, color: AppTheme.primary)
              .animate(onPlay: (c) => c.repeat()).shimmer(),
          const SizedBox(height: 32),
          const Text("VOTACIÓN EN CURSO", 
            style: TextStyle(color: AppTheme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("$totalVotes / $totalPlayers", 
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white)),
          const Text("Votos recibidos", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 48),
          
          // El Host también debe votar si es local_host
          if (gp.votes['local_host'] == null)
            GradientButton(
              text: "VOTAR AHORA",
              icon: Icons.touch_app_rounded,
              onPressed: () => setState(() => _step = 1),
            )
          else
            const Text("Ya has emitido tu voto. Esperando a los demás...", 
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Panel de votación ─────────────────────────────────────────────────────
  Widget _buildVoteStep(GameProvider gp, dynamic voter) {
    // Permitir votar por CUALQUIERA (incluido uno mismo)
    final candidates = gp.players;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Barra de progreso de votación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Voto ${gp.votingTurnIndex + 1} de ${gp.players.length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (gp.votingTurnIndex) / gp.players.length,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 28),

          // Quién vota
          Row(
            children: [
              PlayerAvatar(name: voter.name, size: 48),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votando',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    voter.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          const Text(
            '¿Quién crees que es el Impostor?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de candidatos
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (ctx, i) {
                final candidate = candidates[i];
                final isSelected = _selectedSuspectId == candidate.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedSuspectId = candidate.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.primary : null,
                        color: isSelected ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppTheme.surfaceLight,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(name: candidate.name, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${candidate.points} puntos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 28),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          GradientButton(
            text: 'CONFIRMAR VOTO',
            icon: Icons.how_to_vote_rounded,
            width: double.infinity,
            onPressed: _selectedSuspectId != null ? () => _castVote(gp) : null,
          ),
        ],
      ),
    );
  }
}
