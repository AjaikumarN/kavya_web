import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pump_dashboard_provider.dart';
import '../../utils/indian_format.dart';

/// Fuel dispensing form — large touch targets for pump-side use.
class PumpDispenseScreen extends ConsumerStatefulWidget {
  const PumpDispenseScreen({super.key});

  @override
  ConsumerState<PumpDispenseScreen> createState() => _PumpDispenseScreenState();
}

class _PumpDispenseScreenState extends ConsumerState<PumpDispenseScreen> {
  static const _cardColor = Color(0xFF334155);
  static const _amber = Color(0xFFFBBF24);
  static const _textPrimary = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF94A3B8);

  final _formKey = GlobalKey<FormState>();
  int? _selectedTankId;
  int? _selectedVehicleId;
  final _litresCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '93.21');
  final _odometerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _litresCtrl.dispose();
    _rateCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(fuelTanksProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider);
    final issueState = ref.watch(fuelIssueNotifierProvider);
    final isSubmitting = issueState is AsyncLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dispense Fuel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Record a fuel dispensing entry',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            const SizedBox(height: 24),

            // Tank Selector
            _label('Select Tank'),
            const SizedBox(height: 8),
            tanksAsync.when(
              loading: () => const LinearProgressIndicator(color: _amber),
              error: (_, __) => const Text('Failed to load tanks', style: TextStyle(color: Colors.red)),
              data: (tanks) => _dropdownField<int>(
                initialValue: _selectedTankId,
                hint: 'Choose fuel tank',
                items: tanks
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.currentStockLitres.toStringAsFixed(0)} L remain)'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTankId = v),
                validator: (v) => v == null ? 'Select a tank' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle Selector
            _label('Vehicle Number'),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              loading: () => const LinearProgressIndicator(color: _amber),
              error: (_, __) => const Text('Failed to load vehicles', style: TextStyle(color: Colors.red)),
              data: (vehicles) => _dropdownField<int>(
                initialValue: _selectedVehicleId,
                hint: 'Search / select vehicle',
                items: vehicles
                    .map((v) => DropdownMenuItem(
                          value: v['id'] as int,
                          child: Text(v['registration_number']?.toString() ?? 'Vehicle #${v['id']}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVehicleId = v),
                validator: (v) => v == null ? 'Select a vehicle' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Litres
            _label('Litres Dispensed'),
            const SizedBox(height: 8),
            _numericField(
              controller: _litresCtrl,
              hint: 'e.g. 120',
              suffix: 'L',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter litres';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter valid quantity';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Rate per litre
            _label('Rate per Litre (₹)'),
            const SizedBox(height: 8),
            _numericField(
              controller: _rateCtrl,
              hint: 'e.g. 93.21',
              prefix: '₹',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter rate';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter valid rate';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Odometer (optional)
            _label('Odometer Reading (optional)'),
            const SizedBox(height: 8),
            _numericField(
              controller: _odometerCtrl,
              hint: 'e.g. 125430',
              suffix: 'km',
            ),
            const SizedBox(height: 20),

            // Notes
            _label('Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(color: _textPrimary),
              decoration: _inputDecoration('Any remarks...'),
            ),
            const SizedBox(height: 32),

            // Total preview
            if (_litresCtrl.text.isNotEmpty && _rateCtrl.text.isNotEmpty)
              _totalPreview(),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.local_gas_station),
                label: Text(isSubmitting ? 'Submitting...' : 'Record Fuel Issue'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _totalPreview() {
    final litres = double.tryParse(_litresCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final total = litres * rate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w600),
          ),
          Text(
            IndianFormat.currency(total),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _amber,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(fuelIssueNotifierProvider.notifier).issueFuel(
          tankId: _selectedTankId!,
          vehicleId: _selectedVehicleId!,
          quantityLitres: double.parse(_litresCtrl.text),
          ratePerLitre: double.parse(_rateCtrl.text),
          odometerReading: _odometerCtrl.text.isNotEmpty
              ? double.parse(_odometerCtrl.text)
              : null,
          remarks: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        );
    if (ok && mounted) {
      // Refresh dashboard data
      ref.invalidate(pumpDashboardProvider);
      ref.invalidate(todayFuelIssuesProvider);
      // Reset form
      _litresCtrl.clear();
      _odometerCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _selectedVehicleId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuel dispensed successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary),
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      onChanged: (_) => setState(() {}),
      validator: validator,
      decoration: _inputDecoration(hint ?? '').copyWith(
        prefixText: prefix,
        prefixStyle: const TextStyle(color: _amber, fontWeight: FontWeight.w700, fontSize: 16),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _dropdownField<T>({
    required T? initialValue,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: initialValue,
      hint: Text(hint, style: const TextStyle(color: _textSecondary)),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _cardColor,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: _inputDecoration(''),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _amber, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
