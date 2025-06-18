// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/employee/widgets/employee_form_dialog.dart
// Purpose: A professional, theme-aware dialog for adding or editing an employee,
//          featuring a responsive two-column layout.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/user_service.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? editingEmployee;
  final List<Map<String, dynamic>> availableDepartments;
  final bool isLoadingDepts;

  const EmployeeFormDialog({
    super.key,
    this.editingEmployee,
    required this.availableDepartments,
    this.isLoadingDepts = false,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedDepartmentId;
  bool _isDialogLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingEmployee != null) {
      final emp = widget.editingEmployee!;
      _nameController.text = emp['fullName']?.toString() ?? '';
      _phoneController.text = emp['phone']?.toString() ?? '';
      _emailController.text = emp['email']?.toString() ?? '';
      _usernameController.text = emp['username']?.toString() ?? '';
      final dept = emp['department'];
      _selectedDepartmentId = dept is Map ? dept['_id']?.toString() : dept?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose(); _emailController.dispose();
    _usernameController.dispose(); _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? theme.colorScheme.error : Colors.green),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      _showSnackBar("Please select a department.", isError: true);
      return;
    }
    setState(() => _isDialogLoading = true);
    final employeeData = {
      "fullName": _nameController.text, "phone": _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      "email": _emailController.text.trim(), "username": _usernameController.text.trim(),
      "department": _selectedDepartmentId,
    };
    if (widget.editingEmployee == null) {
      if (_passwordController.text.isEmpty) {
        _showSnackBar("Password is required for new employee.", isError: true);
        setState(() => _isDialogLoading = false);
        return;
      }
      employeeData['password'] = _passwordController.text;
    } else if (_passwordController.text.isNotEmpty) {
      employeeData['password'] = _passwordController.text;
    }
    try {
      if (widget.editingEmployee != null) {
        await UserService.updateEmployee(widget.editingEmployee!['_id'], employeeData);
        _showSnackBar("Employee updated successfully");
      } else {
        await UserService.createEmployee(employeeData);
        _showSnackBar("Employee added successfully");
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showSnackBar("$e", isError: true);
    } finally {
      if (mounted) setState(() => _isDialogLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.editingEmployee != null;
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(isEditing ? "Edit Employee Details" : "Add New Employee", style: theme.textTheme.headlineSmall),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5, // Wider dialog for two columns
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Two-Column Layout ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormTextField(_nameController, "Full Name", isRequired: true),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormTextField(_usernameController, "Username", isRequired: true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormTextField(
                        _emailController, "Email",
                        isRequired: true, keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Email is required";
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(v)) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormTextField(
                        _passwordController, isEditing ? "New Password (optional)" : "Password*",
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (v) {
                          if (!isEditing && (v == null || v.isEmpty)) return "Password is required";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormTextField(_phoneController, "Phone Number", keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildDepartmentDropdown(theme),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDialogLoading ? null : () => Navigator.of(context).pop(false),
          child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
        ),
        ElevatedButton.icon(
          icon: _isDialogLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.check, size: 18),
          label: Text(isEditing ? "Save Changes" : "Add Employee"),
          onPressed: _isDialogLoading ? null : _submitForm,
        ),
      ],
    );
  }

  Widget _buildFormTextField(
      TextEditingController controller,
      String label, {
        bool isRequired = false,
        bool obscureText = false,
        TextInputType? keyboardType,
        Widget? suffixIcon,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller, obscureText: obscureText, keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
      validator: validator ?? (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) return "$label is required";
        return null;
      },
    );
  }

  Widget _buildDepartmentDropdown(ThemeData theme) {
    if (widget.isLoadingDepts) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }
    return DropdownButtonFormField<String>(
      value: _selectedDepartmentId,
      items: widget.availableDepartments.map((dept) => DropdownMenuItem<String>(value: dept['_id'] as String, child: Text(dept['name'] as String))).toList(),
      onChanged: _isDialogLoading ? null : (value) => setState(() => _selectedDepartmentId = value),
      decoration: const InputDecoration(labelText: "Department*"),
      dropdownColor: theme.colorScheme.surface,
      style: theme.textTheme.bodyMedium,
      validator: (value) => value == null ? "Please select a department" : null,
    );
  }
}