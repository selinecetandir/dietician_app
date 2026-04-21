import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../data/models/patient_document_model.dart';
import '../../../data/repository_locator.dart';

class PatientDocumentsScreen extends StatefulWidget {
  const PatientDocumentsScreen({super.key});

  @override
  State<PatientDocumentsScreen> createState() => _PatientDocumentsScreenState();
}

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen> {
  List<PatientDocument> _documents = [];
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

    final docs = await RepositoryLocator.patientDocument.getDocumentsForPatient(
      user.id,
    );
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _typeLabel(String type) {
    switch (type) {
      case PatientDocument.typeBloodTestPdf:
        return 'Blood test (PDF)';
      default:
        return type;
    }
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
                'Upload document (PDF)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a PDF (e.g. lab results). Stored with type, date, and URL.',
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
                    await RepositoryLocator.patientDocument.addDocument(
                      patientId: user.id,
                      documentType: PatientDocument.typeBloodTestPdf,
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
          const SnackBar(content: Text('Document uploaded.')),
        );
      }
    }
  }

  Future<void> _exportPdf(PatientDocument doc) async {
    setState(() => _busy = true);
    try {
      final bytes = doc.decodePdfBytesFromDataUrl();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This document URL cannot be exported from the app (only inline PDF data URLs are supported).',
              ),
            ),
          );
        }
        return;
      }
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: doc.displayFileName,
      );
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
        title: const Text('My documents'),
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
          : _documents.isEmpty
          ? Center(
              child: Text(
                'No documents yet.',
                style: tt.bodyLarge?.copyWith(color: cs.outline),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _documents.length,
                itemBuilder: (context, i) {
                  final doc = _documents[i];
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
                                  doc.displayFileName,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(doc.createdAt),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _typeLabel(doc.documentType),
                            style: tt.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (doc.uploadedByRole != null &&
                              doc.uploadedByRole!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Uploaded by: ${doc.uploadedByRole}',
                                style: tt.bodySmall?.copyWith(color: cs.outline),
                              ),
                            ),
                          if (doc.note != null && doc.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                doc.note!,
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
                                  : () => _exportPdf(doc),
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
