import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/auth_provider.dart';
import '../providers/admin_providers.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final branches = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: const Text('Settings',
            style: TextStyle(color: KTColors.darkTextPrimary)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Company Info ──
          _sectionLabel('Company'),
          _tile(Icons.business, 'Kavya Transports', subtitle: 'Company Name'),
          _tile(Icons.pin, 'GSTIN', subtitle: 'Company GST Number'),
          _tile(Icons.phone_outlined, 'Phone'),
          _tile(Icons.email_outlined, 'Email'),
          _tile(Icons.location_on_outlined, 'State'),
          const SizedBox(height: 20),

          // ── Branches ──
          _sectionLabel('Branches'),
          branches.when(
            data: (list) {
              if (list.isEmpty) {
                return _emptyTile('No branches');
              }
              return Column(
                children: list.map<Widget>((b) {
                  final name = b['name'] ?? '—';
                  final city = b['city'] ?? '';
                  final active = b['is_active'] == true;
                  return _tile(
                    Icons.store_outlined,
                    name,
                    subtitle: city,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (active ? KTColors.success : KTColors.danger)
                            .withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(active ? 'Active' : 'Inactive',
                          style: TextStyle(
                              color: active
                                  ? KTColors.success
                                  : KTColors.danger,
                              fontSize: 11)),
                    ),
                    onTap: () => context.push('/admin/branches'),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: KTColors.amber600))),
            error: (_, __) => _emptyTile('Could not load branches'),
          ),
          const SizedBox(height: 20),

          // ── Profile ──
          _sectionLabel('Profile'),
          _tile(Icons.person_outline, user?.name ?? ''),
          _tile(Icons.email_outlined, user?.email ?? '—'),
          _tile(Icons.badge_outlined, 'Admin', subtitle: 'Role'),
          const SizedBox(height: 30),

          // ── Logout ──
          GestureDetector(
            onTap: () => _logout(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: KTColors.danger.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KTColors.danger.withAlpha(40)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: KTColors.danger, size: 18),
                  SizedBox(width: 8),
                  Text('Log out',
                      style: TextStyle(
                          color: KTColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: KTColors.amber600,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _tile(IconData icon, String title,
      {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: KTColors.darkTextSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: KTColors.darkTextPrimary, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: KTColors.darkTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _emptyTile(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
            child: Text(text,
                style: const TextStyle(
                    color: KTColors.darkTextSecondary, fontSize: 13))),
      );

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KTColors.darkSurface,
        title: const Text('Log out',
            style: TextStyle(color: KTColors.darkTextPrimary)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: KTColors.darkTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log out',
                style: TextStyle(color: KTColors.danger)),
          ),
        ],
      ),
    );
  }
}
