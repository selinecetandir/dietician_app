import 'dart:convert';

import '../models/blood_test_model.dart';
import 'firebase_service.dart';

class FirebaseBloodTestRepository {
  final _service = FirebaseService();

  List<MapEntry<String, dynamic>> _candidateRoots(String patientId) {
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

  Future<List<BloodTestModel>> getBloodTestsForPatient(String patientId) async {
    final tests = <BloodTestModel>[];
    for (final entry in _candidateRoots(patientId)) {
      final label = entry.key;
      final ref = entry.value as dynamic;
      try {
        final snap = await ref.get();
        if (!snap.exists || snap.value == null) continue;
        final raw = Map<String, dynamic>.from(snap.value as Map);
        raw.forEach((key, value) {
          final data = Map<String, dynamic>.from(value as Map);
          tests.add(
            BloodTestModel(
              id: '${label}_$key',
              patientId: patientId,
              fileName: data['fileName'] as String? ?? 'blood-test-report.pdf',
              pdfBase64: data['pdfBase64'] as String? ?? '',
              uploadedByRole: data['uploadedByRole'] as String? ?? 'unknown',
              uploadedAt: DateTime.fromMillisecondsSinceEpoch(
                data['uploadedAt'] as int? ?? data['createdAt'] as int? ?? 0,
              ),
              note: _nullIfEmpty(data['note']),
            ),
          );
        });
      } catch (_) {}
    }

    tests.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return tests;
  }

  Future<void> addBloodTest({
    required String patientId,
    required String fileName,
    required List<int> pdfBytes,
    String? note,
    required String uploadedByRole,
  }) async {
    final payload = {
      'fileName': fileName.trim().isEmpty
          ? 'blood-test-report.pdf'
          : fileName.trim(),
      'pdfBase64': base64Encode(pdfBytes),
      'uploadedAt': DateTime.now().millisecondsSinceEpoch,
      'note': _nullIfEmpty(note),
      'uploadedByRole': uploadedByRole,
    };
    Object? lastError;
    for (final entry in _candidateRoots(patientId)) {
      final rootRef = entry.value as dynamic;
      final ref = rootRef.push();
      try {
        await ref.set(payload);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('Could not write blood test to any path.');
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
