// ─────────────────────────────────────────────────────────────────────────────
// File: lib/screens/location/widgets/location_form_dialog.dart
// Purpose: Fully theme-aware dialog for adding or editing a location.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/location_service.dart';

class LocationFormDialog extends StatefulWidget {
  final Map<String, dynamic>? editingLocation;
  const LocationFormDialog({super.key, this.editingLocation});

  @override
  State<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController(text: "50");
  bool _isDialogLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingLocation != null) {
      final loc = widget.editingLocation!;
      _locationNameController.text = loc['name']?.toString() ?? '';
      _latitudeController.text = loc['latitude']?.toString() ?? '';
      _longitudeController.text = loc['longitude']?.toString() ?? '';
      _radiusController.text = loc['radius']?.toString() ?? '50';
    }
  }

  @override
  void dispose() {
    _locationNameController.dispose(); _latitudeController.dispose();
    _longitudeController.dispose(); _radiusController.dispose();
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isDialogLoading = true);
      final locationData = {
        "name": _locationNameController.text.trim(),
        "latitude": double.tryParse(_latitudeController.text.trim()),
        "longitude": double.tryParse(_longitudeController.text.trim()),
        "radius": int.tryParse(_radiusController.text.trim()),
      };
      locationData.removeWhere((key, value) => value == null);
      try {
        if (widget.editingLocation != null) {
          await LocationService.updateLocation(widget.editingLocation!['_id'], locationData);
          _showSnackBar("Location updated successfully");
        } else {
          await LocationService.createLocation(locationData);
          _showSnackBar("Location added successfully");
        }
        if (mounted) Navigator.of(context).pop(true);
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
    final title = widget.editingLocation != null ? "Edit Location" : "Add New Location";

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: theme.textTheme.headlineSmall),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildFormTextField(_locationNameController, "Location Name", isRequired: true),
              const SizedBox(height: 16),
              _buildFormTextField(_latitudeController, "Latitude", isRequired: true, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
              const SizedBox(height: 16),
              _buildFormTextField(_longitudeController, "Longitude", isRequired: true, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
              const SizedBox(height: 16),
              _buildFormTextField(_radiusController, "Radius (meters)", isRequired: true, keyboardType: TextInputType.number),
            ]),
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
          label: Text(widget.editingLocation != null ? "Save Changes" : "Add Location"),
          onPressed: _isDialogLoading ? null : _submitForm,
        ),
      ],
    );
  }

  Widget _buildFormTextField(TextEditingController controller, String label, {bool isRequired = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(labelText: label + (isRequired ? "*" : "")),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) return "$label is required";
        if (keyboardType == TextInputType.number && int.tryParse(v ?? '') == null) return "Enter a valid number";
        if (keyboardType?.toString().contains('decimal') ?? false) {
          if (double.tryParse(v ?? '') == null) return "Enter a valid decimal number";
        }
        return null;
      },
    );
  }
}