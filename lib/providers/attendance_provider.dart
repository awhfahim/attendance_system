import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_record.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<AttendanceRecord> _attendanceRecords = [];
  AttendanceRecord? _todayAttendance;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  AttendanceRecord? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;

  bool get isCheckedIn => _todayAttendance != null && !_todayAttendance!.isCheckedOut;
  bool get isCheckedOut => _todayAttendance != null && _todayAttendance!.isCheckedOut;

  Future<void> loadTodayAttendance(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.getTodayAttendance(userId);
      if (response['success'] && response['attendance'] != null) {
        _todayAttendance = AttendanceRecord.fromJson(response['attendance']);
      } else {
        _todayAttendance = null;
      }
    } catch (e) {
      _setError('Failed to load today\'s attendance');
      debugPrint('Error loading today attendance: $e');
    }

    _setLoading(false);
    notifyListeners();
  }

  Future<void> loadAttendanceHistory(String userId, {int page = 1, int limit = 20}) async {
    if (page == 1) {
      _setLoading(true);
      _attendanceRecords.clear();
    }
    _clearError();

    try {
      final response = await ApiService.getAttendanceHistory(userId, page: page, limit: limit);
      if (response['success']) {
        final List<dynamic> recordsData = response['records'] ?? [];
        final records = recordsData.map((data) => AttendanceRecord.fromJson(data)).toList();
        
        if (page == 1) {
          _attendanceRecords = records;
        } else {
          _attendanceRecords.addAll(records);
        }
      } else {
        _setError(response['message'] ?? 'Failed to load attendance history');
      }
    } catch (e) {
      _setError('Failed to load attendance history');
      debugPrint('Error loading attendance history: $e');
    }

    _setLoading(false);
    notifyListeners();
  }

  Future<bool> checkIn({bool isRemote = false, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();
      
      final locationData = await LocationService.getAddressFromPosition(_currentPosition!);

      final response = await ApiService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        location: locationData,
        isRemote: isRemote,
        notes: notes,
      );

      if (response['success']) {
        _todayAttendance = AttendanceRecord.fromJson(response['attendance']);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Check-in failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Check-in failed. Please try again.');
      debugPrint('Error during check-in: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkOut({String? notes}) async {
    if (_todayAttendance == null || _todayAttendance!.isCheckedOut) {
      _setError('No active check-in found');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();
      
      final locationData = await LocationService.getAddressFromPosition(_currentPosition!);

      final response = await ApiService.checkOut(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        location: locationData,
        notes: notes,
      );

      if (response['success']) {
        _todayAttendance = AttendanceRecord.fromJson(response['attendance']);
        
        // Update the record in history if it exists
        final index = _attendanceRecords.indexWhere((record) => record.id == _todayAttendance!.id);
        if (index != -1) {
          _attendanceRecords[index] = _todayAttendance!;
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Check-out failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Check-out failed. Please try again.');
      debugPrint('Error during check-out: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      await LocationService.requestPermission();
    } catch (e) {
      _setError('Location permission is required for attendance tracking');
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await ApiService.getAttendanceSummary(userId, startDate, endDate);
      return response;
    } catch (e) {
      debugPrint('Error getting attendance summary: $e');
      return {'success': false, 'message': 'Failed to load summary'};
    }
  }

  Map<String, dynamic> getMonthlyStats() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final monthlyRecords = _attendanceRecords.where((record) {
      return record.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             record.date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    int daysPresent = 0;
    int lateDays = 0;
    double totalHours = 0;

    for (final record in monthlyRecords) {
      if (record.checkInTime != null) {
        daysPresent++;
        
        // Check if late (after 9 AM)
        if (record.checkInTime!.hour > 9 || 
            (record.checkInTime!.hour == 9 && record.checkInTime!.minute > 0)) {
          lateDays++;
        }
        
        if (record.totalHours != null) {
          totalHours += record.totalHours!;
        }
      }
    }

    final onTimePercentage = daysPresent > 0 
        ? ((daysPresent - lateDays) / daysPresent * 100).round()
        : 0;

    return {
      'daysPresent': daysPresent,
      'lateDays': lateDays,
      'totalHours': totalHours.toStringAsFixed(1),
      'onTimePercentage': onTimePercentage,
    };
  }

  List<AttendanceRecord> getRecentAttendance({int limit = 5}) {
    final sortedRecords = List<AttendanceRecord>.from(_attendanceRecords);
    sortedRecords.sort((a, b) => b.date.compareTo(a.date));
    
    return sortedRecords.take(limit).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearData() {
    _attendanceRecords.clear();
    _todayAttendance = null;
    _currentPosition = null;
    _clearError();
    notifyListeners();
  }
}
