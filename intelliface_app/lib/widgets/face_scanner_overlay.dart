// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/widgets/face_scanner_overlay.dart
// Purpose : Defines UI overlays for the face scanning screen, including a
//           viewfinder and a success animation.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// A stateful widget that provides a sophisticated overlay for face scanning.
/// It manages the animations for a pulsing viewfinder effect.
class FaceScannerOverlay extends StatefulWidget {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// A boolean indicating if a face is currently detected in the camera view.
  final bool hasFace;

  /// A boolean indicating if the face scan has been successfully completed.
  final bool isSuccess;

  /* ============================================================================
   * 2. Constructor
   * ========================================================================== */

  const FaceScannerOverlay({
    super.key,
    required this.hasFace,
    this.isSuccess = false,
  });

  @override
  State<FaceScannerOverlay> createState() => _FaceScannerOverlayState();
}

/// Manages the state and animations for the [FaceScannerOverlay].
class _FaceScannerOverlayState extends State<FaceScannerOverlay>
    with SingleTickerProviderStateMixin {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The controller for the pulsing border animation.
  late AnimationController _pulseController;
  /// The animation driven by the controller, which provides values from 0.0 to 1.0.
  late Animation<double> _pulseAnimation;

  /* ============================================================================
   * 2. Lifecycle Methods
   * ========================================================================== */

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller to run for 1.5 seconds and repeat indefinitely.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Create a tween animation that transitions from 0.0 to 1.0 with an ease-in-out curve.
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Dispose the animation controller to free up resources when the widget is removed.
    _pulseController.dispose();
    super.dispose();
  }

  /* ============================================================================
   * 3. Build Method
   * ========================================================================== */

  @override
  Widget build(BuildContext context) {
    // Use a CustomPaint widget to draw the overlay using our custom painter.
    return CustomPaint(
      painter: _FaceScannerOverlayPainter(
        hasFace: widget.hasFace,
        isSuccess: widget.isSuccess,
        pulseAnimation: _pulseAnimation,
      ),
      // The child is an empty container as the painting is done in the foreground.
      child: Container(),
    );
  }
}

/// A [CustomPainter] that draws the visual elements of the face scanner overlay.
class _FaceScannerOverlayPainter extends CustomPainter {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  final bool hasFace;
  final bool isSuccess;
  final Animation<double> pulseAnimation;

  /* ============================================================================
   * 2. Constructor
   * ========================================================================== */

  _FaceScannerOverlayPainter({
    required this.hasFace,
    required this.isSuccess,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation); // The painter will repaint whenever the animation ticks.

  /* ============================================================================
   * 3. Painter Methods
   * ========================================================================== */

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.55;
    // Define the central oval cutout area.
    final ovalRect = Rect.fromCenter(
        center: center, width: ovalWidth, height: ovalHeight);

    // Determine the border color and width based on the current state.
    final borderColor = isSuccess
        ? Colors.green.shade400
        : (hasFace ? Colors.green.shade400 : Colors.white);
    final double borderWidth = isSuccess ? 4.0 : 2.5;

    // --- Step 1: Draw the semi-transparent background overlay ---
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    // Create a path that is the difference between a full-screen rectangle and the central oval.
    // This effectively "cuts out" the oval from the background.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addOval(ovalRect),
      ),
      backgroundPaint,
    );

    // --- Step 2: Draw the static border around the oval cutout ---
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(ovalRect, borderPaint);

    // --- Step 3: Draw the animated pulsing border if not in a success state ---
    if (!isSuccess) {
      final pulseValue = pulseAnimation.value; // Get current value from the animation (0.0 to 1.0).
      final pulseRadius = 10.0 * pulseValue; // The pulse expands by up to 10 logical pixels.
      final pulseOpacity = 1.0 - pulseValue; // The pulse fades out as it expands.

      final pulsePaint = Paint()
        ..color = borderColor.withOpacity(pulseOpacity * 0.5) // Apply the fade effect.
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw the pulsing oval by inflating the base oval rect by the current pulse radius.
      canvas.drawOval(ovalRect.inflate(pulseRadius), pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_FaceScannerOverlayPainter oldDelegate) {
    // The painter should be redrawn if its state (hasFace, isSuccess) changes.
    // The animation itself already triggers repaints because it's passed to the super constructor.
    return oldDelegate.hasFace != hasFace ||
        oldDelegate.isSuccess != isSuccess;
  }
}

/// An [AnimatedWidget] that displays a growing and fading-in checkmark circle
/// to provide clear visual feedback upon successful face capture.
class SuccessCheckmark extends AnimatedWidget {
  /* ============================================================================
   * 1. Constructor
   * ========================================================================== */

  const SuccessCheckmark({super.key, required Animation<double> animation})
      : super(listenable: animation);

  /* ============================================================================
   * 2. Properties
   * ========================================================================== */

  /// A getter to conveniently access the listenable animation with the correct type.
  Animation<double> get _progress => listenable as Animation<double>;

  /* ============================================================================
   * 3. Build Method
   * ========================================================================== */

  @override
  Widget build(BuildContext context) {
    // An animation that controls the scale of the checkmark, giving it an "elastic" pop-in effect.
    final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _progress, curve: Curves.elasticOut),
    );
    // An animation that controls the opacity, making the checkmark fade in smoothly.
    final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progress, curve: Curves.easeIn),
    );

    // Combine the animations using FadeTransition and ScaleTransition.
    return FadeTransition(
      opacity: opacityAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.8),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.check_rounded, size: 80, color: Colors.white),
        ),
      ),
    );
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */