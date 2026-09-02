import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dawwar.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jamiya (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        total_members INTEGER NOT NULL,
        frequency TEXT NOT NULL DEFAULT 'monthly',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE member (
        id TEXT PRIMARY KEY,
        jamiya_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        turn_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (jamiya_id) REFERENCES jamiya(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payment (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        jamiya_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
        FOREIGN KEY (jamiya_id) REFERENCES jamiya(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== JAMIYA ====================
  Future<int> insertJamiya(Map<String, dynamic> jamiya) async {
    final db = await database;
    return await db.insert('jamiya', jamiya);
  }

  Future<List<Map<String, dynamic>>> getAllJamiyas() async {
    final db = await database;
    return await db.query('jamiya', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getJamiya(String id) async {
    final db = await database;
    final results = await db.query('jamiya', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateJamiya(Map<String, dynamic> jamiya) async {
    final db = await database;
    return await db.update('jamiya', jamiya, where: 'id = ?', whereArgs: [jamiya['id']]);
  }

  Future<int> deleteJamiya(String id) async {
    final db = await database;
    return await db.delete('jamiya', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MEMBER ====================
  Future<int> insertMember(Map<String, dynamic> member) async {
    final db = await database;
    return await db.insert('member', member);
  }

  Future<List<Map<String, dynamic>>> getMembersByJamiya(String jamiyaId) async {
    final db = await database;
    return await db.query(
      'member',
      where: 'jamiya_id = ?',
      whereArgs: [jamiyaId],
      orderBy: 'turn_order ASC',
    );
  }

  Future<int> updateMember(Map<String, dynamic> member) async {
    final db = await database;
    return await db.update('member', member, where: 'id = ?', whereArgs: [member['id']]);
  }

  Future<int> deleteMember(String id) async {
    final db = await database;
    return await db.delete('member', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PAYMENT ====================
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payment', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByJamiya(String jamiyaId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, m.name as member_name, m.turn_order 
      FROM payment p 
      JOIN member m ON p.member_id = m.id 
      WHERE p.jamiya_id = ?
      ORDER BY p.due_date ASC, m.turn_order ASC
    ''', [jamiyaId]);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByMember(String memberId) async {
    final db = await database;
    return await db.query('payment', where: 'member_id = ?', whereArgs: [memberId]);
  }

  Future<int> updatePayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.update('payment', payment, where: 'id = ?', whereArgs: [payment['id']]);
  }

  Future<Map<String, dynamic>> getJamiyaStats(String jamiyaId) async {
    final db = await database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment WHERE jamiya_id = ?',
      [jamiyaId],
    );
    
    final paidResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(amount) as total FROM payment WHERE jamiya_id = ? AND status = "paid"',
      [jamiyaId],
    );
    
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment WHERE jamiya_id = ? AND status = "pending"',
      [jamiyaId],
    );

    return {
      'total': totalResult.first['count'],
      'paid': paidResult.first['count'],
      'paid_amount': paidResult.first['total'] ?? 0.0,
      'pending': pendingResult.first['count'],
    };
  }
}
