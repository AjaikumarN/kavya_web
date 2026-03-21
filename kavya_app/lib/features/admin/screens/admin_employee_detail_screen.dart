import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/fleet_dashboard_provider.dart';
import '../providers/admin_providers.dart';

final _employeeDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, userId) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get('/users/$userId');
  if (response is Map<String, dynamic> && response['data'] != null) {
    return Map<String, dynamic>.from(response['data'] as Map);
  }
  if (response is Map<String, dynamic>) return response;
  return {};
});

class AdminEmployeeDetailScreen extends ConsumerWidget {
  final String userId;
  const AdminEmployeeDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_employeeDetailProvider(userId));

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Employee',
            style: TextStyle(color: KTColors.darkTextPrimary)),
      ),
      body: detail.when(
        data: (d) {
          if (d.isEmpty) {
            return const Center(
                child: Text('Employee not found',
                    style: TextStyle(color: KTColors.darkTextSecondary)));
          }
          return _buildBody(context, ref, d);
        },
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: KTColors.amber600)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style:
                    const TextStyle(color: KTColors.darkTextSecondary))),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, Map<String, dynamic> d) {
    final name =
        '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
    final role = d['role'] as String? ?? d['primary_role'] as String? ?? '—';
    final email = d['email'] as String? ?? '—';
    final phone = d['phone'] as String? ?? '—';
    final isActive = d['is_active'] == true;
    final branch = d['branch_name'] as String? ?? d['branch'] as String? ?? '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KTColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: KTColors.info.withAlpha(30),
                child: Text(
                  name.isNotEmpty
                      ? name.substring(0, name.length.clamp(0, 2)).toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: KTColors.info,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
              ),
              const SizedBox(height: 12),
              Text(name,
                  style: const TextStyle(
                      color: KTColors.darkTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(role,
                  style: const TextStyle(
                      color: KTColors.darkTextSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              _infoRow(Icons.email_outlined, email),
              _infoRow(Icons.phone_outlined, phone),
              _infoRow(Icons.business_outlined, branch),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Actions ──
        _actionBtn('Reset password', Icons.lock_reset, KTColors.info,
            () async {
          final api = ref.read(apiServiceProvider);
          try {
            await api.post('/users/$userId/reset-password');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent')),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to reset password')),
              );
            }
          }
        }),
        const SizedBox(height: 10),
        _actionBtn(
          isActive ? 'Deactivate' : 'Reactivate',
          isActive ? Icons.block : Icons.check_circle_outline,
          isActive ? KTColors.danger : KTColors.success,
          () => _toggleActive(context, ref, d, isActive),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: KTColors.darkTextSecondary, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: KTColors.darkTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _toggleActive(BuildContext context, WidgetRef ref,
      Map<String, dynamic> d, bool isActive) {
    final name =
        '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KTColors.darkSurface,
        title: Text(
          isActive ? 'Deactivate $name?' : 'Reactivate $name?',
          style: const TextStyle(color: KTColors.darkTextPrimary),
        ),
        content: Text(
          isActive
              ? 'They will be logged out immediately.'
              : 'They will regain access.',
          style: const TextStyle(color: KTColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(apiServiceProvider);
              try {
                final endpoint = isActive
                    ? '/users/$userId/deactivate'
                    : '/users/$userId/activate';
                await api.patch(endpoint);
                ref.invalidate(_employeeDetailProvider(userId));
                ref.invalidate(adminEmployeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            isActive ? 'Deactivated' : 'Reactivated')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update')),
                  );
                }
              }
            },
            child: Text(
              isActive ? 'Deactivate' : 'Reactivate',
              style: TextStyle(
                  color: isActive ? KTColors.danger : KTColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
