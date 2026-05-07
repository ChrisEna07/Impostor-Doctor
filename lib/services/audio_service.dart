// lib/services/audio_service.dart
//
// Servicio de audio para Impostor & Doctor.
// Usa archivos locales (assets/sounds/) para funcionar sin conexión.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  // Reproductores separados para no interferirse entre sí
  final AudioPlayer _bgPlayer   = AudioPlayer(); // música de fondo (loop)
  final AudioPlayer _sfxPlayer  = AudioPlayer(); // efectos principales
  final AudioPlayer _sfx2Player = AudioPlayer(); // efectos secundarios simultáneos

  bool _muted = false;
  bool get muted => _muted;

  // ── Rutas de assets locales ───────────────────────────────────────────────
  static const _click    = 'sounds/click.mp3';
  static const _suspense = 'sounds/suspense.mp3';
  static const _victory  = 'sounds/victory.mp3';
  static const _defeat   = 'sounds/defeat.mp3';
  static const _reveal   = 'sounds/reveal.mp3';
  static const _vote     = 'sounds/vote.mp3';
  // Doctor module
  static const _night     = 'sounds/night.mp3';
  static const _eliminate = 'sounds/eliminate.mp3';
  static const _save      = 'sounds/save.mp3';

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.release);
    await _sfx2Player.setReleaseMode(ReleaseMode.release);
    await _bgPlayer.setVolume(0.35);
    await _sfxPlayer.setVolume(0.85);
    await _sfx2Player.setVolume(0.85);
  }

  // ── Mute toggle ───────────────────────────────────────────────────────────

  void toggleMute() {
    _muted = !_muted;
    _bgPlayer.setVolume(_muted ? 0 : 0.35);
  }

  // ── Efectos de sonido ─────────────────────────────────────────────────────

  Future<void> playClick() async {
    if (_muted) return;
    try { await _sfxPlayer.play(AssetSource(_click)); } catch (e) { _log(e); }
  }

  Future<void> playReveal() async {
    if (_muted) return;
    try { await _sfxPlayer.play(AssetSource(_reveal)); } catch (e) { _log(e); }
  }

  Future<void> playVote() async {
    if (_muted) return;
    try { await _sfx2Player.play(AssetSource(_vote)); } catch (e) { _log(e); }
  }

  Future<void> playVictory() async {
    if (_muted) return;
    await stopBackground();
    try { await _sfxPlayer.play(AssetSource(_victory)); } catch (e) { _log(e); }
  }

  Future<void> playDefeat() async {
    if (_muted) return;
    await stopBackground();
    try { await _sfxPlayer.play(AssetSource(_defeat)); } catch (e) { _log(e); }
  }

  Future<void> playEliminate() async {
    if (_muted) return;
    await stopBackground();
    try { await _sfxPlayer.play(AssetSource(_eliminate)); } catch (e) { _log(e); }
  }

  Future<void> playSave() async {
    if (_muted) return;
    try { await _sfx2Player.play(AssetSource(_save)); } catch (e) { _log(e); }
  }

  // ── Música de fondo ───────────────────────────────────────────────────────

  Future<void> startSuspense() async {
    if (_muted) return;
    try {
      await _bgPlayer.stop();
      await _bgPlayer.play(AssetSource(_suspense));
    } catch (e) { _log(e); }
  }

  Future<void> startNight() async {
    if (_muted) return;
    try {
      await _bgPlayer.stop();
      await _bgPlayer.play(AssetSource(_night));
    } catch (e) { _log(e); }
  }

  Future<void> stopBackground() async {
    try { await _bgPlayer.stop(); } catch (e) { _log(e); }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _bgPlayer.dispose();
    await _sfxPlayer.dispose();
    await _sfx2Player.dispose();
  }

  void _log(Object e) {
    if (kDebugMode) debugPrint('[AudioService] $e');
  }
}
