import 'package:flutter/material.dart';
import 'package:flutter_uvc_camera/flutter_uvc_camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/colors.dart';
import '../painters/pose_detection_painter.dart';
import '../../../../core/theme/neumorphic_container.dart';

class PoseDetectionWidget extends StatefulWidget {
  final UVCCameraController cameraController;
  final double width;
  final double height;
  final List<Pose> poses;
  final Size imageSize;
  final Function(List<int>)? onPoseAligned;

  const PoseDetectionWidget({
    super.key,
    required this.cameraController,
    required this.width,
    required this.height,
    required this.poses,
    required this.imageSize,
    this.onPoseAligned,
  });

  @override
  State<PoseDetectionWidget> createState() => _PoseDetectionWidgetState();
}

class _PoseDetectionWidgetState extends State<PoseDetectionWidget> {
  late UVCCameraViewParamsEntity _params;
  List<int> _lastReportedPosesAligned = [];

  @override
  void initState() {
    super.initState();
    _params = UVCCameraViewParamsEntity(frameFormat: 0, minFps: 15, maxFps: 30);

    // Process pose alignment on initial poses if available
    if (widget.poses.isNotEmpty && widget.onPoseAligned != null) {
      _processPoseAlignment();
    }
  }

  @override
  void didUpdateWidget(PoseDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only process when the poses list changes (not just the reference)
    bool posesChanged = widget.poses.length != oldWidget.poses.length;

    // Check if individual poses changed when count is the same
    if (!posesChanged && widget.poses.isNotEmpty) {
      for (int i = 0; i < widget.poses.length; i++) {
        // Compare some key landmarks to determine if poses changed
        final oldLandmarks = oldWidget.poses[i].landmarks;
        final newLandmarks = widget.poses[i].landmarks;

        if (oldLandmarks.length != newLandmarks.length) {
          posesChanged = true;
          break;
        }

        // Check a few key points to see if they've changed
        final keyPoints = [
          PoseLandmarkType.nose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
        ];

        for (final point in keyPoints) {
          final oldLm = oldLandmarks[point];
          final newLm = newLandmarks[point];

          if ((oldLm?.x != newLm?.x) || (oldLm?.y != newLm?.y)) {
            posesChanged = true;
            break;
          }
        }

        if (posesChanged) break;
      }
    }

    // Schedule state update for the next frame instead of immediately
    if (posesChanged && widget.onPoseAligned != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processPoseAlignment();
        }
      });
    }
  }

  void _processPoseAlignment() {
    if (widget.onPoseAligned == null) return;

    // Create a new list to avoid modifying existing collections
    final List<int> posesWithProperAlignment = [];

    // Check each pose for proper alignment
    for (int i = 0; i < widget.poses.length; i++) {
      if (PoseDetectionPainter.isPoseAligned(widget.poses[i])) {
        posesWithProperAlignment.add(i);
      }
    }

    // Only notify parent if there's an actual change to reduce rebuilds
    if (_listEquals(posesWithProperAlignment, _lastReportedPosesAligned)) {
      return;
    }

    _lastReportedPosesAligned = List<int>.from(posesWithProperAlignment);

    // Use post-frame callback for notifying parent to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onPoseAligned != null) {
        widget.onPoseAligned!(posesWithProperAlignment);
      }
    });
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

              // Pose overlay with key to help Flutter optimize rebuilds
              RepaintBoundary(
                child: CustomPaint(
                  key: ValueKey('pose_painter_${widget.poses.length}'),
                  size: Size(widget.width, widget.height),
                  painter: PoseDetectionPainter(
                    poses: widget.poses,
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
