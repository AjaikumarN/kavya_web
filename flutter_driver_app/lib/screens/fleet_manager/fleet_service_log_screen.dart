import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../services/api_service.dart';
import '../../providers/fleet_provider.dart';

class FleetServiceLogScreen extends ConsumerStatefulWidget {
  const FleetServiceLogScreen({super.key});

  @override
  ConsumerState<FleetServiceLogScreen> createState() =>
      _FleetServiceLogScreenState();
}

class _FleetServiceLogScreenState
    extends ConsumerState<FleetServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  bool _submitting = false;

  final _vehicleIdCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();

  @override
  void dispose() {
    _vehicleIdCtrl.dispose();
    _typeCtrl.dispose();
    _descCtrl.dispose();
    _odometerCtrl.dispose();
    _costCtrl.dispose();
    _vendorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await _api.logService({
        'vehicle_id': int.tryParse(_vehicleIdCtrl.text.trim()) ?? 0,
        'service_type': _typeCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'odometer_km': double.tryParse(_odometerCtrl.text.trim()) ?? 0,
        'cost': double.tryParse(_costCtrl.text.trim()) ?? 0,
        'vendor': _vendorCtrl.text.trim(),
      });
      ref.invalidate(vehicleListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service logged'), backgroundColor: KTColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
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
        title: Text('Log Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleFleet,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField('Vehicle ID', _vehicleIdCtrl,
                  keyboardType: TextInputType.number),
              _buildField('Service Type', _typeCtrl,
                  hint: 'e.g. Oil Change, Brake Service'),
              _buildField('Description', _descCtrl, maxLines: 3),
              _buildField('Odometer (km)', _odometerCtrl,
                  keyboardType: TextInputType.number),
              _buildField('Cost (₹)', _costCtrl,
                  keyboardType: TextInputType.number),
              _buildField('Vendor / Workshop', _vendorCtrl, required: false),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: KTColors.roleFleet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
