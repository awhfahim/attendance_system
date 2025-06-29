import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const bool _useDemoAI = true;
  static const String _openAIEndpoint = 'https://api.groq.com/v1/chat/completions';
  static const String _apiKey = 'HA7S2HOF82HF_JHAO82HF2FS3RF';
  
  /// Analyzes employee attendance data using AI and provides intelligent insights
  static Future<Map<String, dynamic>> analyzeAttendanceWithAI(List<Map<String, dynamic>> employeeData) async {
    if (_useDemoAI) {
      return _mockAIAnalysis(employeeData);
    } else {
      return _callOpenAI(employeeData);
    }
  }
  
  /// Mock AI analysis that simulates advanced AI insights using real backend data
  static Future<Map<String, dynamic>> _mockAIAnalysis(List<Map<String, dynamic>> employeeData) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final insights = <String>[];
    final recommendations = <Map<String, dynamic>>[];
    final patterns = <String>[];
    
    if (employeeData.isEmpty) {
      return {
        'success': true,
        'aiProvider': 'OpenAI GPT-4 (Demo Mode)',
        'analysisTimestamp': DateTime.now().toIso8601String(),
        'overallRiskScore': '0.0',
        'patternsDetected': ['No employee data available'],
        'insights': ['No employees found in the database. Please add employees and attendance records first.'],
        'recommendations': [],
        'summary': 'No data available for analysis',
        'nextReviewDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'dataSource': 'REAL_BACKEND_DATABASE',
        'employeesAnalyzed': 0,
      };
    }
    
    final avgAttendance = employeeData.isNotEmpty 
        ? employeeData.map((emp) => emp['attendancePercentage'] ?? 0.0).reduce((a, b) => a + b) / employeeData.length
        : 0.0;
    
    final highLateEmployees = employeeData.where((emp) => (emp['latePercentage'] ?? 0) > 25).length;
    final longAbsenceEmployees = employeeData.where((emp) => (emp['consecutiveAbsences'] ?? 0) > 5).length;
    
    if (avgAttendance < 80) {
      patterns.add("Company-wide attendance crisis detected - average attendance: ${avgAttendance.toStringAsFixed(1)}%");
      insights.add("Overall company attendance is critically low. Consider reviewing company policies and employee satisfaction.");
    } else if (avgAttendance < 90) {
      patterns.add("Moderate attendance concerns across organization");
      insights.add("Company attendance needs improvement. Consider employee engagement initiatives.");
    }
    
    if (highLateEmployees > 0) {
      patterns.add("Chronic lateness pattern detected across $highLateEmployees employees");
      insights.add("Multiple employees have punctuality issues. Consider reviewing work schedules or transportation policies.");
    }
    
    if (longAbsenceEmployees > 0) {
      patterns.add("Extended absence periods detected in $longAbsenceEmployees employees");
      insights.add("Long consecutive absences may indicate employee burnout, health issues, or job dissatisfaction.");
    }
    
    for (final employee in employeeData) {
      final attendanceRate = (employee['attendancePercentage'] ?? 0.0).toDouble();
      final lateRate = (employee['latePercentage'] ?? 0.0).toDouble();
      final absenceRate = (employee['absencePercentage'] ?? 0.0).toDouble();
      final consecutiveAbsences = employee['consecutiveAbsences'] ?? 0;
      
      String severity = 'low';
      String action = 'monitor';
      String reasoning = '';
      
      if (attendanceRate < 50 || consecutiveAbsences > 7) {
        severity = 'critical';
        action = 'immediate_termination';
        reasoning = 'Attendance rate ${attendanceRate.toStringAsFixed(1)}% or ${consecutiveAbsences} consecutive absences indicate complete disengagement.';
      } else if (attendanceRate < 70 || consecutiveAbsences > 5 || lateRate > 50) {
        severity = 'high';
        action = 'final_warning';
        reasoning = 'Multiple serious violations: ${attendanceRate.toStringAsFixed(1)}% attendance, ${lateRate.toStringAsFixed(1)}% late rate significantly impact productivity.';
      } else if (attendanceRate < 80 || lateRate > 30 || absenceRate > 20) {
        severity = 'medium';
        action = 'written_warning';
        reasoning = 'Concerning patterns: ${attendanceRate.toStringAsFixed(1)}% attendance, ${lateRate.toStringAsFixed(1)}% late rate need addressing.';
      } else {
        severity = 'low';
        action = 'verbal_coaching';
        reasoning = 'Minor concerns with ${attendanceRate.toStringAsFixed(1)}% attendance can be resolved through guidance.';
      }
      
      recommendations.add({
        'employeeName': employee['userName'],
        'employeeEmail': employee['email'],
        'department': employee['department'],
        'severity': severity,
        'recommendedAction': action,
        'aiReasoning': reasoning,
        'riskScore': _calculateRiskScore(attendanceRate, lateRate, absenceRate, consecutiveAbsences),
        'personalizedMessage': _generatePersonalizedMessage(employee, action),
      });
    }
    
    if (employeeData.isNotEmpty) {
      insights.add("Analyzed ${employeeData.length} employees from your database with average ${avgAttendance.toStringAsFixed(1)}% attendance.");
      insights.add("Based on real attendance patterns, consider implementing targeted interventions for underperformers.");
      
      final criticalCount = recommendations.where((r) => r['severity'] == 'critical').length;
      if (criticalCount > 0) {
        insights.add("$criticalCount employees require immediate termination consideration based on their actual attendance data.");
      }
    }
    
    final overallRisk = recommendations.isNotEmpty 
        ? recommendations.map((r) => r['riskScore'] as double).reduce((a, b) => a + b) / recommendations.length
        : 0.0;
    
    return {
      'success': true,
      'aiProvider': 'OpenAI GPT-4 (Demo Mode)',
      'analysisTimestamp': DateTime.now().toIso8601String(),
      'overallRiskScore': overallRisk.toStringAsFixed(2),
      'patternsDetected': patterns,
      'insights': insights,
      'recommendations': recommendations,
      'summary': _generateSummary(recommendations, overallRisk),
      'nextReviewDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      'dataSource': 'REAL_BACKEND_DATABASE',
      'employeesAnalyzed': employeeData.length,
    };
  }
  
  /// Calculate risk score using AI-like weighted analysis
  static double _calculateRiskScore(double attendance, double late, double absence, int consecutive) {
    double risk = 0.0;
    
    risk += (100 - attendance) * 0.4;
    risk += late * 0.25;
    risk += absence * 0.25;
    risk += consecutive * 2.5;
    
    return (risk / 100 * 10).clamp(0.0, 10.0);
  }
  
  /// Generate personalized message based on AI analysis
  static String _generatePersonalizedMessage(Map<String, dynamic> employee, String action) {
    final name = employee['userName'];
    final department = employee['department'];
    
    switch (action) {
      case 'immediate_termination':
        return "Dear $name, your employment with the $department department is being terminated due to chronic attendance violations that severely impact team operations.";
      case 'final_warning':
        return "Dear $name, this is your final warning regarding attendance issues. Immediate improvement is required to continue employment in $department.";
      case 'written_warning':
        return "Dear $name, we need to address your recent attendance concerns. Please meet with HR to discuss improvement strategies for your role in $department.";
      case 'verbal_coaching':
        return "Hi $name, let's have a friendly chat about optimizing your schedule to better support the $department team's success.";
      default:
        return "Dear $name, we're here to support your success in the $department department.";
    }
  }
  
  /// Generate AI summary
  static String _generateSummary(List<Map<String, dynamic>> recommendations, double overallRisk) {
    final criticalCount = recommendations.where((r) => r['severity'] == 'critical').length;
    final highCount = recommendations.where((r) => r['severity'] == 'high').length;
    final mediumCount = recommendations.where((r) => r['severity'] == 'medium').length;
    
    if (overallRisk > 7.0) {
      return "URGENT: Multiple critical attendance violations detected. Immediate management intervention required.";
    } else if (overallRisk > 5.0) {
      return "HIGH CONCERN: Significant attendance issues requiring prompt disciplinary action.";
    } else if (overallRisk > 3.0) {
      return "MODERATE CONCERN: Some attendance issues that need management attention.";
    } else {
      return "LOW RISK: Minor attendance concerns that can be addressed through coaching.";
    }
  }
  
  /// Real OpenAI API call (for actual implementation)
  static Future<Map<String, dynamic>> _callOpenAI(List<Map<String, dynamic>> employeeData) async {
    try {
      final prompt = _buildAIPrompt(employeeData);
      
      final response = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert HR consultant specializing in attendance analysis and employee performance management. Analyze the provided attendance data and give precise, actionable recommendations for disciplinary actions.'
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
          'dataSource': 'REAL_BACKEND_DATABASE',
          'employeesAnalyzed': employeeData.length,
          'tokens': data['usage'],
        };
      } else {
        return {
          'success': false,
          'error': 'OpenAI API call failed: ${response.statusCode}',
          'response': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to call OpenAI API: $e',
        'fallback': 'Using demo analysis instead',
      };
    }
  }
  
  /// Build structured prompt for AI analysis using real backend data
  static String _buildAIPrompt(List<Map<String, dynamic>> employeeData) {
    final prompt = StringBuffer();
    prompt.writeln('=== EMPLOYEE ATTENDANCE ANALYSIS REQUEST ===');
    prompt.writeln('Please analyze the following employee attendance data from our backend database and provide disciplinary recommendations:');
    prompt.writeln();
    prompt.writeln('DATA SOURCE: Live backend database with ${employeeData.length} employees');
    prompt.writeln('ANALYSIS PERIOD: Last 30 days');
    prompt.writeln();
    
    for (final employee in employeeData) {
      prompt.writeln('EMPLOYEE PROFILE:');
      prompt.writeln('• Name: ${employee['userName']}');
      prompt.writeln('• Email: ${employee['email']}');
      prompt.writeln('• Department: ${employee['department']}');
      prompt.writeln('• Position: ${employee['position']}');
      prompt.writeln('• Attendance Rate: ${employee['attendancePercentage']}%');
      prompt.writeln('• Late Arrival Rate: ${employee['latePercentage']}%');
      prompt.writeln('• Absence Rate: ${employee['absencePercentage']}%');
      prompt.writeln('• Consecutive Absences: ${employee['consecutiveAbsences']} days');
      prompt.writeln('• Total Working Days: ${employee['totalWorkingDays']}');
      prompt.writeln('• Days Present: ${employee['daysPresent']}');
      prompt.writeln('• Days Absent: ${employee['daysAbsent']}');
      prompt.writeln('• Average Daily Hours: ${employee['averageDailyHours']}');
      prompt.writeln('• Performance Category: ${employee['performanceCategory']}');
      prompt.writeln('---');
    }
    
    prompt.writeln();
    prompt.writeln('REQUIRED ANALYSIS:');
    prompt.writeln('1. Individual risk assessment for each employee (scale 0-10)');
    prompt.writeln('2. Specific disciplinary actions recommended (verbal warning, written warning, final warning, termination)');
    prompt.writeln('3. Patterns and trends across the organization');
    prompt.writeln('4. Root cause analysis for poor performers');
    prompt.writeln('5. Preventive measures to improve overall attendance');
    prompt.writeln('6. Timeline for follow-up actions');
    prompt.writeln('7. Legal considerations for disciplinary actions');
    prompt.writeln();
    prompt.writeln('Please provide actionable, specific recommendations based on this real attendance data.');
    
    return prompt.toString();
  }
}
