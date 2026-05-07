// lib/widgets/player_avatar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  final String name;
  final bool isImpostor;
  final bool revealed;
  final double size;
  final bool showVotes;
  final int votes;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.isImpostor = false,
    this.revealed = false,
    this.size = 56,
    this.showVotes = false,
    this.votes = 0,
  });

  Color _avatarColor() {
    final colors = [
      const Color(0xFF6C3DE8),
      const Color(0xFFE83D8A),
      const Color(0xFF3DE8D4),
      const Color(0xFFE8A83D),
      const Color(0xFF3D8AE8),
      const Color(0xFF8AE83D),
      const Color(0xFFE83D3D),
      const Color(0xFF3DE88A),
      const Color(0xFFD43DE8),
      const Color(0xFFE8D43D),
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            border: Border.all(
              color: revealed && isImpostor ? AppTheme.impostorRed : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showVotes && votes > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.impostorRed,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$votes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
