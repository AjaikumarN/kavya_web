import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_stat_card.dart';
import '../../core/widgets/kt_alert_card.dart';
import '../../core/widgets/kt_action_button.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accountant_provider.dart';

class AccountantHomeScreen extends ConsumerWidget {
  const AccountantHomeScreen({super.key});

  String _formatCurrency(num amount) {
    final str = amount.toInt().toString();
    if (str.length <= 3) return '₹$str';
    final last3 = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) parts.insert(0, remaining);
    return '₹${parts.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final dashboard = ref.watch(accountantDashboardProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      body: RefreshIndicator(
        color: KTColors.roleAccountant,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(accountantDashboardProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: KTColors.roleAccountant,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Finance Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notification-list'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: dashboard.when(
                loading: () => const SliverToBoxAdapter(
                  child: KTLoadingShimmer(variant: ShimmerVariant.stat),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: KTErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(accountantDashboardProvider),
                  ),
                ),
                data: (data) {
                  final totalReceivable = (data['total_receivable'] as num?) ?? 0;
                  final overdue = (data['overdue_amount'] as num?) ?? 0;
                  final pendingInvoices = data['pending_invoices'] ?? 0;
                  final pendingExpenses = data['pending_expenses'] ?? 0;
                  final alerts = (data['alerts'] as List?)?.cast<String>() ?? [];

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Hello, ${user?.fullName ?? 'Accountant'}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats ──
                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Total Receivable',
                              value: _formatCurrency(totalReceivable),
                              icon: Icons.account_balance_wallet,
                              color: KTColors.roleAccountant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Overdue',
                              value: _formatCurrency(overdue),
                              icon: Icons.warning_amber,
                              color: KTColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Pending Invoices',
                              value: '$pendingInvoices',
                              icon: Icons.description,
                              color: KTColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Pending Expenses',
                              value: '$pendingExpenses',
                              icon: Icons.receipt_long,
                              color: KTColors.warning,
                            ),
                          ),
                        ],
                      ),

                      if (alerts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        KTAlertCard(
                          count: alerts.length,
                          title: 'Finance Alerts',
                          severity: AlertSeverity.high,
                          items: alerts,
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.account_balance_wallet,
                              label: 'Receivables',
                              color: KTColors.roleAccountant,
                              onTap: () => context.go('/accountant/receivables'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.payments,
                              label: 'Payments',
                              color: KTColors.success,
                              onTap: () => context.push('/accountant/payments'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.description,
                              label: 'Invoices',
                              color: KTColors.info,
                              onTap: () => context.go('/accountant/invoices'),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
