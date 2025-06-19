import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';
import '../services/camera_service.dart';
import '../widgets/attendance_image_widget.dart';

class AttendanceCard extends StatefulWidget {
  const AttendanceCard({super.key});

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  bool _isProcessing = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Request location permission first
      await attendanceProvider.requestLocationPermission();
      
      // Capture image for check-in
      File? capturedImage;
      final shouldCaptureImage = await _showImageCaptureDialog('check-in');
      
      if (shouldCaptureImage == true) {
        capturedImage = await CameraService.captureAttendanceImage(context);
      }
      
      final success = await attendanceProvider.checkIn(
        isRemote: true, // Assuming remote work by default
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        image: capturedImage,
      );

      if (success) {
        final localTime = DateTime.now().toLocal();
        await NotificationService.showAttendanceConfirmation(
          'Successfully checked in at \\${DateFormat('hh:mm a').format(localTime)}',
        );
        _notesController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully checked in!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.errorMessage ?? 'Check-in failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to check in. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image for check-out
      File? capturedImage;
      final shouldCaptureImage = await _showImageCaptureDialog('check-out');
      
      if (shouldCaptureImage == true) {
        capturedImage = await CameraService.captureAttendanceImage(context);
      }
      
      final success = await attendanceProvider.checkOut(
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        image: capturedImage,
      );

      if (success) {
        final localTime = DateTime.now().toLocal();
        await NotificationService.showAttendanceConfirmation(
          'Successfully checked out at \\${DateFormat('hh:mm a').format(localTime)}',
        );
        _notesController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully checked out!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.errorMessage ?? 'Check-out failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to check out. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool?> _showImageCaptureDialog(String action) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Capture Photo'),
        content: Text('Would you like to take a photo for your $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final todayAttendance = attendanceProvider.todayAttendance;
        final isCheckedIn = attendanceProvider.isCheckedIn;
        final isCheckedOut = attendanceProvider.isCheckedOut;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(isCheckedIn, isCheckedOut).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(isCheckedIn, isCheckedOut),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(isCheckedIn, isCheckedOut),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (todayAttendance != null) ...[
                  _buildTimeDisplay(todayAttendance),
                  const SizedBox(height: 20),
                  // Show attendance images if available
                  if (todayAttendance.checkInImagePath != null || todayAttendance.checkOutImagePath != null) ...[
                    AttendanceImageWidget(
                      checkInImagePath: todayAttendance.checkInImagePath,
                      checkOutImagePath: todayAttendance.checkOutImagePath,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
                _buildActionSection(isCheckedIn, isCheckedOut),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeDisplay(attendance) {
    // Use toLocal() only, do NOT add extra hours
    final checkInTime = DateFormat('hh:mm a').format(attendance.checkInTime.toLocal());
    final checkOutTime = attendance.checkOutTime != null
        ? DateFormat('hh:mm a').format(attendance.checkOutTime!.toLocal())
        : '--:--';
    
    return Row(
      children: [
        Expanded(
          child: _buildTimeCard(
            'Check In',
            checkInTime,
            Icons.login,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeCard(
            'Check Out',
            checkOutTime,
            Icons.logout,
            attendance.checkOutTime != null ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isCheckedIn, bool isCheckedOut) {
    return Column(
      children: [
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Add notes (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            prefixIcon: const Icon(Icons.note_add),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : isCheckedOut
                    ? null
                    : isCheckedIn
                        ? _handleCheckOut
                        : _handleCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedOut
                  ? AppColors.textSecondary
                  : isCheckedIn
                      ? AppColors.error
                      : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCheckedOut
                            ? Icons.check_circle
                            : isCheckedIn
                                ? Icons.logout
                                : Icons.login,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCheckedOut
                            ? 'Completed for Today'
                            : isCheckedIn
                                ? 'Check Out'
                                : 'Check In',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(bool isCheckedIn, bool isCheckedOut) {
    if (isCheckedOut) return AppColors.success;
    if (isCheckedIn) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _getStatusText(bool isCheckedIn, bool isCheckedOut) {
    if (isCheckedOut) return 'COMPLETED';
    if (isCheckedIn) return 'CHECKED IN';
    return 'NOT STARTED';
  }
}
