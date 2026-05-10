// lib/providers/game_provider.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/game_settings.dart';
import '../models/word_pair.dart';

enum GamePhase {
  setup,         // Configuración de jugadores
  wordReveal,    // Revelando palabras por turnos
  discussion,    // Discusión
  voting,        // Votación
  result,        // Resultado de votación
  roundEnd,      // Fin de ronda
  gameOver,      // Juego terminado
}

class GameProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // ── Estado principal ──────────────────────────────────────────────────────
  GamePhase phase = GamePhase.setup;
  List<Player> players = [];
  GameSettings settings = GameSettings();

  // ── Ronda ─────────────────────────────────────────────────────────────────
  int currentRound = 0;
  WordPair? currentWordPair;
  int impostorIndex = -1;
  List<WordPair> _allWords = [];

  // ── Turno de revelación ───────────────────────────────────────────────────
  int currentRevealTurn = 0; // índice del jugador cuya palabra se muestra ahora
  bool wordVisible = false;

  // ── Votación ──────────────────────────────────────────────────────────────
  Map<String, String?> votes = {}; // voterId -> suspectId
  String? votingCurrentPlayerId;   // quién está votando ahora
  int votingTurnIndex = 0;

  // ── Resultado ─────────────────────────────────────────────────────────────
  Player? eliminatedPlayer;
  bool impostorCaught = false;

  // ── Cargado ───────────────────────────────────────────────────────────────
  bool isLoading = false;

  // ═════════════════════════════════════════════════════════════════════════
  // SETUP
  // ═════════════════════════════════════════════════════════════════════════

  void addPlayer(String name) {
    if (players.length >= settings.maxPlayers) return;
    players.add(Player(id: _uuid.v4(), name: name.trim()));
    notifyListeners();
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void renamePlayer(String id, String newName) {
    final idx = players.indexWhere((p) => p.id == id);
    if (idx != -1) players[idx].name = newName.trim();
    notifyListeners();
  }

  void updateSettings(GameSettings s) {
    settings = s;
    notifyListeners();
  }

  bool get canStartGame => players.length >= settings.minPlayers;

  // ═════════════════════════════════════════════════════════════════════════
  // INICIO DE RONDA
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> startRound() async {
    isLoading = true;
    notifyListeners();

    if (_allWords.isEmpty) await _loadWords();

    // Elegir par de palabras al azar
    currentWordPair = _allWords[Random().nextInt(_allWords.length)];

    // Elegir impostor al azar
    impostorIndex = Random().nextInt(players.length);
    for (int i = 0; i < players.length; i++) {
      players[i].isImpostor = (i == impostorIndex);
    }

    // Reiniciar votos y turnos
    votes.clear();
    currentRevealTurn = 0;
    wordVisible = false;
    votingTurnIndex = 0;
    votingCurrentPlayerId = null;
    eliminatedPlayer = null;
    impostorCaught = false;
    currentRound++;

    phase = GamePhase.wordReveal;
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadWords() async {
    final json = await rootBundle.loadString('assets/words/impostor_words.json');
    final list = jsonDecode(json) as List;
    _allWords = list.map((e) => WordPair.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REVELACIÓN DE PALABRAS
  // ═════════════════════════════════════════════════════════════════════════

  Player get currentRevealPlayer => players[currentRevealTurn];

  String get currentPlayerWord {
    if (currentWordPair == null) return '';
    return players[currentRevealTurn].isImpostor
        ? currentWordPair!.impostor
        : currentWordPair!.normal;
  }

  void showWord() {
    wordVisible = true;
    notifyListeners();
  }

  void hideWord() {
    wordVisible = false;
    notifyListeners();
  }

  /// Avanza al siguiente jugador en la revelación. Si ya pasaron todos → discusión.
  void nextRevealTurn() {
    wordVisible = false;
    if (currentRevealTurn < players.length - 1) {
      currentRevealTurn++;
    } else {
      phase = GamePhase.discussion;
    }
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // VOTACIÓN
  // ═════════════════════════════════════════════════════════════════════════

  void startVoting() {
    votes.clear();
    votingTurnIndex = 0;
    votingCurrentPlayerId = players[0].id;
    phase = GamePhase.voting;
    notifyListeners();
  }

  void castVote(String suspectId, {String? voterId}) {
    final effectiveVoterId = voterId ?? votingCurrentPlayerId;
    if (effectiveVoterId == null) return;
    
    votes[effectiveVoterId] = suspectId;

    // Si estamos en modo multijugador (hay remotos), esperamos a que todos voten
    bool isMultiplayer = players.any((p) => p.endpointId != null);
    
    if (isMultiplayer) {
      if (votes.length >= players.length) {
        _resolveVoting();
      }
    } else {
      // En modo local seguimos el turno secuencial
      votingTurnIndex++;
      if (votingTurnIndex < players.length) {
        votingCurrentPlayerId = players[votingTurnIndex].id;
      } else {
        _resolveVoting();
      }
    }
    notifyListeners();
  }

  void _resolveVoting() {
    // Contar votos
    final count = <String, int>{};
    for (final v in votes.values) {
      if (v != null) count[v] = (count[v] ?? 0) + 1;
    }

    // Jugador con más votos
    String? topId;
    int topVotes = 0;
    count.forEach((id, v) {
      if (v > topVotes) {
        topVotes = v;
        topId = id;
      }
    });

    // Asignar votos recibidos a cada jugador
    for (final p in players) {
      p.votesReceived = count[p.id] ?? 0;
    }

    eliminatedPlayer = players.firstWhere((p) => p.id == topId,
        orElse: () => players[0]);
    impostorCaught = eliminatedPlayer!.isImpostor;

    _assignPoints();
    phase = GamePhase.result;
    notifyListeners();
  }

  void _assignPoints() {
    final impostorId = players[impostorIndex].id;
    
    // 1. Cualquier jugador que vote por el impostor gana puntos, sea atrapado o no
    for (final entry in votes.entries) {
      if (entry.value == impostorId) {
        final voterIdx = players.indexWhere((p) => p.id == entry.key);
        if (voterIdx != -1) {
          players[voterIdx].points += settings.pointsForCorrectVote;
        }
      }
    }
    
    // 2. Si el impostor sobrevive (no fue atrapado), gana puntos por sobrevivir
    if (!impostorCaught) {
      players[impostorIndex].points += settings.pointsForSurviving;
    }
    
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FIN DE RONDA / JUEGO
  // ═════════════════════════════════════════════════════════════════════════

  void continueAfterResult() {
    // Verificar si alguien alcanzó los puntos para ganar
    if (settings.endMode == GameEndMode.points) {
      final winner = players.where((p) => p.points >= settings.pointsToWin).toList();
      if (winner.isNotEmpty) {
        phase = GamePhase.gameOver;
        notifyListeners();
        return;
      }
    }
    phase = GamePhase.roundEnd;
    notifyListeners();
  }

  void startNextRound() {
    startRound();
  }

  void resetGame() {
    phase = GamePhase.setup;
    for (final p in players) {
      p.points = 0;
      p.isImpostor = false;
      p.votesReceived = 0;
    }
    currentRound = 0;
    votes.clear();
    eliminatedPlayer = null;
    impostorCaught = false;
    notifyListeners();
  }

  void toggleReady(String playerId) {
    final idx = players.indexWhere((p) => p.id == playerId);
    if (idx != -1) {
      players[idx].isReady = !players[idx].isReady;
      notifyListeners();
    }
  }

  bool get allPlayersReady {
    if (players.isEmpty) return false;
    // En multijugador, todos los remotos deben estar listos. El host (local) se asume listo.
    return players.every((p) => p.endpointId == null || p.isReady);
  }

  void fullReset() {
    players.clear();
    resetGame();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  Player? get winner {
    if (phase != GamePhase.gameOver) return null;
    return players.reduce((a, b) => a.points >= b.points ? a : b);
  }

  List<Player> get sortedByPoints {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.points.compareTo(a.points));
    return sorted;
  }

  Player get currentVoter => players[votingTurnIndex < players.length ? votingTurnIndex : 0];
}
