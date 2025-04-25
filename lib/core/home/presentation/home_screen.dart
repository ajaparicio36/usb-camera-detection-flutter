import 'package:flutter/material.dart';
import 'package:usb_camera_detection/features/face_detection/presentation/screens/face_detection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Camera Detection')),
      body: Center(
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
    );
  }

  Widget buildDetectionTypeButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
