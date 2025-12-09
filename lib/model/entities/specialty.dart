class Specialty {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int infoSectionsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Specialty({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.infoSectionsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      infoSectionsCount: (json['infoSectionsCount'] as num?)?.toInt() ?? 0,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
      deletedAt: _dateTimeFromJson(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'infoSectionsCount': infoSectionsCount,
    'createdAt': _dateTimeToJson(createdAt),
    'updatedAt': _dateTimeToJson(updatedAt),
    'deletedAt': _dateTimeToJson(deletedAt),
  };

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _dateTimeToJson(DateTime? date) => date?.toIso8601String();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Specialty && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
