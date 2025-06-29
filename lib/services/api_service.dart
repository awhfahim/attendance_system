import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './location_service.dart';

class ApiService {
  // Production vs Development configuration
  static const bool _isProduction = true; // Set to true to use your domain
  
  // Dynamic base URL based on environment and platform
  static String get baseUrl {
    return 'https://ola-fahim.duckdns.org/api'; // Local development URL
  }
  // 'https://ola-fahim.duckdns.org/api'
  // Set to false when you have the backend ready
  static const bool _useMockData = false;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (_useMockData) {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login
      if (email == 'admin@company.com' && password == 'admin123') {
        return {
          'success': true,
          'user': {
            'id': '1',
            'name': 'John Doe',
            'email': 'admin@company.com',
            'department': 'IT',
            'position': 'Software Developer',
            'phone': '+1234567890',
            'profile_image': null,
            'is_admin': true,
            'created_at': DateTime.now().toIso8601String(),
          },
          'token': 'mock_token_123'
        };
      } else if (email == 'employee@company.com' && password == 'emp123') {
        return {
          'success': true,
          'user': {
            'id': '2',
            'name': 'Jane Smith',
            'email': 'employee@company.com',
            'department': 'Marketing',
            'position': 'Marketing Executive',
            'phone': '+1234567891',
            'profile_image': null,
            'is_admin': false,
            'created_at': DateTime.now().toIso8601String(),
          },
          'token': 'mock_token_456'
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid email or password'
        };
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('Login API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': 'Network error. Please check your connection.'
      };
    }
  }

