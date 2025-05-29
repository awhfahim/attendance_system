import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.login(email, password);
      if (response['success']) {
        // Convert backend camelCase to frontend snake_case
        final userData = Map<String, dynamic>.from(response['user']);
        userData['profile_image'] = userData['profileImage'];
        userData['is_admin'] = userData['isAdmin'];
        userData['created_at'] = userData['createdAt'];
        
        _user = User.fromJson(userData);
        
        // Save the JWT token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        debugPrint('Auth token saved: ${response['token'].substring(0, 20)}...');
        
        await _saveUserData();
        debugPrint('User logged in: ${_user!.name} (${_user!.email})');
        notifyListeners();
      } else {
        _setError(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _setError('Network error. Please check your connection.');
    }

    _setLoading(false);
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await _clearUserData();
    debugPrint('User logged out and data cleared');
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken != null && authToken.isNotEmpty) {
        // Try to reconstruct user data from saved preferences
        final userId = prefs.getString('user_id');
        final userName = prefs.getString('user_name');
        final userEmail = prefs.getString('user_email');
        
        if (userId != null && userName != null && userEmail != null) {
          final userData = User.fromJson({
            'id': userId,
            'name': userName,
            'email': userEmail,
            'department': prefs.getString('user_department') ?? '',
            'position': prefs.getString('user_position') ?? '',
            'phone': prefs.getString('user_phone') ?? '',
            'profile_image': prefs.getString('user_profile_image'),
            'is_admin': prefs.getBool('user_is_admin') ?? false,
            'created_at': prefs.getString('user_created_at') ?? DateTime.now().toIso8601String(),
          });
          _user = userData;
          debugPrint('Auth status: User restored from storage - ${userData.name}');
        } else {
          debugPrint('Auth status: Token exists but user data incomplete, clearing auth');
          await logout(); // Clear incomplete data
        }
      } else {
        debugPrint('Auth status: No token found, user not authenticated');
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // Clear any corrupted data
      await logout();
    }

    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.updateProfile(
        name: name,
        phone: phone,
        profileImage: profileImage,
      );

      if (response['success']) {
        _user = _user!.copyWith(
          name: name ?? _user!.name,
          phone: phone ?? _user!.phone,
          profileImage: profileImage ?? _user!.profileImage,
        );
        await _saveUserData();
        notifyListeners();
      } else {
        _setError(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      _setError('Network error. Please try again.');
    }

    _setLoading(false);
  }

  Future<void> _saveUserData() async {
    if (_user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _user!.id);
    await prefs.setString('user_name', _user!.name);
    await prefs.setString('user_email', _user!.email);
    await prefs.setString('user_department', _user!.department);
    await prefs.setString('user_position', _user!.position);
    await prefs.setString('user_phone', _user!.phone);
    await prefs.setString('user_profile_image', _user!.profileImage ?? '');
    await prefs.setBool('user_is_admin', _user!.isAdmin);
    await prefs.setString('user_created_at', _user!.createdAt.toIso8601String());
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_department');
    await prefs.remove('user_position');
    await prefs.remove('user_phone');
    await prefs.remove('user_profile_image');
    await prefs.remove('user_is_admin');
    await prefs.remove('user_created_at');
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
}
