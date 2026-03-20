class User {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final DateTime joinDate;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    required this.joinDate,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      joinDate: DateTime.parse(json['join_date']),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'join_date': joinDate.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? gender,
    DateTime? joinDate,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      joinDate: joinDate ?? this.joinDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
