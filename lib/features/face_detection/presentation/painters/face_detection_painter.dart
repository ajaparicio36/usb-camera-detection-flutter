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

      // Draw facial landmarks if available
      if (face.landmarks.containsKey(FaceLandmarkType.leftEye) &&
          face.landmarks.containsKey(FaceLandmarkType.rightEye)) {
        final Paint eyePaint =
            Paint()
              ..color = Colors.white.withOpacity(0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

        final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
        final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;

        final double leftEyeX = _scaleX(
          leftEye.x.toDouble(),
          imageSize.width,
          previewSize.width,
        );
        final double leftEyeY = _scaleY(
          leftEye.y.toDouble(),
          imageSize.height,
          previewSize.height,
        );
        final double rightEyeX = _scaleX(
          rightEye.x.toDouble(),
          imageSize.width,
          previewSize.width,
        );
        final double rightEyeY = _scaleY(
          rightEye.y.toDouble(),
          imageSize.height,
          previewSize.height,
        );

        // Draw stylized eye indicators
        canvas.drawCircle(Offset(leftEyeX, leftEyeY), 5, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, rightEyeY), 5, eyePaint);
      }
    }
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
    return oldDelegate.faces != faces ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.imageSize != imageSize;
  }
}
