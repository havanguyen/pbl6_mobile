enum DateRangeType {
  mtd,
  ytd;

  String toJson() => name;
  static DateRangeType fromJson(String json) =>
      values.firstWhere((e) => e.name == json, orElse: () => DateRangeType.mtd);
}

class ReviewAnalysis {
  final String id;
  final String doctorId;
  final DateRangeType dateRange;
  final bool includeNonPublic;
  final double period1Total;
  final double period1Avg;
  final double period2Total;
  final double period2Avg;
  final double totalChange;
  final double avgChange;
  final String summary; // HTML
  final String advantages; // HTML
  final String disadvantages; // HTML
  final String changes; // HTML
  final String recommendations; // HTML
  final String createdBy;
  final String createdAt;

  ReviewAnalysis({
    required this.id,
    required this.doctorId,
    required this.dateRange,
    required this.includeNonPublic,
    required this.period1Total,
    required this.period1Avg,
    required this.period2Total,
    required this.period2Avg,
    required this.totalChange,
    required this.avgChange,
    required this.summary,
    required this.advantages,
    required this.disadvantages,
    required this.changes,
    required this.recommendations,
    required this.createdBy,
    required this.createdAt,
  });

  factory ReviewAnalysis.fromJson(Map<String, dynamic> json) {
    return ReviewAnalysis(
      id: json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      dateRange: DateRangeType.fromJson(json['dateRange'] as String? ?? 'mtd'),
      includeNonPublic: json['includeNonPublic'] as bool? ?? false,
      period1Total: (json['period1Total'] as num?)?.toDouble() ?? 0.0,
      period1Avg: (json['period1Avg'] as num?)?.toDouble() ?? 0.0,
      period2Total: (json['period2Total'] as num?)?.toDouble() ?? 0.0,
      period2Avg: (json['period2Avg'] as num?)?.toDouble() ?? 0.0,
      totalChange: (json['totalChange'] as num?)?.toDouble() ?? 0.0,
      avgChange: (json['avgChange'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] as String? ?? '',
      advantages: json['advantages'] as String? ?? '',
      disadvantages: json['disadvantages'] as String? ?? '',
      changes: json['changes'] as String? ?? '',
      recommendations: json['recommendations'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'dateRange': dateRange.toJson(),
      'includeNonPublic': includeNonPublic,
      'period1Total': period1Total,
      'period1Avg': period1Avg,
      'period2Total': period2Total,
      'period2Avg': period2Avg,
      'totalChange': totalChange,
      'avgChange': avgChange,
      'summary': summary,
      'advantages': advantages,
      'disadvantages': disadvantages,
      'changes': changes,
      'recommendations': recommendations,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}

class ReviewAnalysisListItem {
  final String id;
  final String doctorId;
  final DateRangeType dateRange;
  final bool includeNonPublic;
  final String summary; // HTML
  final String createdBy;
  final String createdAt;
  final String creatorName;

  ReviewAnalysisListItem({
    required this.id,
    required this.doctorId,
    required this.dateRange,
    required this.includeNonPublic,
    required this.summary,
    required this.createdBy,
    required this.createdAt,
    required this.creatorName,
  });

  factory ReviewAnalysisListItem.fromJson(Map<String, dynamic> json) {
    return ReviewAnalysisListItem(
      id: json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      dateRange: DateRangeType.fromJson(json['dateRange'] as String? ?? 'mtd'),
      includeNonPublic: json['includeNonPublic'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? '',
    );
  }
}

class CreateReviewAnalysisRequest {
  final String doctorId;
  final DateRangeType dateRange;
  final bool includeNonPublic;

  CreateReviewAnalysisRequest({
    required this.doctorId,
    required this.dateRange,
    this.includeNonPublic = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'dateRange': dateRange.toJson(),
      'includeNonPublic': includeNonPublic,
    };
  }
}
