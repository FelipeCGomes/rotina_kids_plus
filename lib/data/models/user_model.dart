class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'parent' ou 'child'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });
}
