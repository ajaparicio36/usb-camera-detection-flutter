import 'package:flutter/material.dart';
import 'package:usb_camera_detection/core/theme/colors.dart';
import 'package:usb_camera_detection/core/theme/neumorphic_container.dart';
import 'package:usb_camera_detection/features/face_detection/presentation/screens/face_detection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'USB Camera Detection',
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Select Detection Type',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: buildDetectionTypeButton(
                        context,
                        'Face Detection',
                        Icons.face,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceDetectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: buildDetectionTypeButton(
                        context,
                        'Object Detection',
                        Icons.camera_alt,
                        () {
                          // Navigate to object detection screen
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetectionTypeButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicButton(
              width: 80,
              height: 80,
              onPressed: onPressed,
              child: Icon(icon, size: 40, color: AppColors.iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to start',
              style: TextStyle(fontSize: 14, color: AppColors.iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
