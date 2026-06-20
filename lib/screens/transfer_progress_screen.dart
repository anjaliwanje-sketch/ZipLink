import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransferProgressScreen extends StatefulWidget {
  final String peerName;
  final String protocolType;

  const TransferProgressScreen({
    super.key,
    required this.peerName,
    required this.protocolType,
  });

  @override
  State<TransferProgressScreen> createState() => _TransferProgressScreenState();
}

class _TransferProgressScreenState extends State<TransferProgressScreen> {
  // Mock progress for UI demonstration
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  void _simulateProgress() async {
    while (_progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _progress += 0.05;
          if (_progress > 1.0) _progress = 1.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer in Progress'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Cancel transfer logic here
            context.pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sending to \${widget.peerName}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text('via \${widget.protocolType}'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              const SizedBox(height: 48),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  Text(
                    '\${(_progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Speed', '45 MB/s', Icons.speed),
                  _buildStatCard('Remaining', '12 sec', Icons.timer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueGrey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
