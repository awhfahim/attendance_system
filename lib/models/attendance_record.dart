class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String status; // 'present', 'late', 'absent', 'on_leave'
  final String? notes;
  final Duration? workDuration;
  final bool isRemote;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.status,
    this.notes,
    this.workDuration,
    this.isRemote = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      userId: json['user_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      checkInLocation: json['check_in_location'],
      checkOutLocation: json['check_out_location'],
      checkInLatitude: json['check_in_latitude']?.toDouble(),
      checkInLongitude: json['check_in_longitude']?.toDouble(),
      checkOutLatitude: json['check_out_latitude']?.toDouble(),
      checkOutLongitude: json['check_out_longitude']?.toDouble(),
      status: json['status'],
      notes: json['notes'],
      workDuration: json['work_duration'] != null 
          ? Duration(minutes: json['work_duration']) 
          : null,
      isRemote: json['is_remote'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'status': status,
      'notes': notes,
      'work_duration': workDuration?.inMinutes,
      'is_remote': isRemote,
    };
  }

  Duration get totalWorkTime {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return Duration.zero;
  }

  bool get isCheckedOut => checkOutTime != null;

  String get formattedWorkDuration {
    final duration = totalWorkTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Add date getter based on checkInTime
  DateTime get date => DateTime(checkInTime.year, checkInTime.month, checkInTime.day);

  // Add totalHours getter for compatibility
  double? get totalHours {
    if (checkOutTime != null) {
      return totalWorkTime.inMinutes / 60.0;
    }
    return null;
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? status,
    String? notes,
    Duration? workDuration,
    bool? isRemote,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      workDuration: workDuration ?? this.workDuration,
      isRemote: isRemote ?? this.isRemote,
    );
  }
}
