// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/location/location_screen.dart
// Purpose: A screen that is now fully themed by its parent context.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/location_service.dart';
import '../dashboard/dashboard_layout.dart';
import 'widgets/location_data_table.dart';
import 'widgets/location_form_dialog.dart';
import 'widgets/location_list_header.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  // All state and logic methods remain the same.
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingPage = true;
  final Set<String> _deletingLocationIds = {};
  int _currentPage = 0;
  final int _rowsPerPage = 7;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    if (!mounted) return;
    setState(() => _isLoadingPage = true);
    try {
      final fetchedData = await LocationService.fetchLocations();
      if (mounted) setState(() => _locations = fetchedData);
    } catch (e) {
      _showSnackBar("Fetch locations error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingPage = false);
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

  List<Map<String, dynamic>> get _filteredLocationsData {
    if (_searchQuery.isEmpty) return _locations;
    final lower = _searchQuery.toLowerCase();
    return _locations.where((loc) => loc['name'].toString().toLowerCase().contains(lower)).toList();
  }

  List<Map<String, dynamic>> get _paginatedLocations {
    final filtered = _filteredLocationsData;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _openLocationForm([Map<String, dynamic>? location]) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationFormDialog(editingLocation: location),
    );
    if (result == true) _fetchLocations();
  }

  void _confirmDelete(Map<String, dynamic> locToDelete) {
    final theme = Theme.of(context);
    final String locationId = locToDelete['_id'] as String;
    final String locationName = locToDelete['name'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Delete', style: theme.textTheme.titleLarge),
        content: Text('Are you sure you want to delete location "$locationName"?', style: theme.textTheme.bodyMedium),
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
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              setState(() => _deletingLocationIds.add(locationId));
              try {
                await LocationService.deleteLocation(locationId);
                if (mounted) {
                  _showSnackBar('Location "$locationName" deleted successfully.');
                  _fetchLocations();
                }
              } catch (e) {
                if (mounted) _showSnackBar('Error: $e', isError: true);
              } finally {
                if (mounted) setState(() => _deletingLocationIds.remove(locationId));
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
            Text("Location Management", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Define and manage geographical work locations.", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: theme.brightness == Brightness.light ? 2 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      LocationListHeader(
                        searchController: _searchController,
                        onAddLocation: () => _openLocationForm(),
                        onSearchChanged: (value) => setState(() {
                          _searchQuery = value;
                          _currentPage = 0;
                        }),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoadingPage
                            ? Center(child: CircularProgressIndicator())
                            : LocationDataTable(
                          paginatedLocations: _paginatedLocations,
                          deletingLocationIds: _deletingLocationIds,
                          onEdit: (loc) => _openLocationForm(loc),
                          onDelete: _confirmDelete,
                          onAddFirstLocation: () => _openLocationForm(),
                          currentPage: _currentPage,
                          rowsPerPage: _rowsPerPage,
                          isSearchActive: _searchQuery.isNotEmpty,
                          searchQuery: _searchQuery,
                        ),
                      ),
                      if (!_isLoadingPage && _filteredLocationsData.isNotEmpty)
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
    int totalPages = (_filteredLocationsData.length / _rowsPerPage).ceil();
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
            icon: Icon(LucideIcons.chevronRight, color: (_currentPage + 1) * _rowsPerPage < _filteredLocationsData.length ? theme.textTheme.bodyLarge?.color : theme.disabledColor),
            onPressed: (_currentPage + 1) * _rowsPerPage < _filteredLocationsData.length ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}