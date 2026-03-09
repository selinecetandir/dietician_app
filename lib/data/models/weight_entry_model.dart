class WeightEntryModel {
  final String id;
  final String patientId;
  final double weight;
  final DateTime date;
  final String? note;

  const WeightEntryModel({
    required this.id,
    required this.patientId,
    required this.weight,
    required this.date,
    this.note,
  });
}
