// lib/models/player.dart
class Player {
  final String id;
  String name;
  int points;
  bool isImpostor;
  final String? endpointId; // Si no es null, es un jugador remoto
  int votesReceived;

  Player({
    required this.id,
    required this.name,
    this.points = 0,
    this.isImpostor = false,
    this.endpointId,
    this.votesReceived = 0,
  });

  Player copyWith({
    String? name,
    int? points,
    bool? isImpostor,
    String? endpointId,
    int? votesReceived,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      points: points ?? this.points,
      isImpostor: isImpostor ?? this.isImpostor,
      endpointId: endpointId ?? this.endpointId,
      votesReceived: votesReceived ?? this.votesReceived,
    );
  }
}
