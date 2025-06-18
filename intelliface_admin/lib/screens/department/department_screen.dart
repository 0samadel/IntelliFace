// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/department/department_screen.dart
// Purpose: A screen that is now fully themed by its parent context.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/department_service.dart';
import '../../services/location_service.dart';
import '../dashboard/dashboard_layout.dart';
import 'widgets/department_data_table.dart';
import 'widgets/department_form_dialog.dart';
import 'widgets/department_list_header.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});
  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  // All state and logic methods remain the same.
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _availableLocations = [];
  bool _isLoadingPage = true;
  bool _isLoadingLocationsForForm = false;
  final Set<String> _deletingDepartmentIds = {};
  int _currentPage = 0;
  final int _rowsPerPage = 7;
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _fetchAllData(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _fetchAllData() async { await Future.wait([_fetchDepartments(), _fetchAvailableLocations()]); }

  Future<void> _fetchDepartments() async {
    if (!mounted) return;
    setState(() => _isLoadingPage = true);
    try {
      final fetchedData = await DepartmentService.fetchDepartments();
      if (mounted) setState(() => _departments = fetchedData);
    } catch (e) {
      _showSnackBar("Fetch departments error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  Future<void> _fetchAvailableLocations() async {
    if (!mounted) return;
    setState(() => _isLoadingLocationsForForm = true);
    try {
      final fetchedLocations = await LocationService.fetchLocations();
      if (mounted) setState(() => _availableLocations = fetchedLocations);
    } catch (e) {
      _showSnackBar("Error fetching locations: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocationsForForm = false);
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

  List<Map<String, dynamic>> get _filteredDepartmentsData {
    if (_searchQuery.isEmpty) return _departments;
    final lower = _searchQuery.toLowerCase();
    return _departments.where((dep) => (dep['name']?.toString().toLowerCase().contains(lower) ?? false) || (dep['location']?['name']?.toString().toLowerCase().contains(lower) ?? false)).toList();
  }

  List<Map<String, dynamic>> get _paginatedDepartments {
    final filtered = _filteredDepartmentsData;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _openDepartmentForm([Map<String, dynamic>? department]) async {
    if (_availableLocations.isEmpty && !_isLoadingLocationsForForm) {
      await _fetchAvailableLocations();
    }
    if (!mounted) return;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => DepartmentFormDialog(
        editingDepartment: department,
        availableLocations: _availableLocations,
        isLoadingLocations: _isLoadingLocationsForForm,
      ),
    );
    if (result == true) _fetchDepartments();
  }

  void _confirmDelete(Map<String, dynamic> depToDelete) {
    final theme = Theme.of(context);
    final String departmentId = depToDelete['_id'] as String;
    final String departmentName = depToDelete['name'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Delete', style: theme.textTheme.titleLarge),
        content: Text('Are you sure you want to delete department "$departmentName"?', style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              setState(() => _deletingDepartmentIds.add(departmentId));
              try {
                await DepartmentService.deleteDepartment(departmentId);
                _showSnackBar('Department "$departmentName" deleted successfully.');
                _fetchDepartments();
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              } finally {
                if (mounted) setState(() => _deletingDepartmentIds.remove(departmentId));
              }
            },
            child: const Text('Delete'),
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
            Text("Department Management", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Organize and manage company departments.", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 24),
            Expanded(
              child: Card( // THEME-AWARE: Using Card widget which respects CardTheme
                elevation: theme.brightness == Brightness.light ? 2 : 0, // Optional: conditional elevation
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      DepartmentListHeader(
                        searchController: _searchController,
                        onAddDepartment: () => _openDepartmentForm(),
                        onSearchChanged: (value) => setState(() { _searchQuery = value; _currentPage = 0; }),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoadingPage
                            ? Center(child: CircularProgressIndicator())
                            : DepartmentDataTable(
                          paginatedDepartments: _paginatedDepartments,
                          currentPage: _currentPage, rowsPerPage: _rowsPerPage,
                          deletingDepartmentIds: _deletingDepartmentIds,
                          onEdit: (dep) => _openDepartmentForm(dep),
                          onDelete: _confirmDelete,
                        ),
                      ),
                      if (!_isLoadingPage && _filteredDepartmentsData.isNotEmpty)
                        _buildPaginationControls(theme),
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
    int totalPages = (_filteredDepartmentsData.length / _rowsPerPage).ceil();
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
            icon: Icon(LucideIcons.chevronRight, color: (_currentPage + 1) * _rowsPerPage < _filteredDepartmentsData.length ? theme.textTheme.bodyLarge?.color : theme.disabledColor),
            onPressed: (_currentPage + 1) * _rowsPerPage < _filteredDepartmentsData.length ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}