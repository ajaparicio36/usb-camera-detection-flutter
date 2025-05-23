import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_uvc_camera/flutter_uvc_camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/colors.dart';
import '../widgets/pose_detection_widget.dart';
import '../../../../core/theme/neumorphic_container.dart';

class PoseDetectionScreen extends StatefulWidget {
  const PoseDetectionScreen({super.key});

  @override
  State<PoseDetectionScreen> createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen>
    with SingleTickerProviderStateMixin {
  late UVCCameraController _cameraController;
  late PoseDetector _poseDetector;
  bool _isCameraInitialized = false;
  bool _isDetectorInitialized = false;
  List<Pose> _poses = [];
  String _processingStatus = "Initializing...";
  bool _isProcessing = false;
  Timer? _processingTimer;
  Size _imageSize = Size(640, 480); // Default size, updated after first frame
  bool _isCapturing = false;
  late AnimationController _animationController;
  List<int> _alignedPoses = []; // Track poses with proper alignment

  // Size related to the camera preview
  late double _previewWidth;
  late double _previewHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    initializeDetector();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeCamera();
    });
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _poseDetector.close();
    _animationController.dispose();
    super.dispose();
  }

  void initializeDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream, // Use stream mode for better performance
      model:
          PoseDetectionModel.accurate, // Use accurate model for better results
    );

    _poseDetector = PoseDetector(options: options);
    _isDetectorInitialized = true;
  }

  void initializeCamera() {
    _cameraController = UVCCameraController();

    setState(() {
      _isCameraInitialized = true;

      // Set preview dimensions based on available space
      final screenSize = MediaQuery.of(context).size;
      _previewWidth = screenSize.width * 0.9;
      _previewHeight = screenSize.height * 0.5; // Use a fixed ratio
    });

    // Replace periodic timer with single delayed call to avoid multiple timers
    _scheduleNextFrameProcessing();
  }

  // New method to schedule frame processing one at a time
  void _scheduleNextFrameProcessing() {
    if (!mounted) return;

    // Cancel any existing timer to prevent duplicates
    _processingTimer?.cancel();

    // Schedule next processing with a single shot timer
    _processingTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && !_isProcessing) {
        processFrame().then((_) {
          // Only schedule next frame if widget is still mounted
          if (mounted) {
            _scheduleNextFrameProcessing();
          }
        });
      } else if (mounted) {
        // If we're still processing, try again shortly
        _scheduleNextFrameProcessing();
      }
    });
  }

  void handlePoseAlignment(List<int> posesAligned) {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _alignedPoses = posesAligned;
        });
      }
    });
  }

  Future<void> processFrame() async {
    if (!_isCameraInitialized || !_isDetectorInitialized || _isProcessing) {
      return;
    }

    _isProcessing = true;
    if (mounted) {
      setState(() {
        _processingStatus = "Processing frame...";
        _isCapturing = true;
      });

      // Animate the capture status indicator
      _animationController.reset();
      _animationController.forward();
    }

    try {
      // Get the camera frame as a file path with a timeout to prevent hanging
      final String? imagePath = await _cameraController.takePicture().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (imagePath == null) {
        if (mounted) {
          setState(() {
            _processingStatus = "Failed to get frame";
            _isCapturing = false;
          });
        }
        _isProcessing = false;
        return;
      }

      // Verify file exists before proceeding
      final file = File(imagePath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            _processingStatus = "Image file not found";
            _isCapturing = false;
          });
        }
        _isProcessing = false;
        return;
      }

      // Get the actual image dimensions
      final image = await decodeImageFromList(await file.readAsBytes());
      final newImageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      // Create an InputImage from the file path
      final inputImage = InputImage.fromFilePath(imagePath);

      // Process the image with the pose detector
      final List<Pose> detectedPoses = await _poseDetector.processImage(
        inputImage,
      );

      // Delete the temporary file to avoid filling up storage
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting temporary file: $e');
      }

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          // Update image size separately to avoid triggering additional rebuilds
          _imageSize = newImageSize;

          // Create a new list to prevent reference issues
          _poses = List<Pose>.from(detectedPoses);

          _processingStatus =
              _poses.isEmpty
                  ? "No poses detected"
                  : "Detected ${_poses.length} ${_poses.length == 1 ? 'person' : 'people'}";
          _isCapturing = false;
        });
      }
    } catch (e) {
      print('Error processing frame: $e');
      if (mounted) {
        setState(() {
          _processingStatus =
              "Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e}";
          _isCapturing = false;
        });
      }
    } finally {
      // Ensure processing flag is reset
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: NeumorphicContainer(
                  isPressed: true,
                  padding: EdgeInsets.zero,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Initializing camera...',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pose Detection',
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Camera view with pose detection - use a key to avoid unnecessary rebuilds
              Expanded(
                flex: 3,
                child: Center(
                  child: PoseDetectionWidget(
                    key: ValueKey('pose_detection_widget'),
                    cameraController: _cameraController,
                    width: _previewWidth,
                    height: _previewHeight,
                    poses: _poses,
                    imageSize: _imageSize,
                    onPoseAligned: handlePoseAlignment,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Status display with animation
              SizedBox(
                height: 50,
                child: NeumorphicContainer(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  isPressed: true,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            width: 12,
                            height: 12,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isCapturing
                                      ? Color.lerp(
                                        AppColors.accentBlue,
                                        Colors.red,
                                        _animationController.value,
                                      )
                                      : AppColors.accentBlue,
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: Text(
                          _processingStatus,
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Pose alignment information
              SizedBox(
                height: 60,
                child: NeumorphicContainer(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  isPressed: true,
                  child: Row(
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        color: AppColors.accentBlue,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _alignedPoses.isEmpty
                              ? "No aligned poses detected"
                              : "${_alignedPoses.length} ${_alignedPoses.length == 1 ? 'person has' : 'people have'} proper alignment",
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Control panel
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.22,
                child: NeumorphicContainer(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'People Detected:',
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: NeumorphicContainer(
                              isPressed: true,
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(15),
                              child: Center(
                                child: Text(
                                  '${_poses.length}',
                                  style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Image: ${_imageSize.width.toInt()}x${_imageSize.height.toInt()}',
                        style: TextStyle(
                          color: AppColors.textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      Center(
                        child: NeumorphicButton(
                          width: 200,
                          height: 50,
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          onPressed: _isProcessing ? null : processFrame,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color:
                                    _isProcessing
                                        ? AppColors.iconColor.withOpacity(0.5)
                                        : AppColors.iconColor,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Capture & Detect',
                                style: TextStyle(
                                  color:
                                      _isProcessing
                                          ? AppColors.textColor.withOpacity(0.5)
                                          : AppColors.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
