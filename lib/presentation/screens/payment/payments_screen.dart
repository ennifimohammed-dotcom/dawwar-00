import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dawwar_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';

class PaymentsScreen extends StatelessWidget {
  final Jamiya jamiya;
  const PaymentsScreen({super.key, required this.jamiya});

  @override
  Widget build(BuildContext context) {
    return Consumer<DawwarProvider>(
      builder: (_, provider, __) {
        final payments = provider.payments;

        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('لا توجد دفعات بعد', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
                Text('أضف أعضاء لتوليد الدفعات تلقائياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // Group payments by due date month
        final grouped = <String, List<Payment>>{};
        for (final p in payments) {
          final key = '${_monthName(p.dueDate.month)} ${p.dueDate.year}';
          grouped.putIfAbsent(key, () => []).add(p);
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: grouped.entries.map((entry) {
            final monthPayments = entry.value;
            final paidCount = monthPayments.where((p) => p.isPaid).length;
            return _MonthSection(
              monthLabel: entry.key,
              payments: monthPayments,
              paidCount: paidCount,
              total: monthPayments.length,
              onTogglePaid: (payment) {
                if (payment.isPaid) {
                  provider.markPaymentPending(payment);
                } else {
                  provider.markPaymentPaid(payment);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }
}

class _MonthSection extends StatelessWidget {
  final String monthLabel;
  final List<Payment> payments;
  final int paidCount;
  final int total;
  final Function(Payment) onTogglePaid;

  const _MonthSection({
    required this.monthLabel,
    required this.payments,
    required this.paidCount,
    required this.total,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final allPaid = paidCount == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: allPaid ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                allPaid ? Icons.check_circle : Icons.calendar_month,
                color: allPaid ? AppColors.success : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                monthLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: allPaid ? AppColors.success : AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '$paidCount / $total',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: allPaid ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...payments.map((payment) => _PaymentTile(
          payment: payment,
          onToggle: () => onTogglePaid(payment),
        )),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onToggle;

  const _PaymentTile({required this.payment, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isLate = payment.isLate;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: payment.isPaid
                      ? AppColors.success.withOpacity(0.15)
                      : isLate
                          ? AppColors.error.withOpacity(0.1)
                          : Colors.grey.shade100,
                  border: Border.all(
                    color: payment.isPaid
                        ? AppColors.success
                        : isLate
                            ? AppColors.error
                            : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: Icon(
                  payment.isPaid ? Icons.check : isLate ? Icons.warning : Icons.radio_button_unchecked,
                  color: payment.isPaid
                      ? AppColors.success
                      : isLate
                          ? AppColors.error
                          : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.memberName ?? 'غير معروف',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      payment.isPaid
                          ? 'دفع في ${payment.paymentDate?.day}/${payment.paymentDate?.month}'
                          : isLate
                              ? '⚠️ متأخر'
                              : 'في الانتظار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: payment.isPaid
                            ? AppColors.success
                            : isLate
                                ? AppColors.error
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${payment.amount.toStringAsFixed(0)} DH',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: payment.isPaid ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
