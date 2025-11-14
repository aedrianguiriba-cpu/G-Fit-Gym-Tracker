class User {
  final String id;
  final String email;
  final String name;
  final String password;
  final DateTime joinDate;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.joinDate,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      password: json['password'],
      joinDate: DateTime.parse(json['joinDate']),
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'joinDate': joinDate.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
}
