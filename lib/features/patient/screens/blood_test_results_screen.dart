import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../data/models/blood_test_model.dart';
import '../../../data/repository_locator.dart';

class BloodTestResultsScreen extends StatefulWidget {
  const BloodTestResultsScreen({super.key});

  @override
  State<BloodTestResultsScreen> createState() => _BloodTestResultsScreenState();
}

class _BloodTestResultsScreenState extends State<BloodTestResultsScreen> {
  List<BloodTestModel> _bloodTests = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final tests = await RepositoryLocator.bloodTest.getBloodTestsForPatient(
      user.id,
    );
    if (!mounted) return;
    setState(() {
      _bloodTests = tests;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Future<void> _uploadPdfReport() async {
    final noteCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Blood Test PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a PDF report from clinic or external lab.',
                style: TextStyle(color: cs.outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final user = RepositoryLocator.auth.currentUser;
                  if (user == null) return;
                  try {
                    final picked = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: const ['pdf'],
                      withData: true,
                    );
                    final file = picked?.files.single;
                    final bytes = file?.bytes;
                    if (file == null || bytes == null) return;
                    await RepositoryLocator.bloodTest.addBloodTest(
                      patientId: user.id,
                      fileName: file.name,
                      pdfBytes: bytes,
                      note: noteCtrl.text,
                      uploadedByRole: 'patient',
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF upload failed.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Choose PDF and Upload'),
              ),
            ],
          ),
        );
      },
    );

    noteCtrl.dispose();

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blood test PDF uploaded.')),
        );
      }
    }
  }

  Future<void> _exportUploadedPdf(BloodTestModel report) async {
    setState(() => _busy = true);
    try {
      final bytes = base64Decode(report.pdfBase64);
      await Printing.sharePdf(bytes: bytes, filename: report.fileName);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Test Results'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _uploadPdfReport,
            tooltip: 'Upload PDF',
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bloodTests.isEmpty
          ? Center(
              child: Text(
                'No blood test results yet.',
                style: tt.bodyLarge?.copyWith(color: cs.outline),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _bloodTests.length,
                itemBuilder: (context, i) {
                  final test = _bloodTests[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  test.fileName,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(test.uploadedAt),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded by: ${test.uploadedByRole}',
                            style: tt.bodySmall?.copyWith(color: cs.outline),
                          ),
                          if (test.note != null && test.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                test.note!,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: _busy
                                  ? null
                                  : () => _exportUploadedPdf(test),
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: const Text('Export PDF'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
