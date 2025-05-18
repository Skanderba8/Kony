// lib/models/photo.dart
import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String url;
  final String comment;
  final DateTime takenAt;

  // Local path for temporary storage before upload
  final String? localPath;

  Photo({
    required this.id,
    required this.url,
    required this.comment,
    required this.takenAt,
    this.localPath,
  });

  factory Photo.create({String? localPath, String comment = ''}) {
    return Photo(
      id: const Uuid().v4(),
      url: '',
      comment: comment,
      takenAt: DateTime.now(),
      localPath: localPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'comment': comment,
      'takenAt': takenAt.toIso8601String(),
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String? ?? const Uuid().v4(),
      url: json['url'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      takenAt:
          json['takenAt'] != null
              ? DateTime.parse(json['takenAt'] as String)
              : DateTime.now(),
    );
  }

  Photo copyWith({
    String? id,
    String? url,
    String? comment,
    DateTime? takenAt,
    String? localPath,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      comment: comment ?? this.comment,
      takenAt: takenAt ?? this.takenAt,
      localPath: localPath ?? this.localPath,
    );
  }
}
