import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 20),
                _buildProfileInfo(user),
                const SizedBox(height: 20),
                _buildSettingsSection(),
                const SizedBox(height: 20),
                _buildLogoutSection(authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                child: user.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.position,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.department,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.email, 'Email', user.email),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'Phone', user.phone),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.business, 'Department', user.department),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.work, 'Position', user.position),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.admin_panel_settings,
                'Role',
                user.isAdmin ? 'Administrator' : 'Employee',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (user?.isAdmin == true) ...[
              _buildSettingsTile(
                Icons.analytics,
                'Attendance Analytics',
                'View employee performance reports',
                () {
                  _showAttendanceAnalytics();
                },
              ),
              const Divider(height: 1),
            ],
            _buildSettingsTile(
              Icons.info,
              'About',
              'App version and information',
              () {
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutSection(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.logout,
            color: AppColors.error,
          ),
          title: Text(
            'Logout',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
          subtitle: Text(
            'Sign out of your account',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onTap: () => _showLogoutDialog(authProvider),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Attendance System',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.access_time,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text('A comprehensive attendance tracking system for remote and office employees.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• GPS-based attendance tracking'),
        const Text('• Remote work support'),
        const Text('• Real-time notifications'),
        const Text('• Detailed attendance reports'),
      ],
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Position and Department can only be changed by administrators.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                phoneController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name is required'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Update profile via API
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.updateProfile(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  profileImage: null, // We'll implement image upload later
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                
                nameController.dispose();
                phoneController.dispose();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAttendanceAnalytics() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading attendance analytics...'),
              SizedBox(height: 10),
              Text(
                'Calling AI model for intelligent analysis...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Get analytics data for the last 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      print('🔍 Requesting analytics from backend...');
      final response = await ApiService.getAttendanceAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      print('📥 Analytics Response: ${jsonEncode(response)}');

      if (response['success']) {
        final analytics = response['analytics'];
        final poorPerformers = List<Map<String, dynamic>>.from(analytics['poorPerformers'] ?? []);
        
        print('📊 Analytics received - Total Employees: ${analytics['totalEmployees']}');
        print('⚠️ Poor Performers: ${poorPerformers.length}');
        
        // Call AI service for intelligent analysis using REAL backend data
        Map<String, dynamic>? aiAnalysis;
        final employeePerformances = List<Map<String, dynamic>>.from(analytics['employeePerformances'] ?? []);
        
        if (employeePerformances.isNotEmpty) {
          print('🤖 Calling AI service with ${employeePerformances.length} employees...');
          aiAnalysis = await AIService.analyzeAttendanceWithAI(employeePerformances);
        } else {
          print('⚠️ No employee performance data to analyze');
        }
        
        Navigator.of(context).pop(); // Close loading dialog
        _showAnalyticsResults(analytics, poorPerformers, aiAnalysis);
      } else {
        print('❌ Analytics API failed: ${response['message']}');
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(response['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error loading analytics: $e');
    }
  }

  void _showAnalyticsResults(Map<String, dynamic> analytics, List<Map<String, dynamic>> poorPerformers, Map<String, dynamic>? aiAnalysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Attendance Analytics'),
              if (aiAnalysis != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'AI Enhanced',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Period: ${DateTime.parse(analytics['startDate']).toLocal().toString().split(' ')[0]} to ${DateTime.parse(analytics['endDate']).toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Total Employees: ${analytics['totalEmployees']}'),
                  Text('Average Attendance Rate: ${analytics['averageAttendanceRate']}%'),
                  Text('Average Late Rate: ${analytics['averageLateRate']}%'),
                  
                  // AI Summary section
                  if (aiAnalysis != null && aiAnalysis['success']) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.purple.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'AI Analysis Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aiAnalysis['summary'] ?? 'No summary available',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Overall Risk Score: ${aiAnalysis['overallRiskScore']}/10'),
                          Text('AI Provider: ${aiAnalysis['aiProvider']}'),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  const Text(
                    'EMPLOYEES REQUIRING DISCIPLINARY ACTION:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  if (poorPerformers.isEmpty)
                    const Text(
                      'No employees currently require disciplinary action.',
                      style: TextStyle(color: Colors.green),
                    )
                  else
                    ...poorPerformers.map((employee) => _buildEmployeeCard(employee, aiAnalysis)).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (poorPerformers.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDetailedReport(poorPerformers, aiAnalysis);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View AI Report'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, Map<String, dynamic>? aiAnalysis) {
    final attendanceRate = employee['attendancePercentage'] ?? 0.0;
    final lateRate = employee['latePercentage'] ?? 0.0;
    final absenceRate = employee['absencePercentage'] ?? 0.0;
    final consecutiveAbsences = employee['consecutiveAbsences'] ?? 0;
    
    // Find AI recommendation for this employee
    Map<String, dynamic>? aiRecommendation;
    if (aiAnalysis != null && aiAnalysis['success'] == true) {
      final recommendations = List<Map<String, dynamic>>.from(aiAnalysis['recommendations'] ?? []);
      aiRecommendation = recommendations.firstWhere(
        (rec) => rec['employeeName'] == employee['userName'],
        orElse: () => <String, dynamic>{},
      );
    }
    
    Color cardColor = Colors.red.shade50;
    if (employee['performanceCategory'] == 'Critical') {
      cardColor = Colors.red.shade100;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    employee['userName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (aiRecommendation != null && aiRecommendation.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology, size: 12, color: Colors.purple.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'AI: ${aiRecommendation['riskScore']}/10',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Text('${employee['position']} - ${employee['department']}'),
            const SizedBox(height: 8),
            Text('Attendance: ${attendanceRate.toStringAsFixed(1)}%'),
            Text('Late Rate: ${lateRate.toStringAsFixed(1)}%'),
            Text('Absence Rate: ${absenceRate.toStringAsFixed(1)}%'),
            if (consecutiveAbsences > 0)
              Text(
                'Consecutive Absences: $consecutiveAbsences days',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            Text(
              'Category: ${employee['performanceCategory']}',
              style: TextStyle(
                color: employee['performanceCategory'] == 'Critical' ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            // AI Recommendation preview
            if (aiRecommendation != null && aiRecommendation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, size: 14, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'AI Recommendation:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aiRecommendation['recommendedAction']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailedReport(List<Map<String, dynamic>> poorPerformers, Map<String, dynamic>? aiAnalysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('AI-Enhanced Disciplinary Report'),
              const SizedBox(width: 8),
              Icon(Icons.psychology, color: Colors.purple.shade700),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Analysis Header
                  if (aiAnalysis != null && aiAnalysis['success'] == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade50, Colors.purple.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.smart_toy, color: Colors.purple.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'AI ANALYSIS REPORT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Provider: ${aiAnalysis['aiProvider']}'),
                          Text('Analysis Date: ${DateTime.parse(aiAnalysis['analysisTimestamp']).toLocal().toString().split('.')[0]}'),
                          Text('Overall Risk Score: ${aiAnalysis['overallRiskScore']}/10'),
                          Text('Next Review: ${DateTime.parse(aiAnalysis['nextReviewDate']).toLocal().toString().split(' ')[0]}'),
                          const SizedBox(height: 12),
                          Text(
                            aiAnalysis['summary'] ?? 'No summary available',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  const Text(
                    'RECOMMENDATION FOR DISCIPLINARY ACTION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // AI Patterns and Insights
                  if (aiAnalysis != null && aiAnalysis['success'] == true) ...[
                    if (aiAnalysis['patternsDetected'] != null && (aiAnalysis['patternsDetected'] as List).isNotEmpty) ...[
                      const Text(
                        'AI-DETECTED PATTERNS:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((aiAnalysis['patternsDetected'] as List).map((pattern) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.pattern, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(child: Text('$pattern')),
                            ],
                          ),
                        )
                      )).toList(),
                      const SizedBox(height: 16),
                    ],
                    
                    if (aiAnalysis['insights'] != null && (aiAnalysis['insights'] as List).isNotEmpty) ...[
                      const Text(
                        'AI INSIGHTS:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((aiAnalysis['insights'] as List).map((insight) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(child: Text('$insight')),
                            ],
                          ),
                        )
                      )).toList(),
                      const SizedBox(height: 16),
                    ],
                  ],
                  
                  const Text(
                    'The following employees have been identified as having poor attendance records that warrant disciplinary action:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  ...poorPerformers.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final employee = entry.value;
                    return _buildDetailedEmployeeReport(index, employee, aiAnalysis);
                  }).toList(),
                  
                  const SizedBox(height: 20),
                  const Text(
                    'AI-RECOMMENDED ACTIONS:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // AI-powered recommendations
                  if (aiAnalysis != null && aiAnalysis['success'] == true && aiAnalysis['recommendations'] != null) ...[
                    ...((aiAnalysis['recommendations'] as List).map((rec) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${rec['employeeName']} (Risk: ${rec['riskScore']}/10)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recommended Action: ${rec['recommendedAction']?.toString().replaceAll('_', ' ').toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rec['severity'] == 'critical' ? Colors.red : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AI Reasoning: ${rec['aiReasoning']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Suggested Message: "${rec['personalizedMessage']}"',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      )
                    )).toList(),
                  ] else ...[
                    // Fallback to basic recommendations
                    ...poorPerformers.map((employee) {
                      final category = employee['performanceCategory'];
                      final name = employee['userName'];
                      
                      if (category == 'Critical') {
                        return Text('• $name: Consider immediate termination or final warning');
                      } else {
                        return Text('• $name: Issue written warning and performance improvement plan');
                      }
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (aiAnalysis != null && aiAnalysis['success'] == true)
              ElevatedButton(
                onPressed: () {
                  // In a real app, this could export the report or send it via email
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Report would be exported/sent to HR department'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Export AI Report'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedEmployeeReport(int index, Map<String, dynamic> employee, Map<String, dynamic>? aiAnalysis) {
    final reasons = <String>[];
    
    if ((employee['attendancePercentage'] ?? 0) < 80) {
      reasons.add('Low attendance rate (${(employee['attendancePercentage'] ?? 0).toStringAsFixed(1)}%)');
    }
    if ((employee['latePercentage'] ?? 0) > 30) {
      reasons.add('Excessive tardiness (${(employee['latePercentage'] ?? 0).toStringAsFixed(1)}% of days)');
    }
    if ((employee['absencePercentage'] ?? 0) > 20) {
      reasons.add('High absence rate (${(employee['absencePercentage'] ?? 0).toStringAsFixed(1)}%)');
    }
    if ((employee['consecutiveAbsences'] ?? 0) > 3) {
      reasons.add('${employee['consecutiveAbsences']} consecutive days absent');
    }
    
    // Find AI recommendation for this employee
    Map<String, dynamic>? aiRecommendation;
    if (aiAnalysis != null && aiAnalysis['success'] == true) {
      final recommendations = List<Map<String, dynamic>>.from(aiAnalysis['recommendations'] ?? []);
      aiRecommendation = recommendations.firstWhere(
        (rec) => rec['employeeName'] == employee['userName'],
        orElse: () => <String, dynamic>{},
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index. ${employee['userName']} (${employee['email']})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (aiRecommendation != null && aiRecommendation.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'AI Risk: ${aiRecommendation['riskScore']}/10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text('Position: ${employee['position']}'),
          Text('Department: ${employee['department']}'),
          const SizedBox(height: 8),
          const Text(
            'Violations:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...reasons.map((reason) => Text('  • $reason')).toList(),
          const SizedBox(height: 8),
          Text(
            'Performance Category: ${employee['performanceCategory']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: employee['performanceCategory'] == 'Critical' ? Colors.red : Colors.orange,
            ),
          ),
          
          // AI-specific insights
          if (aiRecommendation != null && aiRecommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Severity: ${aiRecommendation['severity']?.toString().toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: aiRecommendation['severity'] == 'critical' ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended Action: ${aiRecommendation['recommendedAction']?.toString().replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Reasoning: ${aiRecommendation['aiReasoning']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Suggested Communication:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '"${aiRecommendation['personalizedMessage']}"',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
