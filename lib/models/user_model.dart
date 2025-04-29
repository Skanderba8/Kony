// lib/models/user_model.dart
class UserModel {
  final String id;
  final String authUid;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    this.authUid = '',
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authUid': authUid,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      authUid: map['authUid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'technician',
    );
  }

  UserModel copyWith({String? name, String? email, String? role}) {
    return UserModel(
      id: id,
      authUid: authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}
