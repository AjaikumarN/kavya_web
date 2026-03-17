import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/kt_colors.dart';
import '../../services/api_service.dart';

class AssociateDocUploadScreen extends ConsumerStatefulWidget {
  const AssociateDocUploadScreen({super.key});

  @override
  ConsumerState<AssociateDocUploadScreen> createState() =>
      _AssociateDocUploadScreenState();
}

class _AssociateDocUploadScreenState
    extends ConsumerState<AssociateDocUploadScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  bool _submitting = false;

  String _docType = 'pod';
  final _linkedIdCtrl = TextEditingController();
  String? _filePath;
  String? _fileName;

  @override
  void dispose() {
    _linkedIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() {
        _filePath = file.path;
        _fileName = file.name;
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() {
        _filePath = file.path;
        _fileName = file.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_submitting) return;
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a file'),
            backgroundColor: KTColors.warning),
      );
      return;
    }
    if (_linkedIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a Trip/LR ID'),
            backgroundColor: KTColors.warning),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await _api.uploadDocument(
        _filePath!,
        _docType,
        _linkedIdCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document uploaded'),
              backgroundColor: KTColors.success),
        );
        setState(() {
          _filePath = null;
          _fileName = null;
          _linkedIdCtrl.clear();
        });
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
        title: Text('Upload Document',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAssociate,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Document Type ──
            DropdownButtonFormField<String>(
              initialValue: _docType,
              decoration: InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'pod', child: Text('Proof of Delivery (POD)')),
                DropdownMenuItem(value: 'lr', child: Text('Lorry Receipt')),
                DropdownMenuItem(value: 'invoice', child: Text('Invoice')),
                DropdownMenuItem(value: 'weighment', child: Text('Weighment Slip')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _docType = v);
              },
            ),
            const SizedBox(height: 16),

            // ── Linked ID ──
            TextFormField(
              controller: _linkedIdCtrl,
              decoration: InputDecoration(
                labelText: 'Trip / LR / Job ID',
                hintText: 'Enter the related ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── File ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _filePath != null
                      ? KTColors.success
                      : KTColors.divider,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _filePath != null
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: _filePath != null
                        ? KTColors.success
                        : KTColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fileName ?? 'No file selected',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: KTColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _submitting ? null : _upload,
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
                        'Upload',
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
    );
  }
}
