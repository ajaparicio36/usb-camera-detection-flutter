import 'package:flutter/material.dart';
import 'package:flutter_uvc_camera/flutter_uvc_camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/theme/colors.dart';
import '../painters/face_detection_painter.dart';
import '../../../../core/theme/neumorphic_container.dart';

class FaceDetectionWidget extends StatefulWidget {
  final UVCCameraController cameraController;
  final double width;
  final double height;
  final List<Face> faces;
  final Size imageSize;
  final Function(List<int>)? onGazeTracked;

  const FaceDetectionWidget({
    super.key,
    required this.cameraController,
    required this.width,
    required this.height,
    required this.faces,
    required this.imageSize,
    this.onGazeTracked,
  });

  @override
  State<FaceDetectionWidget> createState() => _FaceDetectionWidgetState();
}

class _FaceDetectionWidgetState extends State<FaceDetectionWidget> {
  late UVCCameraViewParamsEntity _params;
  List<int> _lastReportedFacesGazing = [];

  @override
  void initState() {
    super.initState();
    _params = UVCCameraViewParamsEntity(frameFormat: 0, minFps: 15, maxFps: 30);

    // Process gaze tracking on initial faces if available
    if (widget.faces.isNotEmpty && widget.onGazeTracked != null) {
      _processGazeTracking();
    }
  }

  @override
  void didUpdateWidget(FaceDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only process when the faces list changes (not just the reference)
    bool facesChanged = widget.faces.length != oldWidget.faces.length;

    // Check if individual faces changed when count is the same
    if (!facesChanged && widget.faces.isNotEmpty) {
      for (int i = 0; i < widget.faces.length; i++) {
        if (widget.faces[i].trackingId != oldWidget.faces[i].trackingId ||
            widget.faces[i].boundingBox != oldWidget.faces[i].boundingBox) {
          facesChanged = true;
          break;
        }
      }
    }

    if (facesChanged && widget.onGazeTracked != null) {
      _processGazeTracking();
    }
  }

  void _processGazeTracking() {
    if (widget.onGazeTracked == null) return;

    // Create a new list to avoid modifying existing collections
    final List<int> facesLookingAtCamera = [];

    // Check each face for gaze direction
    for (int i = 0; i < widget.faces.length; i++) {
      if (FaceDetectionPainter.isFacingCamera(widget.faces[i])) {
        facesLookingAtCamera.add(i);
      }
    }

    // Only notify parent if there's an actual change to reduce rebuilds
    if (_listEquals(facesLookingAtCamera, _lastReportedFacesGazing)) {
      return;
    }

    _lastReportedFacesGazing = List<int>.from(facesLookingAtCamera);
    widget.onGazeTracked!(facesLookingAtCamera);
  }

  // Simple list comparison utility
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate aspect ratio to avoid black borders
    final double aspectRatio = widget.imageSize.width / widget.imageSize.height;
    double cameraWidth = widget.width;
    double cameraHeight = widget.height;

    // Adjust dimensions based on aspect ratio
    if (widget.width / widget.height > aspectRatio) {
      // Width is too wide
      cameraWidth = widget.height * aspectRatio;
    } else {
      // Height is too tall
      cameraHeight = widget.width / aspectRatio;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: NeumorphicContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Camera view with adjusted dimensions - fixed position
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: cameraWidth,
                    height: cameraHeight,
                    child: UVCCameraView(
                      key: const ValueKey('uvc_camera_view'),
                      cameraController: widget.cameraController,
                      params: _params,
                      width: cameraWidth,
                      height: cameraHeight,
                    ),
                  ),
                ),
              ),

              // Face overlay with key to help Flutter optimize rebuilds
              RepaintBoundary(
                child: CustomPaint(
                  key: ValueKey('face_painter_${widget.faces.length}'),
                  size: Size(widget.width, widget.height),
                  painter: FaceDetectionPainter(
                    faces: widget.faces,
                    previewSize: Size(widget.width, widget.height),
                    imageSize: widget.imageSize,
                  ),
                ),
              ),

              // Decorative frame
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
