class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? householdId;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.householdId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      householdId: map['household_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      if (householdId != null) 'household_id': householdId,
    };
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? householdId,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      householdId: householdId ?? this.householdId,
    );
  }
}
