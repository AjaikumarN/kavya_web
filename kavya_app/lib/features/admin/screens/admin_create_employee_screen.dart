import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/fleet_dashboard_provider.dart';
import '../providers/admin_providers.dart';

class AdminCreateEmployeeScreen extends ConsumerStatefulWidget {
  const AdminCreateEmployeeScreen({super.key});

  @override
  ConsumerState<AdminCreateEmployeeScreen> createState() =>
      _AdminCreateEmployeeScreenState();
}

class _AdminCreateEmployeeScreenState
    extends ConsumerState<AdminCreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();

  String? _selectedRole;
  int? _selectedBranchId;
  DateTime? _licenseExpiry;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final parts = _nameCtrl.text.trim().split(' ');
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await api.post('/users', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _selectedRole,
        'branch_id': _selectedBranchId,
        'password': _passwordCtrl.text,
        if (_selectedRole == 'DRIVER') ...{
          'license_number': _licenseCtrl.text.trim(),
          'aadhaar_number': _aadhaarCtrl.text.trim(),
          if (_licenseExpiry != null)
            'license_expiry': _licenseExpiry!.toIso8601String().split('T')[0],
        },
      });

      ref.invalidate(adminEmployeesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Employee created. Temporary password sent to ${_emailCtrl.text}')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create employee',
            style: TextStyle(color: KTColors.darkTextPrimary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Full name', _nameCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null),
            _field('Email', _emailCtrl,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                }),
            _field('Phone', _phoneCtrl,
                keyboard: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 10) return 'Min 10 digits';
                  return null;
                }),

            // Role
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: _inputDecor('Role'),
              dropdownColor: KTColors.darkSurface,
              style: const TextStyle(color: KTColors.darkTextPrimary),
              items: const [
                DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                DropdownMenuItem(
                    value: 'PROJECT_ASSOCIATE',
                    child: Text('Project Associate')),
                DropdownMenuItem(
                    value: 'FLEET_MANAGER', child: Text('Fleet Manager')),
                DropdownMenuItem(
                    value: 'ACCOUNTANT', child: Text('Accountant')),
                DropdownMenuItem(value: 'DRIVER', child: Text('Driver')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v),
              validator: (v) => v == null ? 'Required' : null,
            ),

            // Branch
            const SizedBox(height: 12),
            branches.when(
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _selectedBranchId,
                decoration: _inputDecor('Branch'),
                dropdownColor: KTColors.darkSurface,
                style: const TextStyle(color: KTColors.darkTextPrimary),
                items: list.map<DropdownMenuItem<int>>((b) {
                  final m = b as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: m['id'] as int,
                    child: Text(m['name'] as String? ?? '—'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedBranchId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              loading: () => const SizedBox(height: 50),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Password
            _field('Password', _passwordCtrl,
                obscure: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Min 8 chars';
                  return null;
                }),
            _field('Confirm password', _confirmCtrl,
                obscure: true,
                validator: (v) => v != _passwordCtrl.text
                    ? 'Passwords don\'t match'
                    : null),

            // Driver-specific fields
            if (_selectedRole == 'DRIVER') ...[
              const SizedBox(height: 8),
              const Divider(color: KTColors.darkBorder),
              const SizedBox(height: 4),
              const Text('Driver details',
                  style: TextStyle(
                      color: KTColors.darkTextSecondary, fontSize: 12)),
              _field('License number', _licenseCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) {
                    setState(() => _licenseExpiry = picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    style:
                        const TextStyle(color: KTColors.darkTextPrimary),
                    decoration: _inputDecor('License expiry').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: KTColors.darkTextSecondary, size: 18),
                    ),
                    controller: TextEditingController(
                      text: _licenseExpiry != null
                          ? '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'
                          : '',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              _field('Aadhaar number (optional)', _aadhaarCtrl),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: KTColors.amber600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create employee',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard,
      bool obscure = false,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        style: const TextStyle(color: KTColors.darkTextPrimary),
        decoration: _inputDecor(label),
        validator: validator,
      ),
    );
  }

  InputDecoration _inputDecor(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: KTColors.darkTextSecondary),
        filled: true,
        fillColor: KTColors.darkSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );
}
