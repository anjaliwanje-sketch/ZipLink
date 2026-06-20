import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connection_manager.dart';
import 'models/peer_device.dart';

class DiscoveryService {
  final ConnectionManager _connectionManager;
  final _peersController = StreamController<List<PeerDevice>>.broadcast();

  bool _isDiscovering = false;
  bool _isAdvertising = false;

  DiscoveryService(this._connectionManager) {
    _connectionManager.initialize();
    _connectionManager.discoveredPeers.listen((peers) {
      _peersController.add(peers);
    });
  }

  Stream<List<PeerDevice>> get discoveredPeers => _peersController.stream;
  bool get isDiscovering => _isDiscovering;
  bool get isAdvertising => _isAdvertising;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    await _connectionManager.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    _isDiscovering = false;
    await _connectionManager.stopDiscovery();
  }

  Future<void> startAdvertising(String deviceName) async {
    if (_isAdvertising) return;
    _isAdvertising = true;
    await _connectionManager.startAdvertising(deviceName);
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    _isAdvertising = false;
    await _connectionManager.stopAdvertising();
  }

  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    await _connectionManager.dispose();
    _peersController.close();
  }
}

// Global Provider for DiscoveryService
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final service = DiscoveryService(ConnectionManager());
  ref.onDispose(() => service.dispose());
  return service;
});

final discoveredPeersProvider = StreamProvider<List<PeerDevice>>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  return discoveryService.discoveredPeers;
});
