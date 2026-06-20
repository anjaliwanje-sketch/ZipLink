import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../discovery/discovery_service.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 4),
    )..repeat();
    
    // Start discovery automatically when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(discoveryServiceProvider).startDiscovery();
       ref.read(discoveryServiceProvider).startAdvertising("My Device");
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peersAsync = ref.watch(discoveredPeersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Nearby Devices'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Radar Animation area
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _radarController,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                         colors: [
                            Colors.blue.withOpacity(0.0),
                            Colors.blue.withOpacity(0.5),
                         ],
                         stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.cell_wifi, size: 64, color: Colors.blue),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Looking for peers...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: peersAsync.when(
              data: (peers) {
                if (peers.isEmpty) {
                  return const Center(child: Text('No devices found yet.'));
                }
                return ListView.builder(
                  itemCount: peers.length,
                  itemBuilder: (context, index) {
                    final peer = peers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            peer.protocolType.contains('Aware') ? Indexes.wifi_tethering : 
                            peer.protocolType.contains('Direct') ? Icons.wifi_find : Icons.router
                          ),
                        ),
                        title: Text(peer.name),
                        subtitle: Text('Protocol: \${peer.protocolType}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.signal_cellular_alt, color: peer.signalStrength > 70 ? Colors.green : Colors.orange),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Go to Transfer progress
                                context.push('/transfer_progress', extra: {
                                  'peerName': peer.name,
                                  'protocolType': peer.protocolType,
                                });
                              },
                              child: const Text('Connect'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: \$error')),
            ),
          ),
        ],
      ),
    );
  }
}

class Indexes {
  static IconData wifi_tethering = Icons.wifi_tethering;
}
