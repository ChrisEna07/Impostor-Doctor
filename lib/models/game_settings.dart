// lib/models/game_settings.dart

enum GameEndMode { points, penalty }

class GameSettings {
  int maxPlayers;
  int minPlayers;
  int pointsToWin;
  GameEndMode endMode;
  int pointsForCorrectVote; // puntos por votar al impostor
  int pointsForSurviving;   // puntos para el impostor si no es descubierto
  bool allowBluetooth;

  GameSettings({
    this.maxPlayers = 10,
    this.minPlayers = 3,
    this.pointsToWin = 10,
    this.endMode = GameEndMode.points,
    this.pointsForCorrectVote = 2,
    this.pointsForSurviving = 3,
    this.allowBluetooth = false,
  });

  GameSettings copyWith({
    int? maxPlayers,
    int? minPlayers,
    int? pointsToWin,
    GameEndMode? endMode,
    int? pointsForCorrectVote,
    int? pointsForSurviving,
    bool? allowBluetooth,
  }) {
    return GameSettings(
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      pointsToWin: pointsToWin ?? this.pointsToWin,
      endMode: endMode ?? this.endMode,
      pointsForCorrectVote: pointsForCorrectVote ?? this.pointsForCorrectVote,
      pointsForSurviving: pointsForSurviving ?? this.pointsForSurviving,
      allowBluetooth: allowBluetooth ?? this.allowBluetooth,
    );
  }
}
