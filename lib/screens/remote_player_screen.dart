// lib/screens/remote_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player_avatar.dart';

enum ClientPhase { waiting, revealed, discussion, voting, result, nightAction, dawn }

class RemotePlayerScreen extends StatefulWidget {
  final String gameType;
  final String myName;

  const RemotePlayerScreen({
    super.key,
    required this.gameType,
    required this.myName,
  });

  @override
  State<RemotePlayerScreen> createState() => _RemotePlayerScreenState();
}

class _RemotePlayerScreenState extends State<RemotePlayerScreen> {
  ClientPhase _phase = ClientPhase.waiting;
  String? _secret;
  String? _roleLabel;
  bool _revealed = false;
  String _message = "Esperando que el Host inicie...";
  int _timerSeconds = 0;
  List<Map<String, dynamic>> _candidates = [];
  List<Map<String, dynamic>> _nightTargets = []; // para acciones nocturnas
  String? _nightActionType; // 'assassin' | 'doctor'
  Map<String, dynamic>? _resultData;
  bool _nightActionDone = false;

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.onDataReceived = (id, data) {
      if (data is Map) {
        if (data['type'] == 'game_data') {
          setState(() {
            _secret = data['secret'];
            _roleLabel = data['role'];
            _phase = ClientPhase.revealed;
          });
          AudioService.instance.playReveal();
        } else if (data['type'] == 'phase_update') {
          setState(() {
            final phaseStr = data['phase'] as String;
            _nightActionDone = false;
            if (phaseStr == 'discussion') {
              _phase = ClientPhase.discussion;
              _timerSeconds = data['time'] ?? 0;
            } else if (phaseStr == 'voting') {
              _phase = ClientPhase.voting;
              _candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? []);
            } else if (phaseStr == 'result' || phaseStr == 'voteResult') {
              _phase = ClientPhase.result;
              _resultData = Map<String, dynamic>.from(data);
            } else if (phaseStr == 'nightIntro') {
              _phase = ClientPhase.waiting;
              _message = "🌙 Cae la noche... ¡Cierra los ojos!";
            } else if (phaseStr == 'nightAssassin') {
              // Solo el asesino recibe lista de targets
              if (_roleLabel == 'Asesino' || _roleLabel == 'asesino') {
                _phase = ClientPhase.nightAction;
                _nightActionType = 'assassin';
                _nightTargets = List<Map<String, dynamic>>.from(data['targets'] ?? []);
              } else {
                _phase = ClientPhase.waiting;
                _message = "🤐 Shhh... El Asesino está eligiendo...";
              }
            } else if (phaseStr == 'nightDoctor') {
              // Solo el doctor recibe lista de targets
              if (_roleLabel == 'Doctor' || _roleLabel == 'doctor') {
                _phase = ClientPhase.nightAction;
                _nightActionType = 'doctor';
                _nightTargets = List<Map<String, dynamic>>.from(data['targets'] ?? []);
              } else {
                _phase = ClientPhase.waiting;
                _message = "🤐 Shhh... El Doctor está actuando...";
              }
            } else if (phaseStr == 'dawn') {
              _phase = ClientPhase.dawn;
              _resultData = data.containsKey('victim') ? Map<String, dynamic>.from(data) : null;
            } else if (phaseStr == 'gameOver') {
              _phase = ClientPhase.result;
              _resultData = Map<String, dynamic>.from(data);
            }
          });
        } else if (data['type'] == 'timer_update') {
          setState(() {
            _timerSeconds = data['time'];
          });
        } else if (data['type'] == 'game_over') {
          Navigator.pop(context);
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(widget.gameType.toUpperCase(), 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text(_phaseLabel, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String get _phaseLabel {
    switch (_phase) {
      case ClientPhase.waiting: return "SALA DE ESPERA";
      case ClientPhase.revealed: return widget.gameType == 'Doctor' ? "TU ROL SECRETO" : "PALABRA SECRETA";
      case ClientPhase.discussion: return "DISCUSIÓN EN CURSO";
      case ClientPhase.voting: return "TIEMPO DE VOTAR";
      case ClientPhase.result: return "RESULTADOS";
      case ClientPhase.nightAction: return _nightActionType == 'assassin' ? "🔪 ELIGE TU VÍCTIMA" : "💉 ELIGE A QUIÉN SALVAR";
      case ClientPhase.dawn: return "🌅 AMANECER";
    }
  }

  Widget _buildBody() {
    switch (_phase) {
      case ClientPhase.waiting: return _buildWaitingUI();
      case ClientPhase.revealed: return Center(child: _buildSecretCard());
      case ClientPhase.discussion: return _buildDiscussionUI();
      case ClientPhase.voting: return _buildVotingUI();
      case ClientPhase.result: return _buildResultUI();
      case ClientPhase.nightAction: return _buildNightActionUI();
      case ClientPhase.dawn: return _buildDawnUI();
    }
  }

  Widget _buildWaitingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primary).animate(onPlay: (c) => c.repeat()).shimmer(),
        const SizedBox(height: 24),
        Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildDiscussionUI() {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("TIEMPO RESTANTE", style: TextStyle(color: AppTheme.textSecondary, letterSpacing: 2)),
        const SizedBox(height: 16),
        Text(timeStr, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 40),
        const Icon(Icons.forum_rounded, size: 80, color: AppTheme.accent).animate(onPlay: (c) => c.repeat()).shake(),
        const SizedBox(height: 40),
        const Text("¡Debate con el grupo!", style: TextStyle(color: Colors.white70, fontSize: 18)),
      ],
    );
  }

  Widget _buildVotingUI() {
    final label = widget.gameType == 'Doctor' ? "¿QUIÉN ES EL ASESINO?" : "¿QUIÉN ES EL IMPOSTOR?";
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _candidates.length,
            itemBuilder: (context, i) {
              final c = _candidates[i];
              return Card(
                color: AppTheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: PlayerAvatar(name: c['name'], size: 40),
                  title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.how_to_vote_rounded, color: AppTheme.primary),
                  onTap: () {
                    MultiplayerService.instance.sendData({'type': 'vote_cast', 'targetId': c['id']});
                    setState(() { _phase = ClientPhase.waiting; _message = "Voto enviado. Esperando resultados..."; });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNightActionUI() {
    if (_nightActionDone) return _buildWaitingUI();
    final isAssassin = _nightActionType == 'assassin';
    final color = isAssassin ? AppTheme.impostorRed : const Color(0xFF1A8C6A);
    final icon = isAssassin ? Icons.local_fire_department_rounded : Icons.medical_services_rounded;
    final hint = isAssassin ? "Elige a quién eliminar esta noche" : "Elige a quién proteger esta noche";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(hint, textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _nightTargets.isEmpty
              ? Center(child: Text("No hay objetivos disponibles", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _nightTargets.length,
                  itemBuilder: (context, i) {
                    final t = _nightTargets[i];
                    return Card(
                      color: AppTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: color.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: PlayerAvatar(name: t['name'], size: 40),
                        title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(icon, color: color),
                        onTap: () {
                          AudioService.instance.playClick();
                          final eventType = isAssassin ? 'night_assassin_choice' : 'night_doctor_choice';
                          final key = isAssassin ? 'targetId' : 'saveId';
                          MultiplayerService.instance.sendData({"type": eventType, key: t['id']});
                          setState(() {
                            _nightActionDone = true;
                            _phase = ClientPhase.waiting;
                            _message = isAssassin ? "Acción enviada. Espera el amanecer..." : "¡Jugador protegido! Espera el amanecer...";
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDawnUI() {
    final victim = _resultData?['victim'];
    final saved = _resultData?['saved'] == true;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(saved ? "🌅 ¡Nadie murió!" : "🌅 Amanece...",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 32),
        if (saved) ...[
          const Icon(Icons.favorite_rounded, size: 80, color: Color(0xFF1A8C6A)),
          const SizedBox(height: 16),
          const Text("¡El Doctor salvó a alguien!", style: TextStyle(color: Color(0xFF1A8C6A), fontSize: 18, fontWeight: FontWeight.bold)),
        ] else if (victim != null) ...[
          PlayerAvatar(name: victim, size: 80),
          const SizedBox(height: 16),
          Text(victim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("fue eliminado/a esta noche", style: TextStyle(color: AppTheme.impostorRed, fontSize: 16)),
        ] else ...[
          const Icon(Icons.bedtime_rounded, size: 80, color: Colors.white38),
          const SizedBox(height: 16),
          const Text("La noche fue tranquila...", style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildResultUI() {
    if (_resultData == null) return _buildWaitingUI();
    bool caught = _resultData!['caught'] ?? false;
    String eliminatedName = _resultData!['eliminatedName'] ?? "Nadie";
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(caught ? "¡VICTORIA!" : "¡DERROTA!", 
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: caught ? AppTheme.safeGreen : AppTheme.impostorRed)),
        const SizedBox(height: 24),
        PlayerAvatar(name: eliminatedName, size: 100),
        const SizedBox(height: 16),
        Text(eliminatedName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(caught ? "Era el Impostor" : "Era inocente...", style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 40),
        Text("Palabra Inocente: ${_resultData!['normalWord']}", style: const TextStyle(color: AppTheme.safeGreen)),
        Text("Palabra Impostor: ${_resultData!['impostorWord']}", style: const TextStyle(color: AppTheme.impostorRed)),
      ],
    );
  }

  Widget _buildSecretCard() {
    return GestureDetector(
      onTap: () {
        setState(() => _revealed = !_revealed);
        AudioService.instance.playClick();
      },
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("TU INFORMACIÓN SECRETA", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 24),
            if (_revealed)
              Column(
                children: [
                  if (_roleLabel != null)
                    Text(_roleLabel!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                  if (_secret != null)
                    Text(_secret!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 12),
                  const Text("¡No dejes que otros lo vean!", style: TextStyle(color: AppTheme.impostorRed, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ).animate().fadeIn().scale()
            else
              const Column(
                children: [
                  Icon(Icons.lock_rounded, size: 60, color: AppTheme.primary),
                  SizedBox(height: 12),
                  Text("TOCA PARA REVELAR", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlayerAvatar(name: widget.myName, size: 24),
          const SizedBox(width: 8),
          Text(widget.myName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
