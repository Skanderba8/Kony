// lib/models/technical_visit_report.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'floor.dart';

/// Comprehensive model representing a technical visit report
///
/// This model uses a floor-based organization where technical components
/// are grouped by building floor rather than by component type.
class TechnicalVisitReport {
  final String id;
  final String technicianId;
  final String technicianName;
  final DateTime date;
  final String clientName;
  final String location;
  final String projectManager;
  final List<String> technicians;
  final String accompanyingPerson;

  // Project context
  final String projectContext;

  // Floors containing all technical components
  final List<Floor> floors;

  // Conclusion
  final String conclusion;
  final int estimatedDurationDays;
  final List<String> assumptions;

  // Status tracking
  final String
  status; // 'draft', 'submitted', 'reviewed', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? lastModified;

  // ADD: Rejection support
  final String? rejectionComment;
  final DateTime? rejectedAt;

  /// Primary constructor with all required fields
  TechnicalVisitReport({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.date,
    required this.clientName,
    required this.location,
    required this.projectManager,
    required this.technicians,
    required this.accompanyingPerson,
    required this.projectContext,
    required this.floors,
    required this.conclusion,
    required this.estimatedDurationDays,
    required this.assumptions,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    this.lastModified,
    this.rejectionComment, // ADD
    this.rejectedAt, // ADD
  });

  /// Factory method to create a new draft report
  ///
  /// Initializes a report with default empty values and the specified technician info.
  /// This is used when starting a new report from scratch.
  factory TechnicalVisitReport.createDraft({
    required String technicianId,
    required String technicianName,
  }) {
    return TechnicalVisitReport(
      id: const Uuid().v4(),
      technicianId: technicianId,
      technicianName: technicianName,
      date: DateTime.now(),
      clientName: '',
      location: '',
      projectManager: '',
      technicians: [technicianName],
      accompanyingPerson: '',
      projectContext: '',
      floors: [
        Floor.create(name: 'Rez-de-chaussée'),
      ], // Initialize with ground floor
      conclusion: '',
      estimatedDurationDays: 1,
      assumptions: [],
      status: 'draft',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      rejectionComment: null, // ADD
      rejectedAt: null, // ADD
    );
  }

  /// Converts the report to a JSON Map for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'date': date.toIso8601String(),
      'clientName': clientName,
      'location': location,
      'projectManager': projectManager,
      'technicians': technicians,
      'accompanyingPerson': accompanyingPerson,
      'projectContext': projectContext,
      'floors': floors.map((floor) => floor.toJson()).toList(),
      'conclusion': conclusion,
      'estimatedDurationDays': estimatedDurationDays,
      'assumptions': assumptions,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'lastModified':
          lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'rejectionComment': rejectionComment, // ADD
      'rejectedAt': rejectedAt?.toIso8601String(), // ADD
    };
  }

  /// Creates a TechnicalVisitReport instance from a Firestore document
  factory TechnicalVisitReport.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime values from different sources
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    // Helper function for nullable DateTime fields
    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      return parseDateTime(value);
    }

    // Parse floors
    List<Floor> parseFloors(dynamic value) {
      if (value == null) return [Floor.create(name: 'Rez-de-chaussée')];
      if (value is List) {
        final floors =
            value
                .whereType<Map<String, dynamic>>()
                .map((item) => Floor.fromJson(item))
                .toList();
        return floors.isEmpty
            ? [Floor.create(name: 'Rez-de-chaussée')]
            : floors;
      }
      return [Floor.create(name: 'Rez-de-chaussée')];
    }

    return TechnicalVisitReport(
      id: json['id'] as String? ?? const Uuid().v4(),
      technicianId: json['technicianId'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? '',
      date: parseDateTime(json['date']),
      clientName: json['clientName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      projectManager: json['projectManager'] as String? ?? '',
      technicians:
          (json['technicians'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      accompanyingPerson: json['accompanyingPerson'] as String? ?? '',
      projectContext: json['projectContext'] as String? ?? '',
      floors: parseFloors(json['floors']),
      conclusion: json['conclusion'] as String? ?? '',
      estimatedDurationDays: json['estimatedDurationDays'] as int? ?? 1,
      assumptions:
          (json['assumptions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'draft',
      createdAt: parseDateTime(json['createdAt']),
      submittedAt: parseNullableDateTime(json['submittedAt']),
      lastModified: parseNullableDateTime(json['lastModified']),
      rejectionComment: json['rejectionComment'] as String?, // ADD
      rejectedAt: parseNullableDateTime(json['rejectedAt']),
    );
  }

  /// Creates a copy of this report with specified fields updated
  TechnicalVisitReport copyWith({
    String? id,
    String? technicianId,
    String? technicianName,
    DateTime? date,
    String? clientName,
    String? location,
    String? projectManager,
    List<String>? technicians,
    String? accompanyingPerson,
    String? projectContext,
    List<Floor>? floors,
    String? conclusion,
    int? estimatedDurationDays,
    List<String>? assumptions,
    String? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? lastModified,
    String? rejectionComment, // ADD
    DateTime? rejectedAt, // ADD
  }) {
    return TechnicalVisitReport(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      date: date ?? this.date,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      projectManager: projectManager ?? this.projectManager,
      technicians: technicians ?? this.technicians,
      accompanyingPerson: accompanyingPerson ?? this.accompanyingPerson,
      projectContext: projectContext ?? this.projectContext,
      floors: floors ?? this.floors,
      conclusion: conclusion ?? this.conclusion,
      estimatedDurationDays:
          estimatedDurationDays ?? this.estimatedDurationDays,
      assumptions: assumptions ?? this.assumptions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      lastModified: DateTime.now(),
      rejectionComment: rejectionComment ?? this.rejectionComment, // ADD
      rejectedAt: rejectedAt ?? this.rejectedAt, // ADD
    );
  }

  /// Changes the report status to 'submitted' and records submission time
  TechnicalVisitReport submit() {
    return copyWith(status: 'submitted', submittedAt: DateTime.now());
  }

  /// Validates if the report has all required fields filled for submission
  bool isValid() {
    // Basic validation of essential fields
    if (clientName.isEmpty ||
        location.isEmpty ||
        projectManager.isEmpty ||
        technicians.isEmpty ||
        projectContext.isEmpty ||
        conclusion.isEmpty) {
      // Ensure conclusion is included in validation
      return false;
    }

    // Check for at least one floor with components
    if (floors.isEmpty || !floors.any((floor) => floor.hasComponents)) {
      return false;
    }

    return true;
  }

  /// Equality comparison based on id and last modification time
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TechnicalVisitReport &&
        other.id == id &&
        other.lastModified == lastModified;
  }

  @override
  int get hashCode => Object.hash(id, lastModified);
}
