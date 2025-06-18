// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/department/widgets/department_form_dialog.dart
// Purpose: Fully theme-aware dialog for adding or editing a department.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/department_service.dart';

class DepartmentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? editingDepartment;
  final List<Map<String, dynamic>> availableLocations;
  final bool isLoadingLocations;

  const DepartmentFormDialog({
    super.key,
    this.editingDepartment,
    required this.availableLocations,
    this.isLoadingLocations = false,
  });

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedLocationId;
  bool _isDialogLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingDepartment != null) {
      final dep = widget.editingDepartment!;
      _nameController.text = dep['name']?.toString() ?? '';
      _selectedLocationId = dep['location']?['_id']?.toString() ?? dep['location']?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLocationId == null) {
        _showSnackBar("Please select a location.", isError: true);
        return;
      }
      setState(() => _isDialogLoading = true);
      final departmentData = {"name": _nameController.text.trim(), "location": _selectedLocationId};
      try {
        String successMessage;
        if (widget.editingDepartment != null) {
          final departmentId = widget.editingDepartment!['_id'] as String;
          await DepartmentService.updateDepartment(departmentId, departmentData);
          successMessage = "Department updated successfully";
        } else {
          await DepartmentService.createDepartment(departmentData);
          successMessage = "Department added successfully";
        }
        if (mounted) {
          _showSnackBar(successMessage);
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) _showSnackBar("Error: $e", isError: true);
      } finally {
        if (mounted) setState(() => _isDialogLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.editingDepartment != null ? "Edit Department" : "Add New Department";

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: theme.textTheme.headlineSmall),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(labelText: "Department Name*"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "This field is required" : null,
              ),
              const SizedBox(height: 16),
              _buildLocationDropdown(theme),
            ],
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
          label: Text(widget.editingDepartment != null ? "Save Changes" : "Add Department"),
          onPressed: _isDialogLoading ? null : _submitForm,
        ),
      ],
    );
  }

  Widget _buildLocationDropdown(ThemeData theme) {
    if (widget.isLoadingLocations) {
      return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }
    return DropdownButtonFormField<String>(
      value: _selectedLocationId,
      items: widget.availableLocations.map((loc) {
        return DropdownMenuItem<String>(
          value: loc['_id'] as String,
          child: Text(loc['name'] as String),
        );
      }).toList(),
      onChanged: _isDialogLoading ? null : (value) => setState(() => _selectedLocationId = value),
      decoration: const InputDecoration(labelText: "Location*"),
      dropdownColor: theme.colorScheme.surface,
      style: theme.textTheme.bodyMedium,
      validator: (value) => value == null ? "Please select a location" : null,
    );
  }
}