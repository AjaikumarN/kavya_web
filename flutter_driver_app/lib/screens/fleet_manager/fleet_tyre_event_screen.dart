import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../services/api_service.dart';

class FleetTyreEventScreen extends ConsumerStatefulWidget {
  const FleetTyreEventScreen({super.key});

  @override
  ConsumerState<FleetTyreEventScreen> createState() =>
      _FleetTyreEventScreenState();
}

class _FleetTyreEventScreenState extends ConsumerState<FleetTyreEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  bool _submitting = false;

  final _vehicleIdCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _eventType = 'rotation';

  @override
  void dispose() {
    _vehicleIdCtrl.dispose();
    _positionCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await _api.recordTyreEvent({
        'vehicle_id': int.tryParse(_vehicleIdCtrl.text.trim()),
        'event_type': _eventType,
        'tyre_position': _positionCtrl.text.trim(),
        'odometer_km': double.tryParse(_odometerCtrl.text.trim()),
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tyre event recorded'), backgroundColor: KTColors.success),
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
        title: Text('Tyre Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

              // ── Event Type ──
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _eventType,
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rotation', child: Text('Rotation')),
                    DropdownMenuItem(value: 'replacement', child: Text('Replacement')),
                    DropdownMenuItem(value: 'puncture', child: Text('Puncture')),
                    DropdownMenuItem(value: 'retread', child: Text('Retread')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _eventType = v);
                  },
                ),
              ),

              _buildField('Tyre Position', _positionCtrl,
                  hint: 'e.g. Front Left, Rear Right'),
              _buildField('Odometer (km)', _odometerCtrl,
                  keyboardType: TextInputType.number),
              _buildField('Notes', _notesCtrl, maxLines: 3, required: false),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: KTColors.warning,
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
                          'Record Event',
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
