// ─────────────────────────────────────────────────────────────────────────────
// File    : models/user_model.dart
// Purpose : Defines the data structures for User and nested Department objects.
// ─────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * Department Model
 * ========================================================================== */

/// A simple model for a department, often nested within a [User].
class Department {
  final String? id;
  final String? name;

  Department({this.id, this.name});

  /// Creates a [Department] instance from a JSON map.
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] as String?,
      name: json['name'] as String?,
    );
  }
}

/* ============================================================================
 * User Model
 * ========================================================================== */

class User {
  /* ----------------------------------------------------------------------------
   * 1. Properties
   * -------------------------------------------------------------------------- */

  final String id; // NOTE: Corresponds to _id from MongoDB
  final String? employeeId;
  final String fullName;
  final String? phone;
  final String email;
  final String username;
  final String? address;
  final String role;
  final Department? department; // Nested object
  final String? profilePicture;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /* ----------------------------------------------------------------------------
   * 2. Constructor
   * -------------------------------------------------------------------------- */

  User({
    required this.id,
    this.employeeId,
    required this.fullName,
    this.phone,
    required this.email,
    required this.username,
    this.address,
    required this.role,
    this.department,
    this.profilePicture,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /* ----------------------------------------------------------------------------
   * 3. Deserialization (from JSON)
   * -------------------------------------------------------------------------- */

  /// Creates a [User] instance from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      employeeId: json['employeeId'] as String?,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      username: json['username'] as String,
      address: json['address'] as String?,
      role: json['role'] as String,
      department: json['department'] != null
          ? Department.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      profilePicture: json['profilePicture'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /* ----------------------------------------------------------------------------
   * 4. Computed Properties
   * -------------------------------------------------------------------------- */

  /// Constructs the full profile picture URL from a relative path.
  String? get fullProfilePictureUrl {
    if (profilePicture == null) return null;
    if (profilePicture!.startsWith('http')) return profilePicture;

    // NOTE: This logic requires a `serverBaseUrl` in ApiConstants
    // that points to the server root (e.g., "http://localhost:5100").
    // return "${ApiConstants.serverBaseUrl}/$profilePicture";

    return null; // Adjust this based on your final implementation.
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */