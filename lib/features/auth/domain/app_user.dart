class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
    this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String token;
  final String? phone;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Belumi User',
      phone: json['phone']?.toString(),
      role: _roleFromJson(json['role']),
      token: json['token']?.toString() ?? '',
    );
  }

  static String _roleFromJson(Object? value) {
    if (value is String) return value;
    if (value is num) return value == 1 ? 'Admin' : 'Customer';
    return 'Customer';
  }
}
