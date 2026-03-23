import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/fleet_dashboard_provider.dart';
import '../providers/admin_providers.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class AdminComplianceDetailScreen extends ConsumerStatefulWidget {
  final String alertId;
  const AdminComplianceDetailScreen({super.key, required this.alertId});

  @override
  ConsumerState<AdminComplianceDetailScreen> createState() =>
      _AdminComplianceDetailScreenState();
}

class _AdminComplianceDetailScreenState
    extends ConsumerState<AdminComplianceDetailScreen> {
  DateTime? _expiryDate;
  DateTime? _issueDate;
  final _certCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _certCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(adminComplianceAlertsProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Compliance detail',
            style: TextStyle(color: KTColors.darkTextPrimary)),
      ),
      body: alerts.when(
        data: (list) {
          final alert = _findAlert(list);
          if (alert == null) {
            return const Center(
                child: Text('Alert not found',
                    style: TextStyle(color: KTColors.darkTextSecondary)));
          }
          return _body(context, alert);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: KTColors.amber600)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: KTColors.darkTextSecondary))),
      ),
    );
  }

  Map<String, dynamic>? _findAlert(List<dynamic> list) {
    for (final a in list) {
      final m = a as Map<String, dynamic>;
      if (m['id']?.toString() == widget.alertId) return m;
    }
    return null;
  }

  Widget _body(BuildContext context, Map<String, dynamic> alert) {
    final category = alert['category'] as String? ?? '';
    final severity = (alert['severity'] as String? ?? '').toUpperCase();
    final entityType = (alert['entity_type'] as String? ?? '').toUpperCase();
    final entityId = alert['entity_id'];
    final entityName = alert['entity_name'] as String? ??
        alert['registration_number'] as String? ??
        alert['driver_name'] as String? ??
        '—';
    final message = alert['message'] as String? ?? alert['description'] as String? ?? '';
    final expiryRaw = alert['expiry_date'] as String?;
    final daysExpired = _daysExpired(expiryRaw);

    final isVehicle = entityType == 'VEHICLE';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Alert header ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KTColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: _severityColor(severity), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _severityPill(severity),
                const Spacer(),
                Text(category.replaceAll('_', ' '),
                    style: const TextStyle(
                        color: KTColors.darkTextSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              Text(message.isNotEmpty ? message : '$category expired for $entityName',
                  style: const TextStyle(
                      color: KTColors.darkTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (expiryRaw != null)
                Text('Expired: ${_fmtDate(expiryRaw)}',
                    style: const TextStyle(
                        color: KTColors.danger, fontSize: 12)),
              if (daysExpired > 0)
                Text('$daysExpired days overdue',
                    style: const TextStyle(
                        color: KTColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Entity info ──
        _sectionHead('ENTITY DETAILS'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KTColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Type', entityType),
              _detailRow('Name', entityName),
              if (entityId != null) _detailRow('ID', entityId.toString()),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Renewal form (vehicles) ──
        if (isVehicle) ...[
          _sectionHead('RENEW COMPLIANCE'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KTColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateField('Issue date', _issueDate, (d) => setState(() => _issueDate = d)),
                const SizedBox(height: 12),
                _dateField('New expiry date', _expiryDate, (d) => setState(() => _expiryDate = d)),
                const SizedBox(height: 12),
                TextField(
                  controller: _certCtrl,
                  style: const TextStyle(color: KTColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Certificate number (optional)',
                    labelStyle: const TextStyle(color: KTColors.darkTextSecondary),
                    filled: true,
                    fillColor: KTColors.darkElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      _submitting ? 'Submitting…' : 'Mark as renewed',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KTColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => _markRenewed(context, entityId, category),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Driver actions ──
        if (!isVehicle) ...[
          _actionBtn('Remind driver', Icons.notifications_active,
              KTColors.amber600, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder sent to driver')),
            );
          }),
          const SizedBox(height: 10),
          _actionBtn('View driver details', Icons.person, KTColors.info, () {
            if (entityId != null) {
              context.push('/admin/drivers/$entityId');
            }
          }),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _markRenewed(
      BuildContext context, dynamic entityId, String category) async {
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select new expiry date')),
      );
      return;
    }
    setState(() => _submitting = true);
    final api = ref.read(apiServiceProvider);
    try {
      await api.patch(
        '/admin/vehicles/$entityId/compliance',
        data: {
          'compliance_type': category,
          'expiry_date': _expiryDate!.toIso8601String().split('T')[0],
          if (_issueDate != null)
            'issue_date': _issueDate!.toIso8601String().split('T')[0],
          if (_certCtrl.text.isNotEmpty)
            'certificate_number': _certCtrl.text.trim(),
        },
      );
      ref.invalidate(adminComplianceAlertsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compliance marked as renewed')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update compliance')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _dateField(
      String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: KTColors.amber600),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: KTColors.darkElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? DateFormat('dd MMM yyyy').format(value) : label,
                style: TextStyle(
                  color: value != null
                      ? KTColors.darkTextPrimary
                      : KTColors.darkTextSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.calendar_today,
                color: KTColors.darkTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: KTColors.darkTextSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: KTColors.darkTextPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _severityPill(String severity) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(severity,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return KTColors.danger;
      case 'URGENT':
        return KTColors.amber600;
      case 'WARNING':
        return const Color(0xFF7C3AED);
      default:
        return KTColors.info;
    }
  }

  Widget _sectionHead(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: KTColors.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

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

  String _fmtDate(dynamic val) {
    if (val == null) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(val.toString()));
    } catch (_) {
      return val.toString();
    }
  }

  int _daysExpired(String? expiryRaw) {
    if (expiryRaw == null) return 0;
    try {
      final exp = DateTime.parse(expiryRaw);
      final diff = DateTime.now().difference(exp).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }
}
