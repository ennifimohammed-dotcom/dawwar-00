import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dawwar_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';

class CreateJamiyaScreen extends StatefulWidget {
  const CreateJamiyaScreen({super.key});

  @override
  State<CreateJamiyaScreen> createState() => _CreateJamiyaScreenState();
}

class _CreateJamiyaScreenState extends State<CreateJamiyaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _membersController = TextEditingController();
  DateTime _startDate = DateTime.now();
  String _frequency = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء جمعية جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                title: '📝 معلومات الجمعية',
                children: [
                  TextFormField(
                    controller: _nameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الجمعية',
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (v) => v!.isEmpty ? 'أدخل اسم الجمعية' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (درهم)',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: 'DH',
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'أدخل المبلغ';
                      if (double.tryParse(v) == null) return 'مبلغ غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _membersController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأعضاء',
                      prefixIcon: Icon(Icons.people),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'أدخل عدد الأعضاء';
                      final n = int.tryParse(v);
                      if (n == null || n < 2) return 'يجب أن يكون 2 أو أكثر';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '📅 التوقيت',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                    title: const Text('تاريخ البداية', style: TextStyle(fontFamily: 'Cairo')),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _pickDate,
                  ),
                  const Divider(),
                  const Text(
                    'التكرار',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FrequencyButton(
                          label: 'شهري',
                          icon: Icons.calendar_month,
                          isSelected: _frequency == 'monthly',
                          onTap: () => setState(() => _frequency = 'monthly'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FrequencyButton(
                          label: 'أسبوعي',
                          icon: Icons.calendar_view_week,
                          isSelected: _frequency == 'weekly',
                          onTap: () => setState(() => _frequency = 'weekly'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_amountController.text.isNotEmpty && _membersController.text.isNotEmpty)
                _buildSummary(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('إنشاء الجمعية'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final members = int.tryParse(_membersController.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('💰 الصندوق الإجمالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          Text(
            '${(amount * members).toStringAsFixed(0)} درهم',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final jamiya = Jamiya(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      startDate: _startDate,
      totalMembers: int.parse(_membersController.text),
      frequency: _frequency,
    );

    await context.read<DawwarProvider>().addJamiya(jamiya);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    super.dispose();
  }
}

class _FrequencyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
