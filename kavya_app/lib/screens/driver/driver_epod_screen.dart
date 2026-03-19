import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../providers/fleet_dashboard_provider.dart';

/// Electronic Proof of Delivery — 4-step stepper:
/// 1. Confirm delivery details
/// 2. Capture receiver signature (drawn)
/// 3. Take photo proof
/// 4. Submit ePOD
class DriverEpodScreen extends ConsumerStatefulWidget {
  final int tripId;
  const DriverEpodScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverEpodScreen> createState() => _DriverEpodScreenState();
}

class _DriverEpodScreenState extends ConsumerState<DriverEpodScreen> {
  int _currentStep = 0;
  bool _deliveryConfirmed = false;
  final _receiverNameCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  File? _photoProof;
  bool _submitting = false;

  // Signature state
  final List<Offset?> _signaturePoints = [];
  bool get _hasSignature => _signaturePoints.any((p) => p != null);

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photoProof = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(apiServiceProvider);

      // Upload photo if taken
      if (_photoProof != null) {
        await api.uploadDocument(
          _photoProof!,
          'epod_photo',
          widget.tripId.toString(),
        );
      }

      // Mark trip as delivered/completed
      await api.updateTripStatus(widget.tripId, 'delivered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ePOD submitted — delivery complete!'),
            backgroundColor: KTColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ePOD failed: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ePOD — Trip #${widget.tripId}'),
        backgroundColor: KTColors.cardSurface,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && !_deliveryConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please confirm delivery details')),
            );
            return;
          }
          if (_currentStep == 1 && !_hasSignature) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please capture receiver signature')),
            );
            return;
          }
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? KTColors.success : KTColors.primary,
                  ),
                  onPressed: _submitting ? null : details.onStepContinue,
                  child: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isLast ? 'Submit ePOD' : 'Next'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Confirm delivery
          Step(
            title: const Text('Confirm Delivery'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _receiverNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Receiver Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Remarks (optional)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _deliveryConfirmed,
                  onChanged: (v) => setState(() => _deliveryConfirmed = v ?? false),
                  title: const Text('I confirm goods delivered in good condition'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Step 2: Signature
          Step(
            title: const Text('Receiver Signature'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _signaturePoints.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) => setState(() => _signaturePoints.add(null)),
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _SignaturePainter(_signaturePoints),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _signaturePoints.clear()),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Signature'),
                ),
              ],
            ),
          ),

          // Step 3: Photo proof
          Step(
            title: const Text('Photo Proof'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                if (_photoProof != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_photoProof!, height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photoProof != null ? 'Retake Photo' : 'Take Photo'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Photo of delivered goods / signed document',
                  style: TextStyle(fontSize: 12, color: KTColors.textSecondary),
                ),
              ],
            ),
          ),

          // Step 4: Review & Submit
          Step(
            title: const Text('Submit'),
            isActive: _currentStep >= 3,
            content: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _reviewRow('Trip', '#${widget.tripId}'),
                    _reviewRow('Receiver', _receiverNameCtrl.text.isEmpty ? '—' : _receiverNameCtrl.text),
                    _reviewRow('Signature', _hasSignature ? '✓ Captured' : '✗ Missing'),
                    _reviewRow('Photo', _photoProof != null ? '✓ Taken' : '⊘ Skipped'),
                    if (_remarksCtrl.text.isNotEmpty)
                      _reviewRow('Remarks', _remarksCtrl.text),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: KTColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
