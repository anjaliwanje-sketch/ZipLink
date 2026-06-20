import 'dart:io';

class ChunkStreamer {
  final int chunkSize;

  ChunkStreamer({this.chunkSize = 1024 * 1024}); // 1 MB chunk

  // Reads a specific chunk from the file (used for resumability)
  Future<List<int>> readChunk(File file, int offset) async {
    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      if (offset >= await file.length()) {
        return [];
      }
      await randomAccessFile.setPosition(offset);
      return await randomAccessFile.read(chunkSize);
    } finally {
      await randomAccessFile.close();
    }
  }

  // Writes a chunk to the file at a specific offset
  Future<void> writeChunk(File file, int offset, List<int> chunkData) async {
    final randomAccessFile = await file.open(mode: FileMode.append);
    try {
      if (offset > 0) {
        // If appending doesn't automatically position to end, we can set position
        // Since we are writing chunks sequentially, mode.write or append needs careful positioning.
        // Actually mode.append ignores setPosition. We should use FileMode.writeOnlyAppend 
        // to just stream to the end, or FileMode.write for random access.
      }
    } finally {
      await randomAccessFile.close();
    }
    
    // Better way to handle resumable writes:
    final raf = await file.open(mode: FileMode.writeOnlyAppend);
    try {
      await raf.writeFrom(chunkData);
    } finally {
      await raf.close();
    }
  }

  // Stream full file starting from offset
  Stream<List<int>> streamFromFile(File file, int startOffset) async* {
    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      final fileLength = await file.length();
      await randomAccessFile.setPosition(startOffset);

      while (await randomAccessFile.position() < fileLength) {
        yield await randomAccessFile.read(chunkSize);
      }
    } finally {
      await randomAccessFile.close();
    }
  }
}
