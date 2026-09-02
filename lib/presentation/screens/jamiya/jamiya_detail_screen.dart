import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/dawwar_provider.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../member/add_member_screen.dart';
import '../payment/payments_screen.dart';

class JamiyaDetailScreen extends StatefulWidget {
  final Jamiya jamiya;
  const JamiyaDetailScreen({super.key, required this.jamiya});

  @override
  State<JamiyaDetailScreen> createState() => _JamiyaDetailScreenState();
}

class _JamiyaDetailScreenState extends State<JamiyaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DawwarProvider>();
      provider.loadMembers(widget.jamiya.id);
      provider.loadPayments(widget.jamiya.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jamiya.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'مشاركة التقرير',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'الأعضاء'),
            Tab(icon: Icon(Icons.payment), text: 'الدفعات'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(jamiya: widget.jamiya),
                PaymentsScreen(jamiya: widget.jamiya),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<DawwarProvider>(
        builder: (_, provider, __) {
          if (_tabController.index == 0 &&
              provider.members.length < widget.jamiya.totalMembers) {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMemberScreen(
                    jamiya: widget.jamiya,
                    nextTurn: provider.members.length + 1,
                  ),
                ),
              ).then((_) {
                provider.loadMembers(widget.jamiya.id);
                provider.loadPayments(widget.jamiya.id);
              }),
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة عضو', style: TextStyle(fontFamily: 'Cairo')),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<DawwarProvider>(
      builder: (_, provider, __) {
        final stats = provider.stats;
        return Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'الصندوق',
                value: '${widget.jamiya.totalPot.toStringAsFixed(0)}DH',
                icon: Icons.account_balance_wallet,
              ),
              _StatItem(
                label: 'دفع',
                value: '${stats['paid'] ?? 0}',
                icon: Icons.check_circle,
                color: AppColors.accentLight,
              ),
              _StatItem(
                label: 'انتظار',
                value: '${stats['pending'] ?? 0}',
                icon: Icons.pending,
                color: Colors.orange.shade200,
              ),
              _StatItem(
                label: 'الأعضاء',
                value: '${provider.members.length}/${widget.jamiya.totalMembers}',
                icon: Icons.people,
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareReport() async {
    final provider = context.read<DawwarProvider>();
    final report = provider.generateShareReport(widget.jamiya);
    await Share.share(report, subject: 'تقرير جمعية ${widget.jamiya.name}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontFamily: 'Cairo', fontSize: 11)),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  final Jamiya jamiya;
  const _MembersTab({required this.jamiya});

  @override
  Widget build(BuildContext context) {
    return Consumer<DawwarProvider>(
      builder: (_, provider, __) {
        final members = provider.members;
        final currentTurn = provider.getCurrentTurn(jamiya);

        if (members.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('لا يوجد أعضاء بعد', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
                Text('أضف الأعضاء لبدء الجمعية', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (_, i) {
            final member = members[i];
            final isCurrent = currentTurn?.id == member.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: isCurrent
                    ? const BorderSide(color: AppColors.accent, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? AppColors.accent : AppColors.primary,
                  child: Text(
                    '${member.turnOrder}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
                title: Row(
                  children: [
                    Text(member.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('دوره الآن', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                subtitle: member.phone != null
                    ? Text(member.phone!, style: const TextStyle(fontFamily: 'Cairo'))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => provider.deleteMember(member.id, jamiya.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
