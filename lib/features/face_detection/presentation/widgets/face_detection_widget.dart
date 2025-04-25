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

  const FaceDetectionWidget({
    super.key,
    required this.cameraController,
    required this.width,
    required this.height,
    required this.faces,
    required this.imageSize,
  });

  @override
  State<FaceDetectionWidget> createState() => _FaceDetectionWidgetState();
}

class _FaceDetectionWidgetState extends State<FaceDetectionWidget> {
  late UVCCameraViewParamsEntity _params;

  @override
  void initState() {
    super.initState();
    _params = UVCCameraViewParamsEntity(frameFormat: 0, minFps: 15, maxFps: 30);
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
              // Camera view with adjusted dimensions
              Center(
                child: SizedBox(
                  width: cameraWidth,
                  height: cameraHeight,
                  child: UVCCameraView(
                    cameraController: widget.cameraController,
                    params: _params,
                    width: cameraWidth,
                    height: cameraHeight,
                  ),
                ),
              ),

              // Face overlay
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: FaceDetectionPainter(
                  faces: widget.faces,
                  previewSize: Size(widget.width, widget.height),
                  imageSize: widget.imageSize,
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
