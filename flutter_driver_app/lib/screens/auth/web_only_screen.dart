import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_role_badge.dart';
import '../../providers/auth_provider.dart';

class WebOnlyScreen extends ConsumerWidget {
  const WebOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.primaryRole ?? 'admin';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Role badge ──
                  KTRoleBadge(role: role),
                  const SizedBox(height: 24),

                  // ── Icon ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: KTColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.desktop_mac_outlined,
                        color: KTColors.primary, size: 40),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Use Web Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: KTColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your role (${KTColors.roleLabel(role)}) requires the full web dashboard for best experience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: KTColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── QR Code ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: 'https://erp.kavyatransports.com',
                      version: QrVersions.auto,
                      size: 160,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: KTColors.primaryDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: KTColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan to open web dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Logout ──
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(authStateProvider.notifier).logout();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KTColors.danger,
                      side: const BorderSide(color: KTColors.danger),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
