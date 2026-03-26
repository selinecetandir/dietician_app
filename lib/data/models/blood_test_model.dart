class BloodTestModel {
  final String id;
  final String patientId;
  final String fileName;
  final String pdfBase64;
  final String uploadedByRole;
  final DateTime uploadedAt;
  final String? note;

  const BloodTestModel({
    required this.id,
    required this.patientId,
    required this.fileName,
    required this.pdfBase64,
    required this.uploadedByRole,
    required this.uploadedAt,
    this.note,
  });
}
