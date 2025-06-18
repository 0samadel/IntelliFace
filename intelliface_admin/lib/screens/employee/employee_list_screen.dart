// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/employee/employee_list_screen.dart
// Purpose: A screen that is now fully themed by its parent context.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/user_service.dart';
import '../../services/department_service.dart';
import '../dashboard/dashboard_layout.dart';
import 'widgets/employee_data_table.dart';
import 'widgets/employee_list_header.dart';
import 'widgets/employee_form_dialog.dart';
import 'widgets/face_enroll_dialog.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  // All state and logic methods remain the same.
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _availableDepartments = [];
  bool _isLoadingPage = true;
  bool _isLoadingDeptsForForm = false;
  final Set<String> _deletingEmployeeIds = {};
  int _currentPage = 0;
  final int _rowsPerPage = 6;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    await _fetchEmployees();
    await _fetchAvailableDepartments();
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;
    setState(() => _isLoadingPage = true);
    try {
      final fetchedData = await UserService.fetchEmployees();
      if (mounted) setState(() => _employees = fetchedData);
    } catch (e) {
      _showSnackBar("Fetch employees error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  Future<void> _fetchAvailableDepartments() async {
    if (!mounted) return;
    setState(() => _isLoadingDeptsForForm = true);
    try {
      final fetchedDepts = await DepartmentService.fetchDepartments();
      if (mounted) setState(() => _availableDepartments = fetchedDepts);
    } catch (e) {
      _showSnackBar("Error fetching departments: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingDeptsForForm = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
    ));
  }

  List<Map<String, dynamic>> get _filteredEmployeesData {
    if (_searchQuery.isEmpty) return _employees;
    final lower = _searchQuery.toLowerCase();
    return _employees.where((emp) =>
    (emp['fullName']?.toString().toLowerCase().contains(lower) ?? false) ||
        (emp['email']?.toString().toLowerCase().contains(lower) ?? false) ||
        (emp['username']?.toString().toLowerCase().contains(lower) ?? false) ||
        (emp['employeeId']?.toString().toLowerCase().contains(lower) ?? false) ||
        (emp['department']?['name']?.toString().toLowerCase().contains(lower) ?? false) ||
        (emp['phone']?.toString().toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  List<Map<String, dynamic>> get _paginatedEmployees {
    final filtered = _filteredEmployeesData;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _startAddOrEditEmployee([Map<String, dynamic>? employee]) async {
    if (_availableDepartments.isEmpty && !_isLoadingDeptsForForm) {
      await _fetchAvailableDepartments();
    }
    if (!mounted) return;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => EmployeeFormDialog(
        editingEmployee: employee,
        availableDepartments: _availableDepartments,
        isLoadingDepts: _isLoadingDeptsForForm,
      ),
    );
    if (result == true) _fetchEmployees();
  }

  void _openFaceUploadDialog(Map<String, dynamic> emp) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (_) => FaceEnrollDialog(employee: emp),
    );
    if (result == true) _fetchEmployees();
  }

  void _confirmDelete(Map<String, dynamic> empToDelete) {
    final theme = Theme.of(context);
    final String employeeDbId = empToDelete['_id'] as String;
    final String employeeName = empToDelete['fullName'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Delete', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to delete "$employeeName"? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete Employee'),
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              if (!mounted) return;
              setState(() => _deletingEmployeeIds.add(employeeDbId));
              try {
                await UserService.deleteEmployee(employeeDbId);
                _showSnackBar('Employee "$employeeName" deleted successfully.');
              } catch (e) {
                _showSnackBar('$e', isError: true);
              } finally {
                if (mounted) {
                  await _fetchEmployees();
                  setState(() => _deletingEmployeeIds.remove(employeeDbId));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardLayout(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Employee Management", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Add, edit, or remove employee details and enroll faces.", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: theme.brightness == Brightness.light ? 2 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      EmployeeListHeader(
                        searchController: _searchController,
                        onAddEmployee: () => _startAddOrEditEmployee(),
                        onSearchChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoadingPage
                            ? Center(child: CircularProgressIndicator())
                            : EmployeeDataTable(
                          paginatedEmployees: _paginatedEmployees,
                          currentPage: _currentPage,
                          rowsPerPage: _rowsPerPage,
                          deletingEmployeeIds: _deletingEmployeeIds,
                          onEdit: (emp) => _startAddOrEditEmployee(emp),
                          onDelete: _confirmDelete,
                          onEnrollFace: _openFaceUploadDialog,
                        ),
                      ),
                      if (!_isLoadingPage && _filteredEmployeesData.isNotEmpty) _buildPaginationControls(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(ThemeData theme) {
    int totalPages = (_filteredEmployeesData.length / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Page ${_currentPage + 1} of $totalPages", style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: _currentPage > 0 ? theme.textTheme.bodyLarge?.color : theme.disabledColor),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(LucideIcons.chevronRight, color: (_currentPage + 1) * _rowsPerPage < _filteredEmployeesData.length ? theme.textTheme.bodyLarge?.color : theme.disabledColor),
            onPressed: (_currentPage + 1) * _rowsPerPage < _filteredEmployeesData.length ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}