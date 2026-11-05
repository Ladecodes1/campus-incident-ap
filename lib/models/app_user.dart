class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student' or 'staff'

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isStaff => role == 'staff';

  // Turns this user into a map so we can save it in Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
    };
  }

  // Builds a user from a Firestore document
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
    );
  }
}