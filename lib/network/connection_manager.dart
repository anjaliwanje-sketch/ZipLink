import 'dart:async';
import '../discovery/models/peer_device.dart';
import 'connection_protocol.dart';
import 'wifi_aware_protocol.dart';
import 'wifi_direct_protocol.dart';
import 'hotspot_fallback_protocol.dart';

class ConnectionManager {
  final List<ConnectionProtocol> _protocols = [
    WiFiAwareProtocol(),
    WiFiDirectProtocol(),
    HotspotFallbackProtocol(),
  ];

  ConnectionProtocol? _activeProtocol;
  final _peersController = StreamController<List<PeerDevice>>.broadcast();

  // Combine discovered peers from all active protocols
  Stream<List<PeerDevice>> get discoveredPeers => _peersController.stream;
  
  ProtocolType? get activeProtocolType => _activeProtocol?.type;

  Future<void> initialize() async {
    for (var protocol in _protocols) {
      await protocol.initialize();
      protocol.discoveredPeers.listen((peers) {
        _peersController.add(peers);
      });
    }
  }

  Future<void> startDiscovery() async {
    // Start discovery on highest priority supported protocol
    for (var protocol in _protocols) {
      if (await protocol.isSupported()) {
        await protocol.startDiscovery();
        _activeProtocol = protocol;
        print('Started discovery using: ${protocol.type}');
        // Try fallback if we want to run multiple or just stick to one
        // For now, we start all to get the best signal and protocols
      }
    }
  }

  Future<void> stopDiscovery() async {
    for (var protocol in _protocols) {
      await protocol.stopDiscovery();
    }
  }

  Future<void> startAdvertising(String deviceName) async {
    for (var protocol in _protocols) {
      if (await protocol.isSupported()) {
        // Adaptive band switching logic (prefer 5Ghz in native code, fallback to 2.4)
        // Instruct protocol to start advertising
        await protocol.startAdvertising(deviceName);
        _activeProtocol = protocol;
      }
    }
  }

  Future<void> stopAdvertising() async {
    for (var protocol in _protocols) {
      await protocol.stopAdvertising();
    }
  }

  Future<bool> connectTo(PeerDevice peer) async {
    // Find the protocol that discovered this peer
    final matchingProtocol = _protocols.firstWhere(
      (p) {
        if (p.type == ProtocolType.wifiAware && peer.protocolType == 'WiFi Aware') return true;
        if (p.type == ProtocolType.wifiDirect && peer.protocolType == 'WiFi Direct') return true;
        if (p.type == ProtocolType.hotspot && peer.protocolType == 'Hotspot/mDNS') return true;
        return false;
      },
      orElse: () => _protocols.last,
    );

    _activeProtocol = matchingProtocol;
    return await matchingProtocol.connectTo(peer);
  }

  Future<void> disconnect() async {
    for (var protocol in _protocols) {
      await protocol.disconnect();
    }
    _activeProtocol = null;
  }

  Future<void> dispose() async {
    for (var protocol in _protocols) {
      await protocol.dispose();
    }
    _peersController.close();
  }
}
