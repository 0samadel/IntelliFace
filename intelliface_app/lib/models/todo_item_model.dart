// ─────────────────────────────────────────────────────────────────────────────
// File    : models/todo_item_model.dart
// Purpose : Defines the data structure for a TodoItem.
// ─────────────────────────────────────────────────────────────────────────────

class TodoItem {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  final String id; // NOTE: Corresponds to _id from MongoDB
  String title;
  String? description;
  DateTime? dueDate;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;

  /* ============================================================================
   * 2. Constructor
   * ========================================================================== */

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /* ============================================================================
   * 3. Deserialization (from JSON)
   * ========================================================================== */

  /// Creates a [TodoItem] instance from a JSON map.
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /* ============================================================================
   * 4. Serialization (to JSON)
   * ========================================================================== */

  /// Converts the instance to a JSON map suitable for update operations.
  Map<String, dynamic> toJsonForUpdate() {
    final Map<String, dynamic> data = {};
    data['title'] = title;
    if (description != null) data['description'] = description;
    if (dueDate != null) data['dueDate'] = dueDate!.toIso8601String(); else data['dueDate'] = null;
    data['isCompleted'] = isCompleted;
    return data;
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */