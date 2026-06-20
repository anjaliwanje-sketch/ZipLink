import 'dart:async';
import 'package:flutter/services.dart';
import '../discovery/models/peer_device.dart';
import 'connection_protocol.dart';

class WiFiDirectProtocol implements ConnectionProtocol {
  static const MethodChannel _channel = MethodChannel('com.ziplink.networking/wifi_direct');

  final _peersController = StreamController<List<PeerDevice>>.broadcast();
  final List<PeerDevice> _discoveredDevices = [];

  @override
  ProtocolType get type => ProtocolType.wifiDirect;

  @override
  Stream<List<PeerDevice>> get discoveredPeers => _peersController.stream;

  @override
  Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeviceDiscovered') {
        final args = call.arguments as Map;
        final device = PeerDevice(
          id: args['id'],
          name: args['name'],
          protocolType: 'WiFi Direct',
          signalStrength: args['rssi'] ?? 60,
        );
        if (!_discoveredDevices.contains(device)) {
          _discoveredDevices.add(device);
          _peersController.add(List.from(_discoveredDevices));
        }
      }
    });
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    _peersController.close();
  }

  @override
  Future<void> startDiscovery() async {
    _discoveredDevices.clear();
    try {
      await _channel.invokeMethod('startDiscovery');
    } on PlatformException catch (e) {
      print("Failed to start WiFi Direct discovery: '${e.message}'.");
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } on PlatformException catch (e) {
      print("Failed to stop WiFi Direct discovery: '${e.message}'.");
    }
  }

  @override
  Future<void> startAdvertising(String deviceName) async {
    try {
      await _channel.invokeMethod('startAdvertising', {'deviceName': deviceName});
    } on PlatformException catch (e) {
      print("Failed to start WiFi Direct advertising: '${e.message}'.");
    }
  }

  @override
  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopAdvertising');
    } on PlatformException catch (e) {
      print("Failed to stop WiFi Direct advertising: '${e.message}'.");
    }
  }

  @override
  Future<bool> connectTo(PeerDevice peer) async {
    try {
      final result = await _channel.invokeMethod('connect', {'deviceId': peer.id});
      return result == true;
    } on PlatformException catch (e) {
      print("Failed to connect via WiFi Direct: '${e.message}'.");
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect WiFi Direct: '${e.message}'.");
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod('isSupported');
      return result == true;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
