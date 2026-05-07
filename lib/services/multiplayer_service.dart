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

  final Strategy strategy = Strategy.P2P_STAR;
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

      await Nearby().startAdvertising(
        userName,
        strategy,
        serviceId: serviceId,
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
          if (connectedEndpointIds.isEmpty) status = ConnectionStatus.hosting;
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

      await Nearby().startDiscovery(
        userName,
        strategy,
        serviceId: serviceId,
        onEndpointFound: (id, name, serviceId) {
          onEndpointFound?.call(id, name);
        },
        onEndpointLost: (id) {
          onEndpointLost?.call(id);
        },
      );
      status = ConnectionStatus.discovering;
    } catch (e) {
      debugPrint('Error discovering: $e');
    }
  }

  Future<void> requestConnection(String userName, String id) async {
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
    // Enviar a todos los conectados por defecto o al primero si es necesario
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

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    connectedEndpointIds.clear();
    endpointNames.clear();
    status = ConnectionStatus.idle;
  }
}
