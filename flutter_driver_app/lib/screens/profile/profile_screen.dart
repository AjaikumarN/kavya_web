import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_role_badge.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.primaryRole ?? 'driver';
    final roleColor = KTColors.roleColor(role);

    return Scaffold(
      backgroundColor: KTColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: roleColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [roleColor, roleColor.withValues(alpha: 0.85)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            (user?.fullName ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.fullName ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        KTRoleBadge(role: role),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Personal Info ──
                _sectionHeader('Personal Info'),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _infoTile(
                          Icons.person_outline, 'Username', user?.username ?? '-'),
                      const Divider(height: 1, indent: 56),
                      _infoTile(
                          Icons.phone_outlined, 'Phone', user?.phone ?? '-'),
                      const Divider(height: 1, indent: 56),
                      _infoTile(
                          Icons.email_outlined, 'Email', user?.email ?? '-'),
                      const Divider(height: 1, indent: 56),
                      _infoTile(
                        Icons.badge_outlined,
                        'Status',
                        user?.isActive == true ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Roles ──
                if (user != null && user.roles.length > 1) ...[
                  _sectionHeader('Roles'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.roles
                            .map((r) => KTRoleBadge(role: r))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── App ──
                _sectionHeader('App'),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _actionTile(
                          Icons.notifications_outlined, 'Notifications', () {
                        context.push('/notification-list');
                      }),
                      const Divider(height: 1, indent: 56),
                      _actionTile(Icons.help_outline, 'Help & Support', () {}),
                      const Divider(height: 1, indent: 56),
                      _actionTile(Icons.info_outline, 'About', () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Kavya Transports',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2025 Kavya Transports',
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Logout ──
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: _actionTile(
                    Icons.logout,
                    'Logout',
                    () {
                      HapticFeedback.mediumImpact();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                              'Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref
                                    .read(authStateProvider.notifier)
                                    .logout();
                                context.go('/login');
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: KTColors.danger,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    color: KTColors.danger,
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: KTColors.textPrimary,
          ),
        ),
      );

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon, color: KTColors.textSecondary, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: KTColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: KTColors.textPrimary,
          ),
        ),
      );

  Widget _actionTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? KTColors.textPrimary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? KTColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
