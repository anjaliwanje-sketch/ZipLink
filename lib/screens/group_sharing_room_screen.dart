import 'package:flutter/material.dart';

class GroupSharingRoomScreen extends StatelessWidget {
  const GroupSharingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Sharing Room'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 100, color: Colors.indigo),
            const SizedBox(height: 24),
            const Text(
              'Broadcast to Multiple Devices',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Join or create a room to share files with everyone at once.'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Room'),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Join Room'),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
