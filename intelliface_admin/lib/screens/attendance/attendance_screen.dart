// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/attendance/attendance_screen.dart
// Purpose: A screen that is now fully themed by its parent context.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:lucide_icons/lucide_icons.dart';

import '../dashboard/dashboard_layout.dart';
import '../../services/attendance_service.dart';
import 'widgets/attendance_filter_controls.dart';
import 'widgets/attendance_data_table.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // All state and logic methods remain the same.
  DateTime selectedDate = DateTime.now();
  String selectedStatusFilter = 'All';
  List<Map<String, dynamic>> _allFetchedAttendanceRecords = [];
  bool _isLoading = true;
  final Set<String> _deletingRecordIds = {};
  int _currentPage = 0;
  final int _rowsPerPage = 7;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final records = await AttendanceService.fetchAllAttendanceRecords();
      if (mounted) setState(() => _allFetchedAttendanceRecords = records);
    } catch (e) {
      if (mounted) _showSnackBar("Error fetching attendance: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _parseApiDateTime(String? dateString) {
    if (dateString == null) return null;
    return DateTime.tryParse(dateString)?.toLocal();
  }

  List<Map<String, dynamic>> get _filteredData {
    return _allFetchedAttendanceRecords.where((record) {
      final checkInDateTime = _parseApiDateTime(record['checkInTime'] as String?);
      if (checkInDateTime == null) return false;
      final isSameDate = DateUtils.isSameDay(checkInDateTime, selectedDate);
      if (!isSameDate) return false;
      final recordStatus = record['status']?.toString() ?? 'N/A';
      if (selectedStatusFilter == 'All') return true;
      return recordStatus == selectedStatusFilter;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedData {
    final filtered = _filteredData;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
    ));
  }

  void _pickDate() async {
    final theme = Theme.of(context);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          // Pass the current theme to the date picker
          data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                onPrimary: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              )
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      if (mounted) setState(() { selectedDate = picked; _currentPage = 0; });
    }
  }

  void _exportToHtml() {
    final dataToExport = _filteredData;
    if (dataToExport.isEmpty) {
      _showSnackBar("No data to export for the selected criteria.", isError: true);
      return;
    }
    String htmlContent = '''
    <!DOCTYPE html><html><head><meta charset="utf-8"><title>Attendance Report - ${DateFormat.yMMMMd().format(selectedDate)}</title><style>body { font-family: 'Inter', sans-serif; margin: 20px; background-color: #121212; color: #EAEAEA; } table { border-collapse: collapse; width: 100%; margin-top: 20px; border: 1px solid #333; } th, td { border: 1px solid #333; padding: 12px; text-align: left; font-size: 14px;} th { background-color: #1E1E1E; font-weight: 600;} h2, h3 { color: #EAEAEA; } .status-Present { color: #28A745; font-weight: bold; } .status-Late { color: #FFC107; font-weight: bold; }</style></head><body><h2>Attendance Report - ${DateFormat.yMMMMd().format(selectedDate)}</h2><h3>Status Filter: $selectedStatusFilter</h3><table><tr><th>#</th><th>Employee ID</th><th>Employee Name</th><th>Check-In</th><th>Check-Out</th><th>Status</th></tr>''';
    for (int i = 0; i < dataToExport.length; i++) {
      final record = dataToExport[i];
      final user = record['userId'] as Map<String, dynamic>?;
      final employeeId = user?['username']?.toString() ?? user?['_id']?.toString() ?? 'N/A';
      final employeeName = user?['fullName']?.toString() ?? 'N/A';
      final checkInTime = DateFormat.jm().format(_parseApiDateTime(record['checkInTime'] as String?)!);
      final checkOutTime = record['checkOutTime'] != null ? DateFormat.jm().format(_parseApiDateTime(record['checkOutTime'] as String?)!) : '–';
      final status = record['status']?.toString() ?? 'N/A';
      htmlContent += '<tr><td>${i + 1}</td><td>$employeeId</td><td>$employeeName</td><td>$checkInTime</td><td>$checkOutTime</td><td class="status-$status">$status</td></tr>';
    }
    htmlContent += '</table></body></html>';
    final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..setAttribute("download", "attendance_report_${DateFormat('yyyy-MM-dd').format(selectedDate)}.html")..click();
    html.Url.revokeObjectUrl(url);
    _showSnackBar("Attendance report exported successfully.");
  }

  void _confirmDeleteAttendance(Map<String, dynamic> recordToDelete) async {
    final theme = Theme.of(context);
    final String recordId = recordToDelete['_id'] as String;
    final userName = recordToDelete['userId']?['fullName']?.toString() ?? 'Employee';
    final checkInDate = DateFormat.yMMMd().format(_parseApiDateTime(recordToDelete['checkInTime'] as String?)!);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Delete', style: theme.textTheme.titleLarge),
        content: Text('Delete attendance for $userName on $checkInDate?', style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              if (!mounted) return;
              setState(() => _deletingRecordIds.add(recordId));
              try {
                await AttendanceService.deleteAttendanceRecord(recordId);
                if (mounted) {
                  _showSnackBar('Attendance record deleted successfully.');
                  _fetchAttendanceData();
                }
              } catch (e) {
                if (mounted) _showSnackBar('Failed to delete record: $e', isError: true);
              } finally {
                if (mounted) setState(() => _deletingRecordIds.remove(recordId));
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
            Text("Attendance Records", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("View and manage employee attendance logs.", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: theme.brightness == Brightness.light ? 2 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      AttendanceFilterControls(
                        selectedDate: selectedDate,
                        selectedStatusFilter: selectedStatusFilter,
                        onPickDate: _pickDate,
                        onExport: _exportToHtml,
                        onStatusChanged: (value) {
                          if (value != null && mounted) setState(() { selectedStatusFilter = value; _currentPage = 0; });
                        },
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : AttendanceDataTable(
                          records: _paginatedData,
                          deletingRecordIds: _deletingRecordIds,
                          onDelete: _confirmDeleteAttendance,
                          selectedDate: selectedDate,
                          selectedStatusFilter: selectedStatusFilter,
                          currentPage: _currentPage,
                          rowsPerPage: _rowsPerPage,
                        ),
                      ),
                      if (!_isLoading && _filteredData.isNotEmpty) _buildPaginationControls(theme),
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
    int totalPages = (_filteredData.length / _rowsPerPage).ceil();
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
            icon: Icon(LucideIcons.chevronRight, color: (_currentPage + 1) * _rowsPerPage < _filteredData.length ? theme.textTheme.bodyLarge?.color : theme.disabledColor),
            onPressed: (_currentPage + 1) * _rowsPerPage < _filteredData.length ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}