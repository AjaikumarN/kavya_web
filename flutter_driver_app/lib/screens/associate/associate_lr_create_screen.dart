import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../providers/associate_provider.dart';
import '../../services/api_service.dart';

class AssociateLRCreateScreen extends ConsumerStatefulWidget {
  final String? jobId;
  const AssociateLRCreateScreen({super.key, this.jobId});

  @override
  ConsumerState<AssociateLRCreateScreen> createState() =>
      _AssociateLRCreateScreenState();
}

class _AssociateLRCreateScreenState
    extends ConsumerState<AssociateLRCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  bool _submitting = false;

  final _consignorNameCtrl = TextEditingController();
  final _consignorGstCtrl = TextEditingController();
  final _consigneeNameCtrl = TextEditingController();
  final _consigneeGstCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _goodsDescCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _packagesCtrl = TextEditingController();
  final _freightCtrl = TextEditingController();

  @override
  void dispose() {
    _consignorNameCtrl.dispose();
    _consignorGstCtrl.dispose();
    _consigneeNameCtrl.dispose();
    _consigneeGstCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _goodsDescCtrl.dispose();
    _weightCtrl.dispose();
    _packagesCtrl.dispose();
    _freightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await _api.createLR({
        if (widget.jobId != null) 'job_id': widget.jobId,
        'consignor_name': _consignorNameCtrl.text.trim(),
        'consignor_gst': _consignorGstCtrl.text.trim(),
        'consignee_name': _consigneeNameCtrl.text.trim(),
        'consignee_gst': _consigneeGstCtrl.text.trim(),
        'from_location': _fromCtrl.text.trim(),
        'to_location': _toCtrl.text.trim(),
        'goods_description': _goodsDescCtrl.text.trim(),
        'weight_kg': double.tryParse(_weightCtrl.text.trim()),
        'num_packages': int.tryParse(_packagesCtrl.text.trim()),
        'freight_amount': double.tryParse(_freightCtrl.text.trim()),
      });
      ref.invalidate(lrListProvider);
      ref.invalidate(jobsNeedingLRProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('LR created successfully'),
              backgroundColor: KTColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Create Lorry Receipt',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAssociate,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.jobId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: KTColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: KTColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Creating LR for Job #${widget.jobId}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: KTColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Consignor ──
              _sectionHeader('Consignor Details'),
              _buildField('Consignor Name', _consignorNameCtrl),
              _buildField('Consignor GST', _consignorGstCtrl,
                  hint: 'e.g. 29ABCDE1234F1Z5'),

              // ── Consignee ──
              _sectionHeader('Consignee Details'),
              _buildField('Consignee Name', _consigneeNameCtrl),
              _buildField('Consignee GST', _consigneeGstCtrl,
                  hint: 'e.g. 29ABCDE1234F1Z5'),

              // ── Route ──
              _sectionHeader('Route'),
              _buildField('From', _fromCtrl),
              _buildField('To', _toCtrl),

              // ── Goods ──
              _sectionHeader('Goods Details'),
              _buildField('Description', _goodsDescCtrl, maxLines: 2),
              Row(
                children: [
                  Expanded(
                      child: _buildField('Weight (kg)', _weightCtrl,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildField('Packages', _packagesCtrl,
                          keyboardType: TextInputType.number)),
                ],
              ),
              _buildField('Freight (₹)', _freightCtrl,
                  keyboardType: TextInputType.number),

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: KTColors.roleAssociate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Create LR',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: KTColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
