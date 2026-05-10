// lib/services/multiplayer_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionStatus { idle, hosting, discovering, connected }

class MultiplayerService {
  MultiplayerService._();
  static final MultiplayerService instance = MultiplayerService._();

  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String serviceId = "com.chrizdev.impostordoctor";
  ConnectionStatus status = ConnectionStatus.idle;
  
  Set<String> connectedEndpointIds = {};
  Map<String, String> endpointNames = {}; // id -> name
  
  // Callbacks para la UI
  Function(String, ConnectionInfo)? onConnectionInitiated;
  Function(String)? onConnected;
  Function(String)? onDisconnected;
  Function(String, dynamic)? onDataReceived;
  Function(String, String)? onEndpointFound;
  Function(String?)? onEndpointLost;

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startHosting(String userName) async {
    try {
      bool granted = await checkPermissions();
      if (!granted) return;

      // No detenemos endpoints para permitir que otros se unan si ya hay alguien
      await Nearby().stopAdvertising(); 
      
      await Nearby().startAdvertising(
        userName,
        strategy,
        serviceId: serviceId,
        onConnectionInitiated: (id, info) {
          debugPrint('Conexión iniciada con $id (${info.endpointName})');
          onConnectionInitiated?.call(id, info);
        },
        onConnectionResult: (id, status) {
          debugPrint('Resultado de conexión con $id: $status');
          if (status == Status.CONNECTED) {
            connectedEndpointIds.add(id);
            this.status = ConnectionStatus.connected;
            onConnected?.call(id);
            // Reiniciamos publicidad para asegurar que otros nos vean (algunos dispositivos la ocultan al conectar)
            // Pero con cuidado de no romper la conexión actual
          }
        },
        onDisconnected: (id) {
          debugPrint('Desconectado de $id');
          connectedEndpointIds.remove(id);
          endpointNames.remove(id);
          if (connectedEndpointIds.isEmpty) {
            this.status = ConnectionStatus.hosting;
          }
          onDisconnected?.call(id);
        },
      );
      status = ConnectionStatus.hosting;
    } catch (e) {
      debugPrint('Error hosting: $e');
    }
  }

  Future<void> startDiscovering(String userName) async {
    try {
      bool granted = await checkPermissions();
      if (!granted) return;

      await Nearby().stopDiscovery();

      await Nearby().startDiscovery(
        userName,
        strategy,
        serviceId: serviceId,
        onEndpointFound: (id, name, serviceId) {
          debugPrint('Endpoint encontrado: $id ($name)');
          onEndpointFound?.call(id, name);
        },
        onEndpointLost: (id) {
          debugPrint('Endpoint perdido: $id');
          onEndpointLost?.call(id);
        },
      );
      status = ConnectionStatus.discovering;
    } catch (e) {
      debugPrint('Error discovering: $e');
    }
  }

  Future<void> requestConnection(String userName, String id) async {
    debugPrint('Solicitando conexión a $id');
    await Nearby().requestConnection(
      userName,
      id,
      onConnectionInitiated: (id, info) {
        onConnectionInitiated?.call(id, info);
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          connectedEndpointIds.add(id);
          this.status = ConnectionStatus.connected;
          onConnected?.call(id);
        }
      },
      onDisconnected: (id) {
        connectedEndpointIds.remove(id);
        endpointNames.remove(id);
        if (connectedEndpointIds.isEmpty) status = ConnectionStatus.idle;
        onDisconnected?.call(id);
      },
    );
  }

  void acceptConnection(String id) {
    debugPrint('Aceptando conexión de $id');
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (id, payload) {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          var data = jsonDecode(str);
          if (data is Map && data['type'] == 'handshake') {
            endpointNames[id] = data['name'] ?? 'Anon';
          }
          onDataReceived?.call(id, data);
        }
      },
      onPayloadTransferUpdate: (id, update) {},
    );
  }

  void sendDataTo(String endpointId, dynamic data) {
    String json = jsonEncode(data);
    Nearby().sendBytesPayload(endpointId, Uint8List.fromList(json.codeUnits));
  }

  void sendData(dynamic data) {
    for (var id in connectedEndpointIds) {
      sendDataTo(id, data);
    }
  }

  void broadcastData(dynamic data) {
    String json = jsonEncode(data);
    var bytes = Uint8List.fromList(json.codeUnits);
    for (var id in endpointNames.keys) {
      Nearby().sendBytesPayload(id, bytes);
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
    if (connectedEndpointIds.isEmpty) status = ConnectionStatus.idle;
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
    if (connectedEndpointIds.isEmpty) status = ConnectionStatus.idle;
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    connectedEndpointIds.clear();
    endpointNames.clear();
    status = ConnectionStatus.idle;
  }
}
