import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


import '../security/encryption_service.dart';
import 'chunk_streamer.dart';
import 'transfer_state_repository.dart';

class EncryptedChunkInfo {
  final Uint8List data;
  final String fileId;
  final int offset;

  EncryptedChunkInfo(this.data, this.fileId, this.offset);
}

class TransferEngine {
  final _chunkStreamer = ChunkStreamer();
  final _stateRepository = TransferStateRepository();

  TransferEngine() {
    _stateRepository.initialize();
  }

  // Sender Side
  Future<void> sendFile(File file, String receiverIp, int port, List<int> sharedSecret) async {
    final encryptionService = EncryptionService(sharedSecret);
    final fileId = file.path.hashCode.toString();
    final fileSize = await file.length();
    
    // Check local state for resumability
    var state = await _stateRepository.getState(fileId);
    int startOffset = 0;

    if (state != null && state.status == 'interrupted') {
      startOffset = state.bytesTransferred;
      print('Resuming transfer from offset: $startOffset');
    } else {
      await _stateRepository.saveState(TransferStateModel(
        transferId: fileId,
        filePath: file.path,
        totalSize: fileSize,
        bytesTransferred: 0,
        status: 'sending',
      ));
    }

    try {
      final socket = await Socket.connect(receiverIp, port);

      // Send Header: fileId|offset
      socket.add(utf8.encode('HEADER|$fileId|$startOffset\n'));

      final stream = _chunkStreamer.streamFromFile(file, startOffset);

      await for (final chunk in stream) {
        final encryptedChunk = encryptionService.encryptChunk(chunk);
        
        // Prefix with length for framing
        final lengthBytes = ByteData(4)..setInt32(0, encryptedChunk.length, Endian.big);
        socket.add(lengthBytes.buffer.asUint8List());
        socket.add(encryptedChunk);

        startOffset += chunk.length;
        
        // Persist state periodically
        await _stateRepository.saveState(TransferStateModel(
          transferId: fileId,
          filePath: file.path,
          totalSize: fileSize,
          bytesTransferred: startOffset,
          status: 'sending',
        ));
      }

      await socket.flush();
      await socket.close();

      // Transfer complete
      await _stateRepository.saveState(TransferStateModel(
        transferId: fileId,
        filePath: file.path,
        totalSize: fileSize,
        bytesTransferred: startOffset,
        status: 'completed',
      ));

    } catch (e) {
      print('Transfer interrupted: $e');
      await _stateRepository.saveState(TransferStateModel(
        transferId: fileId,
        filePath: file.path,
        totalSize: fileSize,
        bytesTransferred: startOffset,
        status: 'interrupted',
      ));
    }
  }

  // Receiver Side
  Future<void> receiveFile(int port, String saveDir, List<int> sharedSecret) async {
    final encryptionService = EncryptionService(sharedSecret);
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    server.listen((Socket socket) async {
      String? currentFileId;
      int currentOffset = 0;
      File? saveFile;
      
      socket.listen((List<int> data) async {
        // Very basic parsing for demo. In production, need robust framing
        final str = String.fromCharCodes(data).split('\n').first;
        if (str.startsWith('HEADER|')) {
          final parts = str.split('|');
          currentFileId = parts[1];
          currentOffset = int.tryParse(parts[2]) ?? 0;
          saveFile = File('$saveDir/$currentFileId');
          
          if (currentOffset == 0 && await saveFile!.exists()) {
             await saveFile!.delete(); 
          }
          return; // Wait for chunks
        }
        
        if (currentFileId != null && saveFile != null) {
          try {
            // Strip length bytes (first 4 bytes framing) if any, and decrypt
            // For simplicity, we assume we receive full chunks here (production needs buffer)
            if (data.length > 4) {
               final actualData = data.sublist(4);
               final decrypted = encryptionService.decryptChunk(Uint8List.fromList(actualData));
               await _chunkStreamer.writeChunk(saveFile!, currentOffset, decrypted);
               currentOffset += decrypted.length;

               await _stateRepository.saveState(TransferStateModel(
                  transferId: currentFileId!,
                  filePath: saveFile!.path,
                  totalSize: 0, // Need to transmit size in header
                  bytesTransferred: currentOffset,
                  status: 'receiving',
               ));
            }
          } catch(e) {
            print('Decrypt error $e');
          }
        }
      },
      onDone: () async {
        if (currentFileId != null) {
          await _stateRepository.saveState(TransferStateModel(
            transferId: currentFileId!,
            filePath: saveFile!.path,
            totalSize: 0,
            bytesTransferred: currentOffset,
            status: 'completed',
          ));
        }
        socket.destroy();
      });
    });
  }
}
