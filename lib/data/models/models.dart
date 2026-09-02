import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ==================== JAMIYA MODEL ====================
class Jamiya {
  final String id;
  final String name;
  final double amount;
  final DateTime startDate;
  final int totalMembers;
  final String frequency;
  final DateTime createdAt;

  Jamiya({
    String? id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.totalMembers,
    this.frequency = 'monthly',
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'start_date': startDate.toIso8601String(),
    'total_members': totalMembers,
    'frequency': frequency,
    'created_at': createdAt.toIso8601String(),
  };

  factory Jamiya.fromMap(Map<String, dynamic> map) => Jamiya(
    id: map['id'],
    name: map['name'],
    amount: map['amount'].toDouble(),
    startDate: DateTime.parse(map['start_date']),
    totalMembers: map['total_members'],
    frequency: map['frequency'] ?? 'monthly',
    createdAt: DateTime.parse(map['created_at']),
  );

  double get totalPot => amount * totalMembers;
}

// ==================== MEMBER MODEL ====================
class Member {
  final String id;
  final String jamiyaId;
  final String name;
  final String? phone;
  final int turnOrder;
  final DateTime createdAt;

  Member({
    String? id,
    required this.jamiyaId,
    required this.name,
    this.phone,
    required this.turnOrder,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'jamiya_id': jamiyaId,
    'name': name,
    'phone': phone,
    'turn_order': turnOrder,
    'created_at': createdAt.toIso8601String(),
  };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
    id: map['id'],
    jamiyaId: map['jamiya_id'],
    name: map['name'],
    phone: map['phone'],
    turnOrder: map['turn_order'],
    createdAt: DateTime.parse(map['created_at']),
  );
}

// ==================== PAYMENT MODEL ====================
enum PaymentStatus { pending, paid, late }

class Payment {
  final String id;
  final String memberId;
  final String jamiyaId;
  final double amount;
  DateTime? paymentDate;
  final DateTime dueDate;
  PaymentStatus status;
  final String? note;
  final DateTime createdAt;
  
  // Joined fields
  String? memberName;
  int? turnOrder;

  Payment({
    String? id,
    required this.memberId,
    required this.jamiyaId,
    required this.amount,
    this.paymentDate,
    required this.dueDate,
    this.status = PaymentStatus.pending,
    this.note,
    DateTime? createdAt,
    this.memberName,
    this.turnOrder,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'member_id': memberId,
    'jamiya_id': jamiyaId,
    'amount': amount,
    'payment_date': paymentDate?.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'status': status.name,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    memberId: map['member_id'],
    jamiyaId: map['jamiya_id'],
    amount: map['amount'].toDouble(),
    paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
    dueDate: DateTime.parse(map['due_date']),
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => PaymentStatus.pending,
    ),
    note: map['note'],
    createdAt: DateTime.parse(map['created_at']),
    memberName: map['member_name'],
    turnOrder: map['turn_order'],
  );

  bool get isPaid => status == PaymentStatus.paid;
  bool get isLate => status == PaymentStatus.late || 
    (status == PaymentStatus.pending && dueDate.isBefore(DateTime.now()));
}
