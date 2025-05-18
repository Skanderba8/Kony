// lib/models/statistics/report_stats.dart
class ReportStats {
  int total;
  int draft;
  int submitted;
  int reviewed;
  int approved;
  double averageDuration;
  int totalComponents;

  ReportStats({
    required this.total,
    required this.draft,
    required this.submitted,
    required this.reviewed,
    required this.approved,
    required this.averageDuration,
    required this.totalComponents,
  });

  // Copy with method for immutability
  ReportStats copyWith({
    int? total,
    int? draft,
    int? submitted,
    int? reviewed,
    int? approved,
    double? averageDuration,
    int? totalComponents,
  }) {
    return ReportStats(
      total: total ?? this.total,
      draft: draft ?? this.draft,
      submitted: submitted ?? this.submitted,
      reviewed: reviewed ?? this.reviewed,
      approved: approved ?? this.approved,
      averageDuration: averageDuration ?? this.averageDuration,
      totalComponents: totalComponents ?? this.totalComponents,
    );
  }

  // Convert to Map for serialization
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'draft': draft,
      'submitted': submitted,
      'reviewed': reviewed,
      'approved': approved,
      'averageDuration': averageDuration,
      'totalComponents': totalComponents,
    };
  }

  // Create from Map for deserialization
  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      total: json['total'] as int? ?? 0,
      draft: json['draft'] as int? ?? 0,
      submitted: json['submitted'] as int? ?? 0,
      reviewed: json['reviewed'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      averageDuration: json['averageDuration'] as double? ?? 0.0,
      totalComponents: json['totalComponents'] as int? ?? 0,
    );
  }
}
