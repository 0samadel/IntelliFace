// ─────────────────────────────────────────────────────────────────────────────
// File    : models/employee.dart
// Purpose : Defines the data structure for an Employee object.
// ─────────────────────────────────────────────────────────────────────────────

class Employee {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  final int id;
  final String name;
  final String surname;
  final String phoneNumber;
  final String email;
  final bool isAdmin;

  /* ============================================================================
   * 2. Constructor
   * ========================================================================== */

  Employee({
    required this.id,
    required this.name,
    required this.surname,
    required this.phoneNumber,
    required this.email,
    required this.isAdmin,
  });

  /* ============================================================================
   * 3. JSON Serialization
   * ========================================================================== */

  /// Creates an [Employee] instance from a JSON map.
  /// NOTE: Designed to handle the backend's `ReadDto<EmployeeDto>` wrapper.
  factory Employee.fromJson(Map<String, dynamic> json) {
    // This logic handles two common API response shapes:
    // 1. A direct list item:   { "id": 1, "data": { ... } }
    // 2. A nested single item: { "data": { "id": 1, ... } }
    return Employee(
      id: json['id'] ?? json['data']['id'] ?? 0,
      name: json['data']['name'] ?? '',
      surname: json['data']['surname'] ?? '',
      phoneNumber: json['data']['phoneNumber'] ?? '',
      email: json['data']['email'] ?? '',
      isAdmin: json['data']['isAdmin'] ?? false,
    );
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */