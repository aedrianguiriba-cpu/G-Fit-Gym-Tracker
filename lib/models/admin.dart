class Admin {
  final String id;
  final String email;
  final String name;
  final String password;
  final DateTime joinDate;
  final String? avatarUrl;
  final String? phone;

  Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.joinDate,
    this.avatarUrl,
    this.phone,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      password: json['password'] ?? '',
      joinDate: DateTime.parse(json['join_date']),
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'join_date': joinDate.toIso8601String(),
      'avatar_url': avatarUrl,
      'phone': phone,
    };
  }

  Admin copyWith({
    String? id,
    String? email,
    String? name,
    String? password,
    DateTime? joinDate,
    String? avatarUrl,
    String? phone,
  }) {
    return Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      joinDate: joinDate ?? this.joinDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() => 'Admin(id: $id, name: $name, email: $email)';
}
