class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final String lastName;
  final DateTime birthDate;
  final String sex;
  final List<String> disorders;
  final bool isStudying;
  final String? educationLevel;
  final String avatarId;
  final int currentXp;
  final int totalXp;
  final int level;
  final String? pinCode;
  final List<String> unlockedAvatars; // <-- NOVO: Guarda os avatares comprados

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.sex,
    this.disorders = const [],
    this.isStudying = false,
    this.educationLevel,
    required this.avatarId,
    this.currentXp = 0,
    this.totalXp = 0,
    this.level = 1,
    this.pinCode,
    // Avatares básicos já vêm desbloqueados de fábrica:
    this.unlockedAvatars = const [
      'avatar_boy',
      'avatar_girl',
      'avatar_dino',
      'avatar_hero',
    ],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'sex': sex,
      'disorders': disorders,
      'isStudying': isStudying,
      'educationLevel': educationLevel,
      'avatarId': avatarId,
      'currentXp': currentXp,
      'totalXp': totalXp,
      'level': level,
      'pinCode': pinCode,
      'unlockedAvatars': unlockedAvatars, // Salva no Firebase
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChildModel(
      id: documentId,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      lastName: map['lastName'] ?? '',
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : DateTime.now(),
      sex: map['sex'] ?? 'Masculino',
      disorders: List<String>.from(map['disorders'] ?? []),
      isStudying: map['isStudying'] ?? false,
      educationLevel: map['educationLevel'],
      avatarId: map['avatarId'] ?? 'avatar_boy',
      currentXp: map['currentXp']?.toInt() ?? 0,
      totalXp: map['totalXp']?.toInt() ?? 0,
      level: map['level']?.toInt() ?? 1,
      pinCode: map['pinCode'],
      // Lê do Firebase ou dá os básicos se for um perfil antigo
      unlockedAvatars: List<String>.from(
        map['unlockedAvatars'] ??
            ['avatar_boy', 'avatar_girl', 'avatar_dino', 'avatar_hero'],
      ),
    );
  }
}
