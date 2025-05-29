import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) {
      // On web, permissions are handled by the browser automatically
      // when accessing the camera through image_picker
      return true;
    }
    
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Capture image from camera
  static Future<File?> captureImage() async {
    try {
      // Request permission first
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Compress to reduce file size
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Convert image file to base64 string
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  /// Show camera capture dialog
  static Future<String?> showCameraDialog(BuildContext context, {
    required String title,
    required String message,
  }) async {
    File? imageFile;
    
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  if (imageFile != null) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final capturedImage = await captureImage();
                          if (capturedImage != null) {
                            setState(() {
                              imageFile = capturedImage;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(imageFile == null ? 'Take Photo' : 'Retake'),
                      ),
                      if (imageFile != null)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final base64 = await imageToBase64(imageFile!);
                            Navigator.of(context).pop(base64);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Use Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Skip'),
                ),
                if (imageFile == null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show camera dialog for attendance image capture
  static Future<File?> captureAttendanceImage(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AttendanceImageDialog(),
    );
  }
}

class _AttendanceImageDialog extends StatefulWidget {
  @override
  _AttendanceImageDialogState createState() => _AttendanceImageDialogState();
}

class _AttendanceImageDialogState extends State<_AttendanceImageDialog> {
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Capture Attendance Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Take a photo for your attendance record'),
          const SizedBox(height: 16),
          if (imageFile != null) ...[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final capturedImage = await CameraService.captureImage();
                  if (capturedImage != null) {
                    setState(() {
                      imageFile = capturedImage;
                    });
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(imageFile == null ? 'Take Photo' : 'Retake'),
              ),
              if (imageFile != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(imageFile);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Use Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        if (imageFile == null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
