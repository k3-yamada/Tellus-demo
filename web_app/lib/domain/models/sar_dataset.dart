class SarDatasetEntry {
  const SarDatasetEntry({
    required this.id,
    required this.name,
    this.description,
    this.observationCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final int observationCount;

  factory SarDatasetEntry.fromJson(Map<String, dynamic> json) {
    return SarDatasetEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
      description: json['description'] as String?,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
    );
  }
}
