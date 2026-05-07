// lib/models/doctor_player.dart
enum DoctorRole { ciudadano, doctor, asesino }

extension DoctorRoleExt on DoctorRole {
  String get label {
    switch (this) {
      case DoctorRole.ciudadano: return 'Ciudadano';
      case DoctorRole.doctor:    return 'Doctor';
      case DoctorRole.asesino:   return 'Asesino';
    }
  }

  String get emoji {
    switch (this) {
      case DoctorRole.ciudadano: return '👥';
      case DoctorRole.doctor:    return '💉';
      case DoctorRole.asesino:   return '🔪';
    }
  }
}

class DoctorPlayer {
  final String id;
  String name;
  DoctorRole role;
  bool isAlive;
  int points;
  final String? endpointId;
  int votesReceived;

  // Estado de la noche actual
  bool targetedByAssassin;
  bool savedByDoctor;

  DoctorPlayer({
    required this.id,
    required this.name,
    this.role = DoctorRole.ciudadano,
    this.isAlive = true,
    this.points = 0,
    this.endpointId,
    this.votesReceived = 0,
    this.targetedByAssassin = false,
    this.savedByDoctor = false,
  });

  bool get diedThisNight => targetedByAssassin && !savedByDoctor;

  void resetNightState() {
    targetedByAssassin = false;
    savedByDoctor = false;
  }
}
