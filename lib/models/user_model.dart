// lib/models/user_model.dart
class UserModel {
  final String id;
  final String authUid;
  final String name;
  final String email;
  final String role;
  final String? profilePictureUrl;
  final String? phoneNumber;
  final String? address;
  final String? department;
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.id,
    this.authUid = '',
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    this.phoneNumber,
    this.address,
    this.department,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
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
      'additionalInfo': additionalInfo,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      authUid: map['authUid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'technician',
      profilePictureUrl: map['profilePictureUrl'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      department: map['department'],
      additionalInfo:
          map['additionalInfo'] != null
              ? Map<String, dynamic>.from(map['additionalInfo'])
              : null,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? profilePictureUrl,
    String? phoneNumber,
    String? address,
    String? department,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      id: id,
      authUid: authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      department: department ?? this.department,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
