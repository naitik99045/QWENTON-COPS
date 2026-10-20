/// Represents an authenticated seller user in the Qwenton CommerceOps app
class AuthUser {
  final String id;
  final String phoneNumber;
  final String? email;
  final bool isMock;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.isMock = false,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phoneNumber: json['phone'] as String? ?? json['phone_number'] as String? ?? '',
      email: json['email'] as String?,
      isMock: json['is_mock'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'is_mock': isMock,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
