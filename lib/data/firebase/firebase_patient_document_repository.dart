import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import '../models/patient_document_model.dart';
import 'firebase_service.dart';

class FirebasePatientDocumentRepository {
  final _service = FirebaseService();

  static const _pdfDataUrlPrefix = 'data:application/pdf;base64,';

  /// Primary store (UML). Writes go here only.
  List<MapEntry<String, DatabaseReference>> _primaryRoots(String patientId) {
    return [
      MapEntry(
        'patientDocuments',
        _service.patientDocumentsRef.child(patientId),
      ),
    ];
  }

  /// Legacy paths used when rules only allowed nested writes; still read for old data.
  List<MapEntry<String, DatabaseReference>> _legacyRoots(String patientId) {
    return [
      MapEntry(
        'bloodTests',
        _service.database.ref('bloodTests').child(patientId),
      ),
      MapEntry(
        'notifications/bloodTests',
        _service.database
            .ref('notifications')
            .child('bloodTests')
            .child(patientId),
      ),
      MapEntry(
        'weightEntries/bloodTests',
        _service.database
            .ref('weightEntries')
            .child('bloodTests')
            .child(patientId),
      ),
    ];
  }

  Future<List<PatientDocument>> getDocumentsForPatient(String patientId) async {
    final docs = <PatientDocument>[];
    final roots = [..._primaryRoots(patientId), ..._legacyRoots(patientId)];

    for (final entry in roots) {
      final label = entry.key;
      final ref = entry.value;
      try {
        final snap = await ref.get();
        if (!snap.exists || snap.value == null) continue;
        final raw = Map<String, dynamic>.from(snap.value as Map);
        raw.forEach((key, value) {
          final data = Map<String, dynamic>.from(value as Map);
          docs.add(_fromDbEntry(
            compositeId: '${label}_$key',
            patientId: patientId,
            data: data,
          ));
        });
      } catch (_) {}
    }

    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  Future<void> addDocument({
    required String patientId,
    required String documentType,
    required String fileName,
    required List<int> pdfBytes,
    String? note,
    required String uploadedByRole,
  }) async {
    final fileUrl = '$_pdfDataUrlPrefix${base64Encode(pdfBytes)}';
    final payload = {
      'documentType': documentType,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'fileUrl': fileUrl,
      'fileName': fileName.trim().isEmpty ? 'document.pdf' : fileName.trim(),
      'note': _nullIfEmpty(note),
      'uploadedByRole': uploadedByRole,
    };

    Object? lastError;
    for (final entry in _primaryRoots(patientId)) {
      final rootRef = entry.value;
      final ref = rootRef.push();
      try {
        await ref.set(payload);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('Could not write patient document.');
  }

  PatientDocument _fromDbEntry({
    required String compositeId,
    required String patientId,
    required Map<String, dynamic> data,
  }) {
    final explicitUrl = data['fileUrl'] as String?;
    final legacyB64 = data['pdfBase64'] as String?;
    final fileUrl = (explicitUrl != null && explicitUrl.isNotEmpty)
        ? explicitUrl
        : (legacyB64 != null && legacyB64.isNotEmpty
              ? '$_pdfDataUrlPrefix$legacyB64'
              : '');

    final createdMs =
        data['createdAt'] as int? ?? data['uploadedAt'] as int? ?? 0;

    return PatientDocument(
      id: compositeId,
      patientId: patientId,
      documentType: data['documentType'] as String? ??
          PatientDocument.typeBloodTestPdf,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
      fileUrl: fileUrl,
      fileName: data['fileName'] as String?,
      note: _nullIfEmpty(data['note']),
      uploadedByRole: data['uploadedByRole'] as String?,
    );
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
