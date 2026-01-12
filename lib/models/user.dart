enum UserRole { student, handler }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? enrollment; // For students: enrollment number
  final String? handlerRole; // For handlers: "Student Advisor", "HOD Coordinator", etc.
  final String? canteen; // For canteen staff: "Crispino", "Deans", etc.

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.enrollment,
    this.handlerRole,
    this.canteen,
  });
}
