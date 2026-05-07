// lib/providers/doctor_game_provider.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/doctor_player.dart';
import '../models/game_settings.dart';

enum DoctorPhase {
  setup,           // Configurar jugadores y roles
  nightIntro,      // Todos cierran los ojos
  nightAssassin,   // El asesino elige a su víctima
  nightDoctor,     // El doctor elige a quién salvar
  dawn,            // Amanece — revelación de lo que pasó
  discussion,      // Discusión del pueblo
  voting,          // Votación para eliminar a alguien
  voteResult,      // Resultado de la votación
  gameOver,        // Fin del juego
}

enum DoctorWinner { none, village, assassins }

class DoctorGameProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // ── Estado ────────────────────────────────────────────────────────────────
  DoctorPhase phase = DoctorPhase.setup;
  List<DoctorPlayer> players = [];
  GameSettings settings = GameSettings();
  int currentRound = 0;

  // ── Configuración de roles ────────────────────────────────────────────────
  int assassinCount = 1;

  // ── Noche ─────────────────────────────────────────────────────────────────
  DoctorPlayer? nightKillTarget;   // a quién eligió el asesino
  DoctorPlayer? nightSaveTarget;   // a quién eligió el doctor
  DoctorPlayer? dawnVictim;        // quien murió esta noche (null = nadie)
  bool savedThisNight = false;

  // ── Votación ──────────────────────────────────────────────────────────────
  Map<String, String?> votes = {};
  int votingTurnIndex = 0;
  DoctorPlayer? eliminatedThisVote;

  // ── Resultado ─────────────────────────────────────────────────────────────
  DoctorWinner winner = DoctorWinner.none;
  List<DoctorPlayer> eliminatedHistory = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  void addPlayer(String name) {
    if (players.length >= settings.maxPlayers) return;
    players.add(DoctorPlayer(id: _uuid.v4(), name: name.trim()));
    notifyListeners();
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void setAssassinCount(int count) {
    assassinCount = count.clamp(1, (players.length ~/ 3).clamp(1, 3));
    notifyListeners();
  }

  bool get canStart => players.length >= settings.minPlayers;

  /// Asigna roles aleatoriamente y arranca la ronda
  void startGame() {
    _assignRoles();
    currentRound = 0;
    eliminatedHistory.clear();
    winner = DoctorWinner.none;
    _startNewRound();
  }

  void _assignRoles() {
    final shuffled = List<DoctorPlayer>.from(players)..shuffle(Random());
    for (int i = 0; i < shuffled.length; i++) {
      if (i < assassinCount) {
        shuffled[i].role = DoctorRole.asesino;
      } else if (i == assassinCount) {
        shuffled[i].role = DoctorRole.doctor;
      } else {
        shuffled[i].role = DoctorRole.ciudadano;
      }
      shuffled[i].isAlive = true;
    }
    notifyListeners();
  }

  void _startNewRound() {
    currentRound++;
    nightKillTarget = null;
    nightSaveTarget = null;
    dawnVictim = null;
    savedThisNight = false;
    votes.clear();
    votingTurnIndex = 0;
    eliminatedThisVote = null;
    for (final p in players) p.resetNightState();
    phase = DoctorPhase.nightIntro;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOCHE
  // ═══════════════════════════════════════════════════════════════════════════

  void beginNightAssassin() {
    phase = DoctorPhase.nightAssassin;
    notifyListeners();
  }

  void assassinChoose(String targetId) {
    nightKillTarget = players.firstWhere((p) => p.id == targetId);
    nightKillTarget!.targetedByAssassin = true;
    phase = DoctorPhase.nightDoctor;
    notifyListeners();
  }

  void doctorChoose(String saveId) {
    // Guard: if no living doctor, skip save
    final hasLivingDoctor = players.any((p) => p.role == DoctorRole.doctor && p.isAlive);
    if (!hasLivingDoctor) {
      _resolveDawn();
      return;
    }
    final target = players.firstWhere(
      (p) => p.id == saveId,
      orElse: () => players.first,
    );
    nightSaveTarget = target;
    nightSaveTarget!.savedByDoctor = true;
    _resolveDawn();
  }

  /// Called when doctor has no living player to save (remote skip)
  void skipDoctorTurn() {
    nightSaveTarget = null;
    _resolveDawn();
  }

  void _resolveDawn() {
    savedThisNight = nightKillTarget != null &&
        nightSaveTarget?.id == nightKillTarget?.id;

    if (!savedThisNight && nightKillTarget != null) {
      nightKillTarget!.isAlive = false;
      dawnVictim = nightKillTarget;
      eliminatedHistory.add(nightKillTarget!);
      // Puntos para el asesino
      for (final p in alivePlayers) {
        if (p.role == DoctorRole.asesino) p.points += settings.pointsForSurviving;
      }
    } else {
      dawnVictim = null;
      // Puntos para el doctor si salvó
      if (savedThisNight) {
        final doc = players.firstWhere((p) => p.role == DoctorRole.doctor);
        doc.points += settings.pointsForCorrectVote;
      }
    }

    phase = DoctorPhase.dawn;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DÍA
  // ═══════════════════════════════════════════════════════════════════════════

  void startDiscussion() {
    phase = DoctorPhase.discussion;
    notifyListeners();
  }

  void startVoting() {
    votes.clear();
    votingTurnIndex = 0;
    phase = DoctorPhase.voting;
    notifyListeners();
  }

  List<DoctorPlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList();

  List<DoctorPlayer> get aliveVoters {
    final alive = alivePlayers;
    if (votingTurnIndex < alive.length) return alive;
    return alive;
  }

  DoctorPlayer get currentVoter {
    final alive = alivePlayers;
    return alive[votingTurnIndex < alive.length ? votingTurnIndex : 0];
  }

  void castVote(String suspectId) {
    final voter = currentVoter;
    votes[voter.id] = suspectId;
    votingTurnIndex++;

    if (votingTurnIndex >= alivePlayers.length) {
      _resolveVote();
    } else {
      notifyListeners();
    }
  }

  void _resolveVote() {
    final count = <String, int>{};
    for (final v in votes.values) {
      if (v != null) count[v] = (count[v] ?? 0) + 1;
    }

    String? topId;
    int topVotes = 0;
    count.forEach((id, v) {
      if (v > topVotes) { topVotes = v; topId = id; }
    });

    if (topId != null) {
      eliminatedThisVote = players.firstWhere((p) => p.id == topId);
      eliminatedThisVote!.isAlive = false;
      eliminatedHistory.add(eliminatedThisVote!);
      for (final p in players) p.votesReceived = count[p.id] ?? 0;

      // Puntos si votaron al asesino
      if (eliminatedThisVote!.role == DoctorRole.asesino) {
        for (final entry in votes.entries) {
          if (entry.value == eliminatedThisVote!.id) {
            final voter = players.firstWhere((p) => p.id == entry.key);
            voter.points += settings.pointsForCorrectVote;
          }
        }
      }
    }

    phase = DoctorPhase.voteResult;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIN CONDITION
  // ═══════════════════════════════════════════════════════════════════════════

  void continueAfterVoteResult() {
    final alive = alivePlayers;
    final aliveAssassins = alive.where((p) => p.role == DoctorRole.asesino).length;
    final aliveVillage = alive.where((p) => p.role != DoctorRole.asesino).length;

    if (aliveAssassins == 0) {
      winner = DoctorWinner.village;
      phase = DoctorPhase.gameOver;
    } else if (aliveAssassins >= aliveVillage) {
      winner = DoctorWinner.assassins;
      phase = DoctorPhase.gameOver;
    } else {
      _startNewRound();
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════════════════════════════

  void resetGame() {
    phase = DoctorPhase.setup;
    for (final p in players) {
      p.isAlive = true;
      p.points = 0;
      p.role = DoctorRole.ciudadano;
      p.votesReceived = 0;
      p.resetNightState();
    }
    currentRound = 0;
    winner = DoctorWinner.none;
    eliminatedHistory.clear();
    notifyListeners();
  }

  void fullReset() {
    players.clear();
    resetGame();
  }

  List<DoctorPlayer> get sortedByPoints {
    final s = List<DoctorPlayer>.from(players);
    s.sort((a, b) => b.points.compareTo(a.points));
    return s;
  }

  void updateSettings(GameSettings s) {
    settings = s;
    notifyListeners();
  }
}