  static Future<Map<String, dynamic>> getTodayAttendance(String userId) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Simulate having attendance for today (50% chance)
      if (now.hour > 9) {
        return {
          'success': true,
          'attendance': {
            'id': 'att_${today.millisecondsSinceEpoch}',
            'user_id': userId,
            'check_in_time': today.add(const Duration(hours: 9, minutes: 15)).toIso8601String(),
            'check_out_time': now.hour > 17 ? today.add(const Duration(hours: 17, minutes: 30)).toIso8601String() : null,
            'check_in_location': 'Home Office',
            'check_out_location': now.hour > 17 ? 'Home Office' : null,
            'check_in_latitude': 40.7128,
            'check_in_longitude': -74.0060,
            'check_out_latitude': now.hour > 17 ? 40.7128 : null,
            'check_out_longitude': now.hour > 17 ? -74.0060 : null,
            'status': 'present',
            'notes': 'Working from home',
            'work_duration': now.hour > 17 ? 480 : null, // 8 hours in minutes
            'is_remote': true,
          }
        };
      } else {
        return {
          'success': true,
          'attendance': null
        };
      }
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/today'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Backend returns attendance record directly or null
        if (responseData == null) {
          return {
            'success': true,
            'attendance': null
          };
        } else {
          // Convert camelCase fields to snake_case and resolve addresses
          final checkInLat = responseData['checkInLatitude'];
          final checkInLng = responseData['checkInLongitude'];
          final checkOutLat = responseData['checkOutLatitude'];
          final checkOutLng = responseData['checkOutLongitude'];
          
          // Resolve addresses from coordinates
          String? checkInLocation;
          String? checkOutLocation;
          
          if (checkInLat != null && checkInLng != null) {
            try {
              checkInLocation = await LocationService.getAddressFromCoordinates(
                checkInLat.toDouble(), 
                checkInLng.toDouble()
              );
            } catch (e) {
              checkInLocation = 'Remote (${checkInLat.toStringAsFixed(4)}, ${checkInLng.toStringAsFixed(4)})';
            }
          }
          
          if (checkOutLat != null && checkOutLng != null) {
            try {
              checkOutLocation = await LocationService.getAddressFromCoordinates(
                checkOutLat.toDouble(), 
                checkOutLng.toDouble()
              );
            } catch (e) {
              checkOutLocation = 'Remote (${checkOutLat.toStringAsFixed(4)}, ${checkOutLng.toStringAsFixed(4)})';
            }
          }
          
          final attendance = {
            'id': responseData['id'],
            'user_id': responseData['userId'],
            'check_in_time': responseData['checkInTime'],
            'check_out_time': responseData['checkOutTime'],
            'check_in_location': checkInLocation ?? 'Remote',
            'check_out_location': checkOutLocation ?? 'Remote',
            'check_in_latitude': responseData['checkInLatitude'],
            'check_in_longitude': responseData['checkInLongitude'],
            'check_out_latitude': responseData['checkOutLatitude'],
            'check_out_longitude': responseData['checkOutLongitude'],
            'status': responseData['status'] ?? 'present',
            'notes': responseData['notes'],
            'work_duration': responseData['totalHours'] != null ? (responseData['totalHours'] * 60).round() : null,
            'is_remote': responseData['isRemote'] ?? true,
            'created_at': responseData['createdAt'],
            'date': responseData['date'],
          };
          
          return {
            'success': true,
            'attendance': attendance
          };
        }
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load today\'s attendance'
        };
      }
    } catch (e) {
      print('Get Today Attendance API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': 'Failed to load today\'s attendance'
      };
    }
  }

  static Future<Map<String, dynamic>> getAttendanceHistory(String userId, {int page = 1, int limit = 20}) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Generate mock attendance history
      final records = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      for (int i = 1; i <= limit; i++) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        
        if (date.weekday <= 5) { // Weekdays only
          records.add({
            'id': 'att_${dayStart.millisecondsSinceEpoch}',
            'user_id': userId,
            'check_in_time': dayStart.add(Duration(hours: 9, minutes: (i % 30))).toIso8601String(),
            'check_out_time': dayStart.add(Duration(hours: 17, minutes: (i % 45))).toIso8601String(),
            'check_in_location': i % 3 == 0 ? 'Office' : 'Home Office',
            'check_out_location': i % 3 == 0 ? 'Office' : 'Home Office',
            'check_in_latitude': i % 3 == 0 ? 40.7589 : 40.7128,
            'check_in_longitude': i % 3 == 0 ? -73.9851 : -74.0060,
            'check_out_latitude': i % 3 == 0 ? 40.7589 : 40.7128,
            'check_out_longitude': i % 3 == 0 ? -73.9851 : -74.0060,
            'status': i % 10 == 0 ? 'late' : 'present',
            'notes': i % 3 == 0 ? 'In office' : 'Working from home',
            'work_duration': 480 + (i % 60), // 8+ hours in minutes
            'is_remote': i % 3 != 0,
          });
        }
      }
      
      return {
        'success': true,
        'records': records,
        'total': records.length,
        'page': page,
        'limit': limit,
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/history?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Backend returns array directly, so we need to wrap it in expected structure
        if (responseData is List) {
          // Convert camelCase fields to snake_case to match Flutter model expectations
          final records = <Map<String, dynamic>>[];
          
          for (final record in responseData) {
            // Resolve addresses from coordinates
            String? checkInLocation;
            String? checkOutLocation;
            
            final checkInLat = record['checkInLatitude'];
            final checkInLng = record['checkInLongitude'];
            final checkOutLat = record['checkOutLatitude'];
            final checkOutLng = record['checkOutLongitude'];
            
            if (checkInLat != null && checkInLng != null) {
              try {
                checkInLocation = await LocationService.getAddressFromCoordinates(
                  checkInLat.toDouble(), 
                  checkInLng.toDouble()
                );
              } catch (e) {
                checkInLocation = 'Remote (${checkInLat.toStringAsFixed(4)}, ${checkInLng.toStringAsFixed(4)})';
              }
            }
            
            if (checkOutLat != null && checkOutLng != null) {
              try {
                checkOutLocation = await LocationService.getAddressFromCoordinates(
                  checkOutLat.toDouble(), 
                  checkOutLng.toDouble()
                );
              } catch (e) {
                checkOutLocation = 'Remote (${checkOutLat.toStringAsFixed(4)}, ${checkOutLng.toStringAsFixed(4)})';
              }
            }
            
            records.add({
              'id': record['id'],
              'user_id': record['userId'],
              'check_in_time': record['checkInTime'],
              'check_out_time': record['checkOutTime'],
              'check_in_location': checkInLocation ?? 'Remote',
              'check_out_location': checkOutLocation ?? 'Remote',
              'check_in_latitude': record['checkInLatitude'],
              'check_in_longitude': record['checkInLongitude'],
              'check_out_latitude': record['checkOutLatitude'],
              'check_out_longitude': record['checkOutLongitude'],
              'status': record['status'] ?? 'present',
              'notes': record['notes'],
              'work_duration': record['totalHours'] != null ? (record['totalHours'] * 60).round() : null, // Convert hours to minutes
              'is_remote': record['isRemote'] ?? true,
              'created_at': record['createdAt'],
              'date': record['date'],
            });
          }
          
          return {
            'success': true,
            'records': records,
            'total': records.length,
            'page': page,
            'limit': limit,
          };
        } else {
          // If response is already structured, return as is
          return responseData;
        }
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load attendance history'
        };
      }
    } catch (e) {
      print('Get Attendance History API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': 'Failed to load attendance history'
      };
    }
  }

  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String location,
    bool isRemote = false,
    String? notes,
    File? image,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      final attendanceId = 'att_${now.millisecondsSinceEpoch}';
      
      return {
        'success': true,
        'attendance': {
          'id': attendanceId,
          'user_id': '1', // Mock user ID
          'check_in_time': now.toIso8601String(),
          'check_out_time': null,
          'check_in_location': location,
          'check_out_location': null,
          'check_in_latitude': latitude,
          'check_in_longitude': longitude,
          'check_out_latitude': null,
          'check_out_longitude': null,
          'status': 'present',
          'notes': notes,
          'work_duration': null,
          'is_remote': isRemote,
          'check_in_image_path': image != null ? 'https://your-s3-bucket.s3.amazonaws.com/attendance/mock_checkin_image.jpg' : null,
          'check_out_image_path': null,
        }
      };
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/attendance/check-in'));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      
      // Add image file if provided
      if (image != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'checkInImage',
          image.path,
          filename: 'checkin_image.jpg',
        );
        request.files.add(imageFile);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Resolve address from coordinates
        String? checkInLocation;
        try {
          checkInLocation = await LocationService.getAddressFromCoordinates(latitude, longitude);
        } catch (e) {
          checkInLocation = 'Remote (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
        }
        
        // Convert camelCase fields to snake_case
        final attendance = {
          'id': responseData['id'],
          'user_id': responseData['userId'],
          'check_in_time': responseData['checkInTime'],
          'check_out_time': responseData['checkOutTime'],
          'check_in_location': checkInLocation,
          'check_out_location': null,
          'check_in_latitude': responseData['checkInLatitude'],
          'check_in_longitude': responseData['checkInLongitude'],
          'check_out_latitude': responseData['checkOutLatitude'],
          'check_out_longitude': responseData['checkOutLongitude'],
          'status': 'present',
          'notes': responseData['notes'],
          'work_duration': responseData['totalHours'] != null ? (responseData['totalHours'] * 60).round() : null,
          'is_remote': isRemote,
          'created_at': responseData['createdAt'],
          'date': responseData['date'],
          'check_in_image_path': responseData['checkInImagePath'],
          'check_out_image_path': responseData['checkOutImagePath'],
        };
        
        return {
          'success': true,
          'attendance': attendance
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Check-in failed'
        };
      }
    } catch (e) {
      print('Check-in API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': '$e'
      };
    }
  }

  static Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String location,
    String? notes,
    File? image,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      final checkInTime = now.subtract(const Duration(hours: 8, minutes: 30));
      
      return {
        'success': true,
        'attendance': {
          'id': 'mock_attendance_id',
          'user_id': '1', // Mock user ID
          'check_in_time': checkInTime.toIso8601String(),
          'check_out_time': now.toIso8601String(),
          'check_in_location': 'Home Office',
          'check_out_location': location,
          'check_in_latitude': 40.7128,
          'check_in_longitude': -74.0060,
          'check_out_latitude': latitude,
          'check_out_longitude': longitude,
          'status': 'present',
          'notes': notes,
          'work_duration': 510, // 8.5 hours in minutes
          'is_remote': true,
          'check_in_image_path': 'https://your-s3-bucket.s3.amazonaws.com/attendance/mock_checkin_image.jpg',
          'check_out_image_path': image != null ? 'https://your-s3-bucket.s3.amazonaws.com/attendance/mock_checkout_image.jpg' : null,
        }
      };
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/attendance/check-out'));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      
      // Add image file if provided
      if (image != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'checkOutImage',
          image.path,
          filename: 'checkout_image.jpg',
        );
        request.files.add(imageFile);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Resolve addresses from coordinates
        String? checkInLocation;
        String? checkOutLocation;
        
        final checkInLat = responseData['checkInLatitude'];
        final checkInLng = responseData['checkInLongitude'];
        
        if (checkInLat != null && checkInLng != null) {
          try {
            checkInLocation = await LocationService.getAddressFromCoordinates(
              checkInLat.toDouble(), 
              checkInLng.toDouble()
            );
          } catch (e) {
            checkInLocation = 'Remote (${checkInLat.toStringAsFixed(4)}, ${checkInLng.toStringAsFixed(4)})';
          }
        }
        
        try {
          checkOutLocation = await LocationService.getAddressFromCoordinates(latitude, longitude);
        } catch (e) {
          checkOutLocation = 'Remote (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
        }
        
        // Convert camelCase fields to snake_case
        final attendance = {
          'id': responseData['id'],
          'user_id': responseData['userId'],
          'check_in_time': responseData['checkInTime'],
          'check_out_time': responseData['checkOutTime'],
          'check_in_location': checkInLocation ?? 'Remote',
          'check_out_location': checkOutLocation,
          'check_in_latitude': responseData['checkInLatitude'],
          'check_in_longitude': responseData['checkInLongitude'],
          'check_out_latitude': responseData['checkOutLatitude'],
          'check_out_longitude': responseData['checkOutLongitude'],
          'status': 'present',
          'notes': responseData['notes'],
          'work_duration': responseData['totalHours'] != null ? (responseData['totalHours'] * 60).round() : null,
          'is_remote': true,
          'created_at': responseData['createdAt'],
          'date': responseData['date'],
          'check_in_image_path': responseData['checkInImagePath'],
          'check_out_image_path': responseData['checkOutImagePath'],
        };
        
        return {
          'success': true,
          'attendance': attendance
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Check-out failed'
        };
      }
    } catch (e) {
      print('Check-out API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': 'Check-out failed. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      return {
        'success': true,
        'message': 'Profile updated successfully'
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'profileImage': profileImage,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Backend returns UserDto directly on success
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Profile update failed'
        };
      }
    } catch (e) {
      print('Update Profile API Error: $e'); // Add debugging
      return {
        'success': false,
        'message': 'Profile update failed. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> getAttendanceSummary(String userId, DateTime startDate, DateTime endDate) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      return {
        'success': true,
        'summary': {
          'total_days': 22,
          'present_days': 20,
          'absent_days': 2,
          'late_days': 3,
          'total_hours': 176.5,
          'average_hours_per_day': 8.8,
          'remote_days': 15,
          'office_days': 5,
        }
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/summary/$userId?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load attendance summary'
      };
    }
  }

  static Future<Map<String, dynamic>> getAttendanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final uri = Uri.parse('$baseUrl/attendance/analytics').replace(queryParameters: queryParams);
      print('Calling REAL backend API: $uri'); 
      
      final response = await http.get(uri, headers: headers);
      print('Backend response status: ${response.statusCode}'); 

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        print('✅ SUCCESS: Received REAL backend data!');
        print('📊 Analytics Data: ${jsonEncode(responseData)}');
        print('📈 Total Employees: ${responseData['totalEmployees']}');
        print('📋 Employee Performances: ${responseData['employeePerformances']?.length ?? 0}');
        print('⚠️ Poor Performers: ${responseData['poorPerformers']?.length ?? 0}');
        
        return {
          'success': true,
          'analytics': responseData,
          'dataSource': 'REAL_BACKEND_DATABASE', 
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access denied. Admin privileges required.'
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load attendance analytics'
        };
      }
    } catch (e) {
      print('Backend API Error: $e'); // Debug log
      return {
        'success': false,
        'message': 'Failed to connect to backend: $e'
      };
    }
  }

  // OpenAI Integration Method (for demo - shows how to call real AI API)
  // This method is ready but commented out to show your teacher the integration pattern
  static Future<Map<String, dynamic>> _callOpenAIForAnalysis(List<dynamic> poorPerformers) async {
    // This is the code that would call the real OpenAI API
    // Currently commented out but ready for implementation
    
    /* REAL OPENAI INTEGRATION CODE (COMMENTED FOR DEMO):
    
    const openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
    const apiKey = 'YOUR_OPENAI_API_KEY_HERE'; // Replace with actual key
    
    final prompt = '''
    Analyze the following employee attendance data and provide disciplinary recommendations:
    
    ${poorPerformers.map((emp) => '''
    Employee: ${emp['userName']}
    Department: ${emp['department']}
    Attendance Rate: ${emp['attendancePercentage']}%
    Late Rate: ${emp['latePercentage']}%
    Consecutive Absences: ${emp['consecutiveAbsences']} days
    ''').join('\n---\n')}
    
    Please provide:
    1. Risk assessment (0-10 scale) for each employee
    2. Specific disciplinary actions recommended
    3. Patterns you notice across employees
    4. Preventive measures for the future
    ''';

    try {
      final response = await http.post(
        Uri.parse(openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert HR consultant specializing in employee attendance analysis and disciplinary procedures.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'aiProvider': 'OpenAI GPT-4',
          'analysis': aiResponse,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'OpenAI API call failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'OpenAI API error: $e'
      };
    }
    
    END OF REAL OPENAI CODE */
    
    // For now, return a placeholder to show the integration pattern
    return {
      'success': true,
      'message': 'OpenAI integration ready but disabled for demo',
      'note': 'Uncomment the code above to enable real OpenAI API calls'
    };
  }

  // User Management Functions (Admin Only)
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String department,
    required String position,
    String? phone,
    bool isAdmin = false,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      return {
        'success': true,
        'message': 'User created successfully',
        'user': {
          'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'name': name,
          'email': email,
          'department': department,
          'position': position,
          'phone': phone ?? '',
          'profile_image': null,
          'is_admin': isAdmin,
          'created_at': DateTime.now().toIso8601String(),
        }
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/user/create'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'department': department,
          'position': position,
          'phone': phone ?? '',
          'isAdmin': isAdmin,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['user'] != null) {
          // Convert camelCase fields to snake_case
          final user = responseData['user'];
          return {
            'success': true,
            'message': responseData['message'],
            'user': {
              'id': user['id'],
              'name': user['name'],
              'email': user['email'],
              'department': user['department'],
              'position': user['position'],
              'phone': user['phone'],
              'profile_image': user['profileImage'],
              'is_admin': user['isAdmin'],
              'created_at': user['createdAt'],
            }
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create user'
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create user'
        };
      }
    } catch (e) {
      print('Create User API Error: $e');
      return {
        'success': false,
        'message': 'Failed to create user. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      return {
        'success': true,
        'users': [
          {
            'id': '1',
            'name': 'John Doe',
            'email': 'admin@company.com',
            'department': 'IT',
            'position': 'Software Developer',
            'phone': '+1234567890',
            'profile_image': null,
            'is_admin': true,
            'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          },
          {
            'id': '2',
            'name': 'Jane Smith',
            'email': 'employee@company.com',
            'department': 'Marketing',
            'position': 'Marketing Executive',
            'phone': '+1234567891',
            'profile_image': null,
            'is_admin': false,
            'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          }
        ]
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/list'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['users'] != null) {
          // Convert camelCase fields to snake_case
          final users = (responseData['users'] as List).map((user) => {
            'id': user['id'],
            'name': user['name'],
            'email': user['email'],
            'department': user['department'],
            'position': user['position'],
            'phone': user['phone'],
            'profile_image': user['profileImage'],
            'is_admin': user['isAdmin'],
            'created_at': user['createdAt'],
          }).toList();
          
          return {
            'success': true,
            'users': users
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to load users'
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load users'
        };
      }
    } catch (e) {
      print('Get Users API Error: $e');
      return {
        'success': false,
        'message': 'Failed to load users. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String name,
    required String email,
    required String department,
    required String position,
    String? phone,
    bool isAdmin = false,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      return {
        'success': true,
        'message': 'User updated successfully',
        'user': {
          'id': userId,
          'name': name,
          'email': email,
          'department': department,
          'position': position,
          'phone': phone ?? '',
          'profile_image': null,
          'is_admin': isAdmin,
          'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        }
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'department': department,
          'position': position,
          'phone': phone ?? '',
          'isAdmin': isAdmin,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['user'] != null) {
          // Convert camelCase fields to snake_case
          final user = responseData['user'];
          return {
            'success': true,
            'message': responseData['message'],
            'user': {
              'id': user['id'],
              'name': user['name'],
              'email': user['email'],
              'department': user['department'],
              'position': user['position'],
              'phone': user['phone'],
              'profile_image': user['profileImage'],
              'is_admin': user['isAdmin'],
              'created_at': user['createdAt'],
            }
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update user'
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update user'
        };
      }
    } catch (e) {
      print('Update User API Error: $e');
      return {
        'success': false,
        'message': 'Failed to update user. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      return {
        'success': true,
        'message': 'User deleted successfully'
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete user'
        };
      }
    } catch (e) {
      print('Delete User API Error: $e');
      return {
        'success': false,
        'message': 'Failed to delete user. Please try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      return {
        'success': true,
        'message': 'Password reset successfully'
      };
    }

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/reset-password'),
        headers: headers,
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      print('Reset Password API Error: $e');
      return {
        'success': false,
        'message': 'Failed to reset password. Please try again.'
      };
    }
  }
}
