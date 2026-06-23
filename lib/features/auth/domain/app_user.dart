class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
    this.phone,
    this.subscriptionPlan,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String token;
  final String? phone;
  final String? subscriptionPlan;

  bool get isAdmin => role.toLowerCase() == 'admin';

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? token,
    String? phone,
    String? subscriptionPlan,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      token: token ?? this.token,
      phone: phone ?? this.phone,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Belumi User',
      phone: json['phone']?.toString(),
      role: _roleFromJson(json['role']),
      token: json['token']?.toString() ?? '',
      subscriptionPlan: json['subscriptionPlan']?.toString() ?? json['subscription_plan']?.toString(),
    );
  }

  static String _roleFromJson(Object? value) {
    if (value is String) return value;
    if (value is num) return value == 1 ? 'Admin' : 'Customer';
    return 'Customer';
  }
}
