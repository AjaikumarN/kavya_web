import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/expense.dart';
import '../../../providers/expense_provider.dart';
import '../../../core/widgets/kt_button.dart';
import '../../../core/widgets/kt_text_field.dart';
import '../../../core/widgets/photo_capture.dart';
import '../../../services/biometric_auth_service.dart';

class DriverAddExpenseScreen extends ConsumerStatefulWidget {
  const DriverAddExpenseScreen({super.key});

  @override
  ConsumerState<DriverAddExpenseScreen> createState() => _DriverAddExpenseScreenState();
}

class _DriverAddExpenseScreenState extends ConsumerState<DriverAddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'fuel';
  File? _receipt;
  bool _submitting = false;

  static const _categories = ['fuel', 'toll', 'food', 'maintenance', 'loading', 'unloading', 'parking', 'police', 'other'];
  static const double _biometricThreshold = 500.0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    bool biometricVerified = false;

    // Biometric verification for expenses >= ₹500
    if (amount >= _biometricThreshold) {
      final bioService = ref.read(biometricAuthProvider);
      final canBio = await bioService.canUseBiometrics();
      if (canBio) {
        final authenticated = await bioService.authenticate(
          reason: 'Verify identity for expense of ₹${amount.toStringAsFixed(0)}',
        );
        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric verification required for expenses ≥ ₹500')),
            );
          }
          setState(() => _submitting = false);
          return;
        }
        biometricVerified = true;
      } else {
        // Device doesn't support biometrics — allow with flag
        biometricVerified = true;
      }
    }

    final expense = Expense(
      category: _category,
      amount: amount,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: DateTime.now().toIso8601String().split('T').first,
      receiptUrl: _receipt?.path,
    );

    await ref.read(expensesProvider(null).notifier).addExpense(expense, biometricVerified: biometricVerified);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'fuel'),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              KtTextField(
                label: 'Amount (₹)',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                hint: 'e.g., 500',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              KtTextField(label: 'Description', controller: _descCtrl, hint: 'Optional notes', maxLines: 2),
              const SizedBox(height: 16),
              const Text('Receipt Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              PhotoCapture(onCaptured: (file) => setState(() => _receipt = file)),
              const SizedBox(height: 24),
              KtButton(label: 'Save Expense', icon: Icons.save, isLoading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
