// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String authUid;
  final String name;
  final String email;
  final String role; // 'admin' or 'technician'
  final String? profilePictureUrl;
  final String? phoneNumber;
  final String? address;
  final String? department;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.authUid,
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    this.phoneNumber,
    this.address,
    this.department,
    this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  /// Create UserModel from JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> data, {String? authUid}) {
    return UserModel(
      id: data['id'] ?? '',
      authUid: data['authUid'] ?? authUid ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'technician',
      profilePictureUrl: data['profilePictureUrl'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      department: data['department'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(data['createdAt'] as String))
              : null,
      lastLoginAt:
          data['lastLoginAt'] != null
              ? (data['lastLoginAt'] is Timestamp
                  ? (data['lastLoginAt'] as Timestamp).toDate()
                  : DateTime.parse(data['lastLoginAt'] as String))
              : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authUid': authUid,
      'name': name,
      'email': email,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'phoneNumber': phoneNumber,
      'address': address,
      'department': department,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  /// Convert to JSON with DateTime as ISO strings (for local storage)
  Map<String, dynamic> toJsonString() {
    return {
      'id': id,
      'authUid': authUid,
      'name': name,
      'email': email,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'phoneNumber': phoneNumber,
      'address': address,
      'department': department,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? authUid,
    String? name,
    String? email,
    String? role,
    String? profilePictureUrl,
    String? phoneNumber,
    String? address,
    String? department,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user is technician
  bool get isTechnician => role.toLowerCase() == 'technician';

  /// Get display name (name or email if name is empty)
  String get displayName => name.isNotEmpty ? name : email;

  /// Get user initials for avatar
  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      } else {
        return name[0].toUpperCase();
      }
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return email.isNotEmpty && name.isNotEmpty && role.isNotEmpty;
  }

  /// Get last login formatted string
  String get lastLoginFormatted {
    if (lastLoginAt == null) return 'Jamais connecté';

    final now = DateTime.now();
    final difference = now.difference(lastLoginAt!);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Get account status text
  String get statusText => isActive ? 'Actif' : 'Inactif';

  /// Get role display text
  String get roleDisplayText {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'technician':
        return 'Technicien';
      default:
        return 'Utilisateur';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.authUid == authUid;
  }

  @override
  int get hashCode => Object.hash(id, authUid);

  @override
  String toString() {
    return 'UserModel(id: $id, authUid: $authUid, name: $name, email: $email, role: $role, isActive: $isActive)';
  }
}
