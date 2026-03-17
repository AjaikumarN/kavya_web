class User {
  final int id;
  final String username;
  final String fullName;
  final List<String> roles;
  final String? phone;
  final String? email;
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.roles,
    this.phone,
    this.email,
    this.isActive = true,
  });

  String get primaryRole => roles.isNotEmpty ? roles[0] : 'driver';

  /// Backward compatibility for existing driver screens that reference `user.role`
  String get role => primaryRole;

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles;
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    } else if (json['role'] is String) {
      parsedRoles = [json['role'] as String];
    } else {
      parsedRoles = ['driver'];
    }

    return User(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] as String? ?? json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      roles: parsedRoles,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'roles': roles,
        'phone': phone,
        'email': email,
        'is_active': isActive,
      };
}
