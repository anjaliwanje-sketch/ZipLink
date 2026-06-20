import 'dart:io';
import '../discovery/models/peer_device.dart';
import 'transfer_engine.dart';

class GroupTransferRoom {
  final TransferEngine _transferEngine;
  final List<PeerDevice> _roomMembers = [];

  GroupTransferRoom(this._transferEngine);

  List<PeerDevice> get members => List.unmodifiable(_roomMembers);

  void addMember(PeerDevice device) {
    if (!_roomMembers.contains(device)) {
      _roomMembers.add(device);
    }
  }

  void removeMember(PeerDevice device) {
    _roomMembers.remove(device);
  }

  // Broadcast a file to all members in the room
  Future<void> broadcastFile(File file, List<int> sharedSecret) async {
    final futures = <Future<void>>[];

    for (var member in _roomMembers) {
      if (member.ipAddress != null) {
        // Send file to each member concurrently
        futures.add(_transferEngine.sendFile(
          file, 
          member.ipAddress!, 
          8080, 
          sharedSecret
        ));
      }
    }

    // Wait for all transfers to complete or fail
    await Future.wait(futures);
  }
}
