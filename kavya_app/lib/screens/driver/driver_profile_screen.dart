import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/auth_provider.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName ?? 'Driver';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Gradient Header ──────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KTColors.primary.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F1A2E), width: 2),
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: KTColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KTColors.primary.withValues(alpha: 0.35)),
                ),
                child: Text(
                  (user?.role ?? 'driver').toUpperCase(),
                  style: const TextStyle(
                    color: KTColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Personal Info ────────────────────────────────────────────────
        _SectionGroup(
          title: 'Personal Info',
          children: [
            _InfoTile(Icons.person_outline, 'Full Name', user?.fullName ?? '-'),
            _InfoTile(Icons.email_outlined, 'Email', user?.email.isNotEmpty == true ? user!.email : '-'),
            _InfoTile(Icons.phone_outlined, 'Phone', user?.phone?.isNotEmpty == true ? user!.phone! : '-'),
            _InfoTile(
              Icons.badge_outlined,
              'Status',
              user == null ? '-' : (user.isActive ? 'Active' : 'Inactive'),
              valueColor: user == null ? null : (user.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── App ──────────────────────────────────────────────────────────
        _SectionGroup(
          title: 'App',
          children: [
            _ActionTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              subtitle: 'Contact us for assistance',
              onTap: () {},
            ),
            _ActionTile(
              icon: Icons.info_outline,
              label: 'About',
              subtitle: 'App info & open-source licenses',
              onTap: () => _showAboutSheet(context),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Logout ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LogoutButton(ref: ref),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AboutSheet(),
    );
  }
}

// ── Reusable Section Group ────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KTColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2D45)),
            ),
            child: Column(
              children: List.generate(children.length, (i) => Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: 1, indent: 56, color: const Color(0xFF1E2D45)),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KTColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: KTColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: KTColors.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KTColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: KTColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: KTColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D1515)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── About Bottom Sheet ────────────────────────────────────────────────────────

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  // App icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: KTColors.primary.withValues(alpha: 0.45),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'KT Driver App',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2D45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AboutInfoRow(icon: Icons.business_outlined, label: 'Company', value: 'Kavya Transports'),
                  const SizedBox(height: 10),
                  _AboutInfoRow(icon: Icons.copyright_outlined, label: 'Copyright', value: '© 2025 Kavya Transports'),
                  const SizedBox(height: 10),
                  _AboutInfoRow(icon: Icons.code_outlined, label: 'Built with', value: 'Flutter & FastAPI'),
                  const SizedBox(height: 24),
                  // View licenses
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFF8C00),
                                  surface: Color(0xFF111827),
                                ),
                                scaffoldBackgroundColor: const Color(0xFF0A0F1E),
                                cardColor: const Color(0xFF111827),
                                appBarTheme: const AppBarTheme(
                                  backgroundColor: Color(0xFF0D1424),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  titleTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              child: const LicensePage(
                                applicationName: 'KT Driver App',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© 2025 Kavya Transports',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.article_outlined, size: 16),
                      label: const Text('View Open Source Licenses'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KTColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── About Info Row ────────────────────────────────────────────────────────────

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: KTColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
