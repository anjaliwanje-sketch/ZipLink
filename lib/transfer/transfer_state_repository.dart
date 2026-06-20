import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransferStateModel {
  final String transferId;
  final String filePath;
  final int totalSize;
  final int bytesTransferred;
  final String status;

  TransferStateModel({
    required this.transferId,
    required this.filePath,
    required this.totalSize,
    required this.bytesTransferred,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'transferId': transferId,
      'filePath': filePath,
      'totalSize': totalSize,
      'bytesTransferred': bytesTransferred,
      'status': status,
    };
  }
}

class TransferStateRepository {
  static const _tableName = 'transfer_states';
  Database? _db;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ziplink_transfers.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            transferId TEXT PRIMARY KEY,
            filePath TEXT,
            totalSize INTEGER,
            bytesTransferred INTEGER,
            status TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveState(TransferStateModel state) async {
    if (_db == null) return;
    await _db!.insert(
      _tableName,
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TransferStateModel?> getState(String transferId) async {
    if (_db == null) return null;
    final maps = await _db!.query(
      _tableName,
      where: 'transferId = ?',
      whereArgs: [transferId],
    );

    if (maps.isNotEmpty) {
      return TransferStateModel(
        transferId: maps.first['transferId'] as String,
        filePath: maps.first['filePath'] as String,
        totalSize: maps.first['totalSize'] as int,
        bytesTransferred: maps.first['bytesTransferred'] as int,
        status: maps.first['status'] as String,
      );
    }
    return null;
  }

  Future<void> deleteState(String transferId) async {
    if (_db == null) return;
    await _db!.delete(
      _tableName,
      where: 'transferId = ?',
      whereArgs: [transferId],
    );
  }
}
