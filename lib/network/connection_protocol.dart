import 'dart:async';
import '../discovery/models/peer_device.dart';

enum ProtocolType { wifiAware, wifiDirect, hotspot }

abstract class ConnectionProtocol {
  ProtocolType get type;

  // Stream of discovered peers
  Stream<List<PeerDevice>> get discoveredPeers;

  // Lifecycle
  Future<void> initialize();
  Future<void> dispose();

  // Discovery
  Future<void> startDiscovery();
  Future<void> stopDiscovery();

  // Advertising (so others can find this device)
  Future<void> startAdvertising(String deviceName);
  Future<void> stopAdvertising();

  // Connection
  Future<bool> connectTo(PeerDevice peer);
  Future<void> disconnect();

  // Check if protocol is supported and enabled on current hardware
  Future<bool> isSupported();
}
