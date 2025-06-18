// ─────────────────────────────────────────────────────────────
// File        : face_scan_screen.dart
// Purpose     : Live face recognition using camera and ML Kit
// Role        : Used in Check-In/Check-Out to capture and verify face
// Features    :
//   - Uses front camera to stream frames
//   - Detects faces using Google ML Kit
//   - Captures image on detection and provides feedback (sound, vibration)
//   - Returns captured image to parent screen
// Used In     : CheckInScreen, CheckOutScreen (part of attendance flow)
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:vibration/vibration.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;

import '../widgets/face_scanner_overlay.dart';
import '../utils/app_styles.dart';

class FaceScanScreen extends StatefulWidget {
  final Function(File? capturedImageFile)? onFaceScanComplete;

  const FaceScanScreen({super.key, this.onFaceScanComplete});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _faceFoundAndProcessing = false;
  List<Face> _faces = [];
  CameraDescription? _cameraDescription;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableTracking: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize the front-facing camera and start frame stream
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorToast("No cameras available.");
        if (mounted) Navigator.pop(context, null);
        return;
      }

      _cameraDescription = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _cameraDescription!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
      await _cameraController!.startImageStream(_processCameraImageForDetection);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _showErrorToast("Error initializing camera.");
      if (mounted) Navigator.pop(context, null);
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(msg: message, backgroundColor: AppColors.error, textColor: Colors.white);
  }

  /// Convert camera planes into usable byte stream
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// Main logic: process image stream and detect face
  Future<void> _processCameraImageForDetection(CameraImage image) async {
    if (_isDetecting || _faceFoundAndProcessing || !mounted || _cameraController == null || !_cameraController!.value.isStreamingImages) {
      return;
    }

    _isDetecting = true;

    try {
      final sensorOrientation = _cameraDescription!.sensorOrientation;
      InputImageRotation rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation270deg;

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      List<Face> faces = await _faceDetector.processImage(inputImage);

      if (!mounted) {
        _isDetecting = false;
        return;
      }

      if (_faces.isEmpty != faces.isEmpty) {
        if (mounted) setState(() => _faces = faces);
      } else {
        _faces = faces;
      }

      // Face Detected → Proceed to snapshot
      if (faces.isNotEmpty && !_faceFoundAndProcessing) {
        setState(() => _faceFoundAndProcessing = true);

        if (mounted) await _cameraController?.stopImageStream();

        File? snapshotFile;
        if (_cameraController?.value.isInitialized == true && _cameraController?.value.isTakingPicture == false) {
          try {
            XFile xFile = await _cameraController!.takePicture();
            snapshotFile = File(xFile.path);
          } catch (e) {
            _showErrorToast("Could not capture image.");
          }
        }

        // Feedback: play sound and vibrate
        AssetsAudioPlayer.newPlayer().open(Audio("assets/sounds/success.mp3"), autoStart: true, volume: 0.5)
            .catchError((e) => print("Error playing sound: $e"));
        if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 200);

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        widget.onFaceScanComplete?.call(snapshotFile);
        Navigator.pop(context, snapshotFile);
      } else {
        _isDetecting = false;
      }
    } catch (e) {
      debugPrint("FaceScanScreen: Error in image stream processing: $e");
      if (mounted) _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    Future.microtask(() async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        if (_cameraController!.value.isStreamingImages) {
          try {
            await _cameraController!.stopImageStream();
          } catch (e) {
            print("Error stopping image stream on dispose: $e");
          }
        }
        await _cameraController!.dispose();
      }
      _cameraController = null;
    });
    super.dispose();
  }

  /// Dynamic scan status message shown at the bottom
  String get _instructionText {
    if (_faceFoundAndProcessing) return "Perfect! Processing...";
    if (_faces.isNotEmpty) return "Face Aligned, Hold Still";
    return "Align Your Face Within The Oval";
  }

  /// UI with camera preview + face overlay + instructions
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context, null)),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),

          FaceScannerOverlay(
            hasFace: _faces.isNotEmpty,
            isSuccess: _faceFoundAndProcessing,
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(50)),
              child: Text(
                _instructionText,
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(16, Colors.white, FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context, null),
                tooltip: "Cancel Scan",
                splashRadius: 24,
              ),
            ),
          )
        ],
      ),
    );
  }
}
