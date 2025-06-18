// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/employee/widgets/face_enroll_dialog.dart
// Purpose: A professional, theme-aware face enrollment dialog with enhanced UI/UX.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart'; // A great package for dashed borders
import '../../../services/face_service.dart';

// IMPORTANT: Add this package to your pubspec.yaml and run `flutter pub get`
// dependencies:
//   dotted_border: ^2.1.0

class FaceEnrollDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  const FaceEnrollDialog({super.key, required this.employee});
  @override
  State<FaceEnrollDialog> createState() => _FaceEnrollDialogState();
}

class _FaceEnrollDialogState extends State<FaceEnrollDialog> {
  PlatformFile? _pickedImageFile;
  bool _isFaceUploading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
    ));
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() => _pickedImageFile = result.files.first);
      }
    } catch (e) {
      _showSnackBar("Could not open file picker: $e", isError: true);
    }
  }

  Future<void> _enrollFace() async {
    if (_isFaceUploading || _pickedImageFile == null) return;

    setState(() => _isFaceUploading = true);
    try {
      await FaceService.enrollFace(widget.employee['_id'], _pickedImageFile!);
      if (mounted) {
        _showSnackBar("Face for ${widget.employee['fullName']} enrolled successfully!");
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isFaceUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Enroll Face: ${widget.employee['fullName'] ?? 'Employee'}", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            "Use a clear, frontal photo without obstructions.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // --- Pro "Dropzone" Image Preview ---
            InkWell(
              onTap: _isFaceUploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(100),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(100),
                color: theme.dividerColor,
                strokeWidth: 2,
                dashPattern: const [8, 6],
                child: Container(
                  height: 180, width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: _pickedImageFile?.bytes != null
                        ? DecorationImage(image: MemoryImage(_pickedImageFile!.bytes!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _pickedImageFile == null
                      ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.imagePlus, size: 48, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(height: 8),
                          Text("Click to upload", style: theme.textTheme.bodySmall)
                        ],
                      )
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // --- Pro Image Status ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _pickedImageFile == null
                  ? Text("No image selected", style: theme.textTheme.bodySmall)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileImage, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _pickedImageFile!.name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _isFaceUploading ? null : _pickImage,
                    child: const Text("Change"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isFaceUploading ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton.icon(
          icon: _isFaceUploading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(LucideIcons.scanFace, size: 16),
          label: const Text("Enroll Face"),
          onPressed: (_isFaceUploading || _pickedImageFile == null) ? null : _enrollFace,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ).copyWith(
            // Make the button visually disabled
            backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.withOpacity(0.5);
              }
              return Colors.green;
            }),
          ),
        ),
      ],
    );
  }
}