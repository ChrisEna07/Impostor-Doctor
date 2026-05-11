// lib/screens/multiplayer_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/doctor_player.dart';
import '../providers/game_provider.dart';
import '../providers/doctor_game_provider.dart';
import '../services/audio_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/player_avatar.dart';
import 'remote_player_screen.dart';
import 'setup_screen.dart';
import 'doctor/doctor_setup_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final String gameType;
  final String userName;

  const MultiplayerLobbyScreen({
    super.key,
    required this.gameType,
    required this.userName,
  });

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final _nameController = TextEditingController();
  bool _isHosting = false;
  bool _isDiscovering = false;
  Map<String, String> _connectedPlayers = {}; // id -> name
  Map<String, String> _availableRooms = {}; // id -> name
  Map<String, bool> _readyPlayers = {}; // id -> isReady
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    MultiplayerService.instance.onConnectionInitiated = (id, info) {
      if (_isDiscovering) {
        // Si soy cliente y el host me responde, acepto automático
        MultiplayerService.instance.acceptConnection(id);
      } else {
        _showConnectionDialog(id, info);
      }
    };
    MultiplayerService.instance.onConnected = (id) {
      if (_isDiscovering) {
        // Enviar mi nombre al conectarme
        Future.delayed(const Duration(milliseconds: 500), () {
          MultiplayerService.instance.sendDataTo(id, {
            'type': 'handshake',
            'name': _nameController.text.trim(),
          });
        });
      }
    };
    MultiplayerService.instance.onDataReceived = (id, data) {
      if (data is Map) {
        if (data['type'] == 'handshake') {
          setState(() {
            _connectedPlayers[id] = data['name'] ?? 'Anon';
          });
        } else if (data['type'] == 'start_game') {
          // Si soy cliente y recibo start_game, voy a RemotePlayerScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RemotePlayerScreen(
                gameType: data['gameType'],
                myName: _nameController.text.trim(),
              ),
            ),
          );
        } else if (data['type'] == 'ready_toggle') {
          setState(() {
            _readyPlayers[id] = data['ready'] ?? false;
          });
        }
      }
    };
    MultiplayerService.instance.onDisconnected = (id) {
      setState(() {
        _connectedPlayers.remove(id);
        _statusMsg = "Desconectado de un jugador";
      });
    };
    MultiplayerService.instance.onEndpointFound = (id, name) {
      setState(() {
        _availableRooms[id] = name;
      });
    };
    MultiplayerService.instance.onEndpointLost = (id) {
      setState(() {
        _availableRooms.remove(id);
      });
    };
  }

  @override
  void dispose() {
    MultiplayerService.instance.stopAll();
    super.dispose();
  }

  void _showConnectionDialog(String id, ConnectionInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Petición de Conexión", style: TextStyle(color: Colors.white)),
        content: Text("¿Aceptar conexión de ${info.endpointName}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("RECHAZAR")),
          TextButton(
            onPressed: () {
              MultiplayerService.instance.acceptConnection(id);
              // Enviar mi nombre después de aceptar
              Future.delayed(const Duration(milliseconds: 500), () {
                MultiplayerService.instance.sendDataTo(id, {
                  'type': 'handshake',
                  'name': _nameController.text.trim(),
                });
              });
              setState(() {
                _connectedPlayers[id] = info.endpointName;
                _availableRooms.remove(id);
              });
              Navigator.pop(context);
            },
            child: const Text("ACEPTAR", style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _toggleHosting() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showNameRequiredError();
      return;
    }
    AudioService.instance.playClick();
    if (_isHosting) {
      MultiplayerService.instance.stopAdvertising();
      setState(() { _isHosting = false; _statusMsg = null; });
    } else {
      if (_connectedPlayers.isEmpty) {
        MultiplayerService.instance.stopAll(); 
      }
      MultiplayerService.instance.startHosting(_nameController.text.trim());
      setState(() { 
        _isHosting = true; 
        _isDiscovering = false; 
        _availableRooms.clear();
        _statusMsg = "Sala creada. Esperando que otros se unan..."; 
      });
    }
  }

  void _toggleDiscovering() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showNameRequiredError();
      return;
    }
    AudioService.instance.playClick();
    if (_isDiscovering) {
      MultiplayerService.instance.stopDiscovery();
      setState(() { _isDiscovering = false; _statusMsg = null; _availableRooms.clear(); });
    } else {
      if (_connectedPlayers.isEmpty) {
        MultiplayerService.instance.stopAll(); 
      }
      setState(() { 
        _isDiscovering = true; 
        _isHosting = false; 
        _availableRooms.clear();
        _statusMsg = "Buscando salas...\nAsegúrate de tener Bluetooth y Ubicación activos"; 
      });
      MultiplayerService.instance.startDiscovering(_nameController.text.trim());
    }
  }

  void _showNameRequiredError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Debes ingresar un nombre para jugar en red"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showWebNotSupported() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚫 El modo multijugador por red no es compatible con Web."),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  void _refreshDiscovery() {
    AudioService.instance.playClick();
    if (_isHosting) {
      MultiplayerService.instance.stopAdvertising().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isHosting) MultiplayerService.instance.startHosting(_nameController.text.trim());
        });
      });
    } else if (_isDiscovering) {
      _availableRooms.clear();
      MultiplayerService.instance.stopDiscovery().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isDiscovering) MultiplayerService.instance.startDiscovering(_nameController.text.trim());
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48), // 48 is total padding
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        
                        // Campo de nombre
                        _buildNameField(),
                        const SizedBox(height: 32),
                        
                        // HOST CARD
                        _buildActionCard(
                          title: "SER ANFITRIÓN",
                          subtitle: "Crea la sala y controla el juego",
                          icon: Icons.wifi_tethering_rounded,
                          active: _isHosting,
                          onTap: _toggleHosting,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 20),

                        // JOIN CARD
                        _buildActionCard(
                          title: "UNIRSE A SALA",
                          subtitle: "Conéctate a la partida de un amigo",
                          icon: Icons.sensors_rounded,
                          active: _isDiscovering,
                          onTap: _toggleDiscovering,
                          color: AppTheme.secondary,
                        ),

                        const SizedBox(height: 24),
                        if (_statusMsg != null)
                          Center(
                            child: Column(
                              children: [
                                Text(_statusMsg!, 
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13))
                                  .animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms),
                                const SizedBox(height: 12),
                                if (_isHosting || _isDiscovering)
                                  TextButton.icon(
                                    onPressed: _refreshDiscovery,
                                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                                    label: const Text("REINTENTAR BÚSQUEDA", style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                                  ),
                                const SizedBox(height: 8),
                                const Text(
                                  "TIP: En Oppo/Realme activa el GPS manual\ny asegúrate de que el Bluetooth esté visible.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white30, fontSize: 9),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                        if (_isDiscovering && _availableRooms.isNotEmpty)
                          _buildRoomList(),

                        const Spacer(),
                        
                        if (_connectedPlayers.isNotEmpty)
                          Column(
                            children: [
                              Text("JUGADORES CONECTADOS (${_connectedPlayers.length + 1})", 
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 110,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // Yo (Host o Cliente local)
                                    _playerBubble(_nameController.text.trim(), _isHosting ? "TÚ (HOST)" : "TÚ (CLIENTE)", isReady: true),
                                    // Los demás
                                    ..._connectedPlayers.entries.map((e) => _playerBubble(e.value, _isHosting ? "CLIENTE" : "JUGADOR", isReady: _readyPlayers[e.key] ?? false)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),

                        GradientButton(
                          text: _isHosting 
                            ? "CONFIGURAR PARTIDA" 
                            : (_connectedPlayers.isNotEmpty ? "CONECTADO - ESPERANDO..." : "ELIGE TU ROL"),
                          icon: _isHosting ? Icons.settings_suggest_rounded : Icons.sync_rounded,
                          onPressed: (_isHosting && _connectedPlayers.isNotEmpty) ? () {
                            AudioService.instance.playClick();
                            _startGameFlow();
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  bool get _allReady {
    if (_connectedPlayers.isEmpty) return false;
    return _connectedPlayers.keys.every((id) => _readyPlayers[id] == true);
  }

  Widget _playerBubble(String name, String role, {bool isReady = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Stack(
            children: [
              PlayerAvatar(name: name, size: 50),
              if (isReady)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(role, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SALAS DISPONIBLES", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        ..._availableRooms.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.meeting_room_rounded, color: AppTheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sala de ${e.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("Toca para solicitar unirte", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  AudioService.instance.playClick();
                  MultiplayerService.instance.requestConnection(_nameController.text.trim(), e.key);
                  setState(() => _statusMsg = "Solicitando unirse a ${e.value}...");
                },
                child: const Text("UNIRSE"),
              ),
            ],
          ),
        )).toList(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                icon: Icon(Icons.person_pin_rounded, color: AppTheme.primary),
                hintText: "Tu nombre...",
                border: InputBorder.none,
              ),
              onChanged: (v) {
                // Actualizar en tiempo real si ya estamos conectados
                if (_connectedPlayers.isNotEmpty) {
                  MultiplayerService.instance.sendData({
                    'type': 'handshake',
                    'name': v.trim(),
                  });
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              AudioService.instance.playClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Nombre guardado"), duration: Duration(seconds: 1))
              );
            },
            icon: const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1);
  }

  void _startGameFlow() {
    // Avisar a todos los clientes que empezamos
    MultiplayerService.instance.sendData({
      'type': 'start_game',
      'gameType': widget.gameType,
    });

    // Si es host, vamos a SetupScreen y agregamos a los jugadores conectados
    if (widget.gameType == 'Impostor') {
      final gp = GameProvider();
      // Yo (Host)
      gp.players.add(Player(id: 'local_host', name: _nameController.text.trim()));
      
      // Agregar remotos con su endpointId
      for (var entry in _connectedPlayers.entries) {
        gp.players.add(Player(
          id: entry.key, 
          name: entry.value, 
          endpointId: entry.key,
        ));
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: gp,
            child: const SetupScreen(),
          ),
        ),
      );
    } else {
      // Doctor logic
      final dgp = DoctorGameProvider();
      dgp.players.add(DoctorPlayer(id: 'local_host', name: _nameController.text.trim()));
      
      for (var entry in _connectedPlayers.entries) {
        dgp.players.add(DoctorPlayer(
          id: entry.key, 
          name: entry.value, 
          endpointId: entry.key,
        ));
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: dgp,
            child: const DoctorSetupScreen(),
          ),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        Expanded(
          child: Column(
            children: [
              Text(widget.gameType.toUpperCase(), 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
              const Text("MULTIJUGADOR RED", 
                style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? color : AppTheme.surfaceLight, width: 2),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (active) const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}
