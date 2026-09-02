import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/models.dart';

class DawwarProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Jamiya> _jamiyas = [];
  List<Member> _members = [];
  List<Payment> _payments = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  List<Jamiya> get jamiyas => _jamiyas;
  List<Member> get members => _members;
  List<Payment> get payments => _payments;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ==================== JAMIYA ====================
  Future<void> loadJamiyas() async {
    _setLoading(true);
    final maps = await _db.getAllJamiyas();
    _jamiyas = maps.map((m) => Jamiya.fromMap(m)).toList();
    _setLoading(false);
  }

  Future<void> addJamiya(Jamiya jamiya) async {
    await _db.insertJamiya(jamiya.toMap());
    await loadJamiyas();
  }

  Future<void> deleteJamiya(String id) async {
    await _db.deleteJamiya(id);
    await loadJamiyas();
  }

  // ==================== MEMBER ====================
  Future<void> loadMembers(String jamiyaId) async {
    _setLoading(true);
    final maps = await _db.getMembersByJamiya(jamiyaId);
    _members = maps.map((m) => Member.fromMap(m)).toList();
    _setLoading(false);
  }

  Future<void> addMember(Member member, Jamiya jamiya) async {
    await _db.insertMember(member.toMap());
    // Auto-generate payments for this member
    await _generatePaymentsForMember(member, jamiya);
    await loadMembers(member.jamiyaId);
  }

  Future<void> deleteMember(String id, String jamiyaId) async {
    await _db.deleteMember(id);
    await loadMembers(jamiyaId);
  }

  Future<void> _generatePaymentsForMember(Member member, Jamiya jamiya) async {
    for (int i = 0; i < jamiya.totalMembers; i++) {
      DateTime dueDate;
      if (jamiya.frequency == 'monthly') {
        dueDate = DateTime(
          jamiya.startDate.year,
          jamiya.startDate.month + i,
          jamiya.startDate.day,
        );
      } else {
        dueDate = jamiya.startDate.add(Duration(days: 7 * i));
      }

      final payment = Payment(
        memberId: member.id,
        jamiyaId: jamiya.id,
        amount: jamiya.amount,
        dueDate: dueDate,
        status: PaymentStatus.pending,
      );
      await _db.insertPayment(payment.toMap());
    }
  }

  // ==================== PAYMENT ====================
  Future<void> loadPayments(String jamiyaId) async {
    _setLoading(true);
    final maps = await _db.getPaymentsByJamiya(jamiyaId);
    _payments = maps.map((m) => Payment.fromMap(m)).toList();
    await _loadStats(jamiyaId);
    _setLoading(false);
  }

  Future<void> markPaymentPaid(Payment payment) async {
    payment.status = PaymentStatus.paid;
    payment.paymentDate = DateTime.now();
    await _db.updatePayment(payment.toMap());
    await loadPayments(payment.jamiyaId);
  }

  Future<void> markPaymentPending(Payment payment) async {
    payment.status = PaymentStatus.pending;
    payment.paymentDate = null;
    await _db.updatePayment(payment.toMap());
    await loadPayments(payment.jamiyaId);
  }

  Future<void> _loadStats(String jamiyaId) async {
    _stats = await _db.getJamiyaStats(jamiyaId);
    notifyListeners();
  }

  // ==================== HELPERS ====================
  List<Payment> getPaymentsForMonth(String jamiyaId, int month, int year) {
    return _payments.where((p) =>
      p.dueDate.month == month && p.dueDate.year == year
    ).toList();
  }

  Member? getCurrentTurn(Jamiya jamiya) {
    if (_members.isEmpty) return null;
    final now = DateTime.now();
    final monthsElapsed = (now.year - jamiya.startDate.year) * 12 +
        now.month - jamiya.startDate.month;
    final currentTurn = monthsElapsed % jamiya.totalMembers;
    try {
      return _members.firstWhere((m) => m.turnOrder == currentTurn + 1);
    } catch (_) {
      return _members.isNotEmpty ? _members.first : null;
    }
  }

  String generateShareReport(Jamiya jamiya) {
    final buffer = StringBuffer();
    buffer.writeln('📊 تقرير جمعية: ${jamiya.name}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 المبلغ الشهري: ${jamiya.amount.toStringAsFixed(0)} درهم');
    buffer.writeln('👥 عدد الأعضاء: ${jamiya.totalMembers}');
    buffer.writeln('🏆 الصندوق الإجمالي: ${jamiya.totalPot.toStringAsFixed(0)} درهم');
    buffer.writeln('');
    buffer.writeln('📋 حالة الدفعات:');
    buffer.writeln('✅ دفع: ${_stats['paid'] ?? 0}');
    buffer.writeln('⏳ في الانتظار: ${_stats['pending'] ?? 0}');
    buffer.writeln('');
    buffer.writeln('👤 الأعضاء وأدوارهم:');
    for (final member in _members) {
      buffer.writeln('  ${member.turnOrder}. ${member.name}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🤝 تطبيق دوّار');
    return buffer.toString();
  }
}
