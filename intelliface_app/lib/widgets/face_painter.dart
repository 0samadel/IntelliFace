// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/widgets/face_painter.dart
// Purpose : A custom painter to draw bounding boxes around detected faces.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// A [CustomPainter] that draws rectangles (bounding boxes) over a list of
/// detected faces. It is responsible for scaling the coordinates from the
/// camera image's resolution to the on-screen widget's resolution.
class FacePainter extends CustomPainter {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// A list of [Face] objects detected by the ML Kit face detection service.
  final List<Face> faces;

  /// The absolute size (resolution) of the image provided by the camera stream.
  /// This is used as the source coordinate system.
  final Size imageSize;

  /// The size of the widget (e.g., CameraPreview) on which this painter is overlaid.
  /// This is the target coordinate system.
  final Size widgetSize;

  /* ============================================================================
   * 2. Constructor
   * ========================================================================== */

  /// Constructs a [FacePainter].
  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
  });

  /* ============================================================================
   * 3. Painter Methods
   * ========================================================================== */

  @override
  void paint(Canvas canvas, Size size) { // The 'size' parameter here is the same as widgetSize.
    // Define the appearance of the bounding box (a red, 3px wide stroke).
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent;

    // Iterate through each detected face to draw its bounding box.
    for (Face face in faces) {
      // Calculate the scaling factors to convert coordinates from the image's
      // coordinate system to the widget's coordinate system.
      final double scaleX = widgetSize.width / imageSize.width;
      final double scaleY = widgetSize.height / imageSize.height;

      // Draw the rectangle on the canvas using the scaled coordinates.
      // The Rect.fromLTRB constructor creates a rectangle from the Left, Top,
      // Right, and Bottom coordinates of the face's bounding box, each multiplied
      // by the appropriate scaling factor.
      canvas.drawRect(
        Rect.fromLTRB(
          face.boundingBox.left * scaleX,
          face.boundingBox.top * scaleY,
          face.boundingBox.right * scaleX,
          face.boundingBox.bottom * scaleY,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    // The painter should only be redrawn if the input data has changed.
    // This optimization prevents unnecessary redraws on every frame, improving performance.
    // It checks if the list of faces, the source image size, or the target widget size has changed.
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.widgetSize != widgetSize;
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */