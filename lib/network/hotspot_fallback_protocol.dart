import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import '../discovery/models/peer_device.dart';
import 'connection_protocol.dart';

class HotspotFallbackProtocol implements ConnectionProtocol {
  final _peersController = StreamController<List<PeerDevice>>.broadcast();
  final Map<String, PeerDevice> _discoveredMap = {};
  MDnsClient? _mDnsClient;
  bool _isAdvertising = false;
  
  static const String _serviceType = '_ziplink._tcp';

  @override
  ProtocolType get type => ProtocolType.hotspot;

  @override
  Stream<List<PeerDevice>> get discoveredPeers => _peersController.stream;

  @override
  Future<void> initialize() async {
    _mDnsClient = MDnsClient();
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    _peersController.close();
  }

  @override
  Future<void> startDiscovery() async {
    if (_mDnsClient == null) return;
    
    _discoveredMap.clear();
    await _mDnsClient!.start();

    _mDnsClient!.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(_serviceType)
    ).listen((PtrResourceRecord ptr) {
      _mDnsClient!.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName)
      ).listen((SrvResourceRecord srv) {
        _mDnsClient!.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target)
        ).listen((IPAddressResourceRecord ipRecord) {
          final deviceName = ptr.domainName.split('.').first;
          final device = PeerDevice(
            id: srv.target,
            name: deviceName,
            ipAddress: ipRecord.address.address,
            protocolType: 'Hotspot/mDNS',
            signalStrength: 100, // Simulated for TCP
          );

          if (!_discoveredMap.containsKey(device.id)) {
            _discoveredMap[device.id] = device;
            _peersController.add(_discoveredMap.values.toList());
          }
        });
      });
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _mDnsClient?.stop();
    _mDnsClient = null;
    _mDnsClient = MDnsClient(); // re-init
  }

  @override
  Future<void> startAdvertising(String deviceName) async {
    _isAdvertising = true;
    // Note: Dart's multicast_dns package does not support ADV yet.
    // In a real Hotspot, one device starts the AP, the other connects. 
    // Here we just log for stub.
    print('Hotspot advertising stub for $deviceName');
  }

  @override
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
  }

  @override
  Future<bool> connectTo(PeerDevice peer) async {
    try {
      if (peer.ipAddress == null) return false;
      // Just check if we can open a socket
      final socket = await Socket.connect(peer.ipAddress, 8080, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (e) {
      print('Hotspot connect failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    // Handled at the TransferEngine level with TCP Sockets
  }

  @override
  Future<bool> isSupported() async {
    return true; // standard TCP/UDP is always supported
  }
}
