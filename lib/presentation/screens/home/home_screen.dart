import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dawwar_provider.dart';
import '../../widgets/jamiya_card.dart';
import '../jamiya/create_jamiya_screen.dart';
import '../jamiya/jamiya_detail_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DawwarProvider>().loadJamiyas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤝', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('دوّار'),
          ],
        ),
      ),
      body: Consumer<DawwarProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.jamiyas.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadJamiyas(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(provider),
                const SizedBox(height: 16),
                ...provider.jamiyas.map((jamiya) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: JamiyaCard(
                    jamiya: jamiya,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JamiyaDetailScreen(jamiya: jamiya),
                      ),
                    ).then((_) => provider.loadJamiyas()),
                    onDelete: () => _confirmDelete(context, provider, jamiya.id),
                  ),
                )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateJamiyaScreen()),
        ).then((_) => context.read<DawwarProvider>().loadJamiyas()),
        icon: const Icon(Icons.add),
        label: const Text('جمعية جديدة', style: TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildHeader(DawwarProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جمعياتي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.jamiyas.length} جمعية نشطة',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد جمعيات بعد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أنشئ جمعيتك الأولى الآن',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateJamiyaScreen()),
            ).then((_) => context.read<DawwarProvider>().loadJamiyas()),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء جمعية', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DawwarProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجمعية', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من حذف هذه الجمعية؟ سيتم حذف جميع البيانات.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteJamiya(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
