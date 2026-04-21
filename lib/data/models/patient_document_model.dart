import 'dart:convert';

/// UML entity **PatientDocument**: document type, creation date, secure file URL.
///
/// PDFs uploaded in-app are stored as a `data:application/pdf;base64,...` URL so the
/// field remains a URL while avoiding a separate storage bucket for this project.
class PatientDocument {
  static const String typeBloodTestPdf = 'bloodTestPdf';

  final String id;
  final String patientId;
  final String documentType;
  final DateTime createdAt;
  final String fileUrl;
  final String? fileName;
  final String? note;
  final String? uploadedByRole;

  const PatientDocument({
    required this.id,
    required this.patientId,
    required this.documentType,
    required this.createdAt,
    required this.fileUrl,
    this.fileName,
    this.note,
    this.uploadedByRole,
  });

  String get displayFileName =>
      (fileName != null && fileName!.trim().isNotEmpty)
          ? fileName!.trim()
          : 'document.pdf';

  /// PDF bytes when [fileUrl] is an inline `data:application/pdf;base64,...` URI.
  List<int>? decodePdfBytesFromDataUrl() {
    const prefix = 'data:application/pdf;base64,';
    if (!fileUrl.startsWith(prefix)) return null;
    try {
      return base64Decode(fileUrl.substring(prefix.length));
    } catch (_) {
      return null;
    }
  }
}
