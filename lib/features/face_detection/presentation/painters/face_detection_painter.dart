import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/theme/colors.dart';

class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final Size imageSize;

  FaceDetectionPainter({
    required this.faces,
    required this.previewSize,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint rectanglePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.white.withOpacity(0.8)
          ..strokeCap = StrokeCap.round;

    final Paint cornerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = AppColors.accentBlue
          ..strokeCap = StrokeCap.round;

    final Paint contourPaint =
        Paint()
          ..color = Colors.greenAccent.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final Paint landmarkPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0;

    final Paint gazePaint =
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    for (final face in faces) {
      // Scale the face bounding box to match the preview size
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        widgetSize: previewSize,
      );

      // Draw modern rectangle with rounded corners
      final RRect roundedRect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(8),
      );
      canvas.drawRRect(roundedRect, rectanglePaint);

      // Draw corner accents
      final double cornerLength = min(rect.width, rect.height) * 0.2;

      // Top left corner
      canvas.drawLine(
        Offset(rect.left, rect.top + cornerLength),
        Offset(rect.left, rect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.left + cornerLength, rect.top),
        cornerPaint,
      );

      // Top right corner
      canvas.drawLine(
        Offset(rect.right - cornerLength, rect.top),
        Offset(rect.right, rect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLength),
        cornerPaint,
      );

      // Bottom right corner
      canvas.drawLine(
        Offset(rect.right, rect.bottom - cornerLength),
        Offset(rect.right, rect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.bottom),
        Offset(rect.right - cornerLength, rect.bottom),
        cornerPaint,
      );

      // Bottom left corner
      canvas.drawLine(
        Offset(rect.left + cornerLength, rect.bottom),
        Offset(rect.left, rect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLength),
        cornerPaint,
      );

      // Draw all available face contours
      _drawFaceContours(canvas, face, contourPaint);

      // Draw all available facial landmarks
      _drawFacialLandmarks(canvas, face, landmarkPaint);

      // Draw gaze direction if available
      if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
        _drawGazeIndicator(canvas, face, rect, gazePaint);
      }
    }
  }

  void _drawFaceContours(Canvas canvas, Face face, Paint paint) {
    // Map of all available contour types
    final contourTypes = {
      FaceContourType.face,
      FaceContourType.leftEyebrowTop,
      FaceContourType.leftEyebrowBottom,
      FaceContourType.rightEyebrowTop,
      FaceContourType.rightEyebrowBottom,
      FaceContourType.leftEye,
      FaceContourType.rightEye,
      FaceContourType.upperLipTop,
      FaceContourType.upperLipBottom,
      FaceContourType.lowerLipTop,
      FaceContourType.lowerLipBottom,
      FaceContourType.noseBridge,
      FaceContourType.noseBottom,
      FaceContourType.leftCheek,
      FaceContourType.rightCheek,
    };

    for (final contourType in contourTypes) {
      final contour = face.contours[contourType];
      if (contour != null && contour.points.isNotEmpty) {
        final path = Path();

        // Get the first point and move to it
        final firstPoint = contour.points.first;
        final firstScaledPoint = Offset(
          _scaleX(firstPoint.x.toDouble(), imageSize.width, previewSize.width),
          _scaleY(
            firstPoint.y.toDouble(),
            imageSize.height,
            previewSize.height,
          ),
        );
        path.moveTo(firstScaledPoint.dx, firstScaledPoint.dy);

        // Add lines to all other points
        for (int i = 1; i < contour.points.length; i++) {
          final point = contour.points[i];
          final scaledPoint = Offset(
            _scaleX(point.x.toDouble(), imageSize.width, previewSize.width),
            _scaleY(point.y.toDouble(), imageSize.height, previewSize.height),
          );
          path.lineTo(scaledPoint.dx, scaledPoint.dy);
        }

        // For closed contours like eyes or face, close the path
        if (contourType == FaceContourType.leftEye ||
            contourType == FaceContourType.rightEye ||
            contourType == FaceContourType.face) {
          path.close();
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawFacialLandmarks(Canvas canvas, Face face, Paint paint) {
    final landmarkTypes = {
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.noseBase,
    };

    for (final landmarkType in landmarkTypes) {
      final landmark = face.landmarks[landmarkType];
      if (landmark != null) {
        final position = landmark.position;
        final scaledPoint = Offset(
          _scaleX(position.x.toDouble(), imageSize.width, previewSize.width),
          _scaleY(position.y.toDouble(), imageSize.height, previewSize.height),
        );
        // Draw a small circle at landmark position
        canvas.drawCircle(scaledPoint, 3.0, paint);
      }
    }
  }

  void _drawGazeIndicator(
    Canvas canvas,
    Face face,
    Rect faceRect,
    Paint gazePaint,
  ) {
    // Use head euler angles to determine gaze direction
    final double? yaw = face.headEulerAngleY; // Left/right rotation
    final double? pitch = face.headEulerAngleX; // Up/down rotation

    if (yaw == null || pitch == null) return;

    // Center of the face
    final Offset faceCenter = Offset(
      faceRect.left + faceRect.width / 2,
      faceRect.top + faceRect.height / 2,
    );

    // Calculate gaze vector based on euler angles
    // Simplified model: yaw affects x-direction, pitch affects y-direction
    final double gazeLength = faceRect.width * 0.7;
    final double gazeX = gazeLength * sin((yaw * pi) / 180);
    final double gazeY = gazeLength * sin((pitch * pi) / 180);

    // Endpoint of the gaze vector
    final Offset gazeEndpoint = Offset(
      faceCenter.dx + gazeX,
      faceCenter.dy + gazeY,
    );

    // Draw the gaze line
    canvas.drawLine(faceCenter, gazeEndpoint, gazePaint);

    // Draw arrow tip
    final double arrowSize = 10.0;
    final double angle = atan2(
      gazeEndpoint.dy - faceCenter.dy,
      gazeEndpoint.dx - faceCenter.dx,
    );

    final Path arrowPath =
        Path()
          ..moveTo(
            gazeEndpoint.dx - arrowSize * cos(angle - pi / 6),
            gazeEndpoint.dy - arrowSize * sin(angle - pi / 6),
          )
          ..lineTo(gazeEndpoint.dx, gazeEndpoint.dy)
          ..lineTo(
            gazeEndpoint.dx - arrowSize * cos(angle + pi / 6),
            gazeEndpoint.dy - arrowSize * sin(angle + pi / 6),
          );

    canvas.drawPath(arrowPath, gazePaint);
  }

  // Helper function to determine if face is looking at camera
  static bool isFacingCamera(Face face) {
    // Check if head rotation is within a threshold
    // This is a simplified approach - you might want to adjust thresholds
    final double? yaw = face.headEulerAngleY; // Left/right rotation
    final double? pitch = face.headEulerAngleX; // Up/down rotation

    if (yaw == null || pitch == null) return false;

    // Define thresholds for "looking at camera"
    const double YAW_THRESHOLD = 15.0; // degrees
    const double PITCH_THRESHOLD = 15.0; // degrees

    return (yaw.abs() < YAW_THRESHOLD) && (pitch.abs() < PITCH_THRESHOLD);
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
  }) {
    return Rect.fromLTRB(
      _scaleX(rect.left, imageSize.width, widgetSize.width),
      _scaleY(rect.top, imageSize.height, widgetSize.height),
      _scaleX(rect.right, imageSize.width, widgetSize.width),
      _scaleY(rect.bottom, imageSize.height, widgetSize.height),
    );
  }

  double _scaleX(double x, double imageWidth, double widgetWidth) {
    return x * widgetWidth / imageWidth;
  }

  double _scaleY(double y, double imageHeight, double widgetHeight) {
    return y * widgetHeight / imageHeight;
  }

  @override
  bool shouldRepaint(FaceDetectionPainter oldDelegate) {
    // Quick checks first
    if (faces.length != oldDelegate.faces.length) return true;
    if (previewSize != oldDelegate.previewSize) return true;
    if (imageSize != oldDelegate.imageSize) return true;

    // Skip detailed face comparison if references are the same
    if (identical(faces, oldDelegate.faces)) return false;

    // More detailed comparison for faces only if necessary
    for (int i = 0; i < faces.length; i++) {
      final Face newFace = faces[i];
      final Face oldFace = oldDelegate.faces[i];

      // Compare essential properties that affect visual appearance
      if (newFace.boundingBox != oldFace.boundingBox) return true;
      if (newFace.headEulerAngleX != oldFace.headEulerAngleX) return true;
      if (newFace.headEulerAngleY != oldFace.headEulerAngleY) return true;
      if (newFace.headEulerAngleZ != oldFace.headEulerAngleZ) return true;

      // If trackingId is available and different, it's a different face
      final int? newId = newFace.trackingId;
      final int? oldId = oldFace.trackingId;
      if (newId != null && oldId != null && newId != oldId) return true;
    }

    // If we got here, faces are visually the same
    return false;
  }
}
