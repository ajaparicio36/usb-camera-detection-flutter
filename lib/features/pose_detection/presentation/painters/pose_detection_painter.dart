import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/colors.dart';

class PoseDetectionPainter extends CustomPainter {
  final List<Pose> poses;
  final Size previewSize;
  final Size imageSize;

  PoseDetectionPainter({
    required this.poses,
    required this.previewSize,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint landmarkPaint =
        Paint()
          ..color = AppColors.accentBlue
          ..style = PaintingStyle.fill
          ..strokeWidth = 3.0;

    final Paint connectionPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    for (final pose in poses) {
      _drawBody(canvas, pose, landmarkPaint, connectionPaint);
    }
  }

  void _drawBody(
    Canvas canvas,
    Pose pose,
    Paint landmarkPaint,
    Paint connectionPaint,
  ) {
    // Draw connections
    _drawConnections(canvas, pose, connectionPaint);

    // Draw landmarks
    _drawLandmarks(canvas, pose, landmarkPaint);
  }

  void _drawLandmarks(Canvas canvas, Pose pose, Paint paint) {
    // Draw all landmarks
    pose.landmarks.forEach((type, landmark) {
      if (landmark.likelihood > 0.5) {
        final Offset position = Offset(
          _scaleX(landmark.x, imageSize.width, previewSize.width),
          _scaleY(landmark.y, imageSize.height, previewSize.height),
        );

        // Draw a circle at landmark position
        canvas.drawCircle(position, 7.0, paint);
      }
    });
  }

  void _drawConnections(Canvas canvas, Pose pose, Paint paint) {
    // Define the pose connections
    final connections = [
      // Face
      [PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner],
      [PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye],
      [PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter],
      [PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner],
      [PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye],
      [PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter],
      [PoseLandmarkType.nose, PoseLandmarkType.leftMouth],
      [PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth],
      [PoseLandmarkType.rightMouth, PoseLandmarkType.nose],

      // Upper body
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],

      // Arms
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
      [PoseLandmarkType.leftPinky, PoseLandmarkType.leftIndex],
      [PoseLandmarkType.rightPinky, PoseLandmarkType.rightIndex],

      // Body
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],

      // Legs
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
      [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
      [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
    ];

    // Draw each connection if both landmarks are visible
    for (final connection in connections) {
      final start = pose.landmarks[connection[0]];
      final end = pose.landmarks[connection[1]];

      if (start != null &&
          end != null &&
          start.likelihood > 0.5 &&
          end.likelihood > 0.5) {
        final startPoint = Offset(
          _scaleX(start.x, imageSize.width, previewSize.width),
          _scaleY(start.y, imageSize.height, previewSize.height),
        );

        final endPoint = Offset(
          _scaleX(end.x, imageSize.width, previewSize.width),
          _scaleY(end.y, imageSize.height, previewSize.height),
        );

        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  // Helper function to determine if the pose is in proper position
  static bool isPoseAligned(Pose pose) {
    // Simple check if shoulders and hips are roughly level
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return false;
    }

    // Check if shoulders are roughly level (within 15 degrees)
    final shoulderAngle =
        (rightShoulder.y - leftShoulder.y).abs() /
        (rightShoulder.x - leftShoulder.x).abs();

    // Check if hips are roughly level
    final hipAngle =
        (rightHip.y - leftHip.y).abs() / (rightHip.x - leftHip.x).abs();

    return shoulderAngle < 0.27 && hipAngle < 0.27; // Approximately 15 degrees
  }

  double _scaleX(double x, double imageWidth, double widgetWidth) {
    return x * widgetWidth / imageWidth;
  }

  double _scaleY(double y, double imageHeight, double widgetHeight) {
    return y * widgetHeight / imageHeight;
  }

  @override
  bool shouldRepaint(PoseDetectionPainter oldDelegate) {
    // Quick checks first
    if (poses.length != oldDelegate.poses.length) return true;
    if (previewSize != oldDelegate.previewSize) return true;
    if (imageSize != oldDelegate.imageSize) return true;

    // Skip detailed pose comparison if references are the same
    if (identical(poses, oldDelegate.poses)) return false;

    // More detailed comparison for poses if necessary
    for (int i = 0; i < poses.length; i++) {
      // Compare the landmarks positions of each pose
      final landmarks1 = poses[i].landmarks;
      final landmarks2 = oldDelegate.poses[i].landmarks;

      if (landmarks1.length != landmarks2.length) {
        return true;
      }

      for (final type in landmarks1.keys) {
        final lm1 = landmarks1[type];
        final lm2 = landmarks2[type];
        if (lm1?.x != lm2?.x || lm1?.y != lm2?.y) {
          return true;
        }
      }
    }

    // If we got here, poses are visually the same
    return false;
  }
}
