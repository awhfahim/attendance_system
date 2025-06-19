import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../utils/app_colors.dart';

class RecentAttendanceList extends StatelessWidget {
  const RecentAttendanceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final recentRecords = attendanceProvider.getRecentAttendance();
        
        if (recentRecords.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your recent attendance will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/attendance-history');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRecords.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = recentRecords[index];
                  return _AttendanceListTile(record: record);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceListTile extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceListTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    final isPresent = record.checkInTime != null;
    final checkInTimeLocal = record.checkInTime?.toLocal();
    final isLate = checkInTimeLocal != null && (checkInTimeLocal.hour > 9 || (checkInTimeLocal.hour == 9 && checkInTimeLocal.minute > 0));
    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (!isPresent) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
      statusText = 'Absent';
    } else if (isLate) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'Late';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'On Time';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          statusIcon,
          color: statusColor,
          size: 24,
        ),
      ),
      title: Text(
        dateFormat.format(record.date.toLocal()),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.login,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                record.checkInTime != null 
                    ? 'In: ${timeFormat.format(record.checkInTime!.toLocal())}'
                    : 'Not checked in',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (record.checkOutTime != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.logout,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Out: ${timeFormat.format(record.checkOutTime!.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          if (record.totalHours != null) ...[
            const SizedBox(height: 2),
            Text(
              'Total: ${record.totalHours!.toStringAsFixed(1)} hours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
