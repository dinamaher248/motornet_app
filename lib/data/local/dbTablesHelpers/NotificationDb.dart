import 'package:sqflite/sqflite.dart';

import '../AppDatabaseHelper.dart';
import 'dbModels/db_models.dart';

class NotificationDb {
  final _dbHelper = AppDatabaseHelper();

  Future<void> insertItem(NotificationItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'notify',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> findIdByRef(String refId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notify',
      columns: ['id'],
      where: 'ref_id = ?',
      whereArgs: [refId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> removeItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete('notify', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('notify');
  }

  Future<void> markAsRead(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notify',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsReadByRef(String refId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notify',
      {'is_read': 1},
      where: 'ref_id = ?',
      whereArgs: [refId],
    );
  }

  Future<void> markAllRead() async {
    final db = await _dbHelper.database;
    await db.update('notify', {'is_read': 1});
  }

  Future<int> unreadCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notify WHERE is_read = 0 OR is_read IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<NotificationItem>> getAllItems() async {
    final db = await _dbHelper.database;
    final data = await db.query('notify', orderBy: 'id DESC');
    return data.map((e) => NotificationItem.fromMap(e)).toList();
  }
}
