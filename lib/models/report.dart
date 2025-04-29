import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String technicianId;
  final String technicianName;
  final String interventionTypeId;
  final String interventionTitle;
  final String description;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'approved'

  Report({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.interventionTypeId,
    required this.interventionTitle,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'interventionTypeId': interventionTypeId,
      'interventionTitle': interventionTitle,
      'description': description,
      'createdAt':
          createdAt.toIso8601String(), // Store as ISO string for consistency
      'status': status.toLowerCase(), // Ensure status is always lowercase
    };
  }

  // Create Report from Firestore document
  factory Report.fromJson(Map<String, dynamic> json) {
    // Handle different timestamp formats from Firestore
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    return Report(
      id: json['id'] as String,
      technicianId: json['technicianId'] as String,
      technicianName: json['technicianName'] as String,
      interventionTypeId: json['interventionTypeId'] as String,
      interventionTitle: json['interventionTitle'] as String,
      description: json['description'] as String,
      createdAt: parseDateTime(json['createdAt']),
      status: (json['status'] as String).toLowerCase(), // Normalize status case
    );
  }
}
