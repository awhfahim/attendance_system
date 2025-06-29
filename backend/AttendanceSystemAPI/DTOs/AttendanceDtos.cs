using System.ComponentModel.DataAnnotations;

namespace AttendanceSystemAPI.DTOs
{
    public class LoginDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        public string Password { get; set; } = string.Empty;
    }
    
    public class LoginResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public UserDto? User { get; set; }
        public string? Token { get; set; }
    }
    
    public class UserDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public string Position { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string? ProfileImage { get; set; }
        public bool IsAdmin { get; set; }
        public DateTime CreatedAt { get; set; }
    }
    
    public class CheckInDto
    {
        [Required]
        public double Latitude { get; set; }
        
        [Required]
        public double Longitude { get; set; }
        
        public string? Notes { get; set; }
        public IFormFile? CheckInImage { get; set; }
    }
    
    public class CheckOutDto
    {
        [Required]
        public double Latitude { get; set; }
        
        [Required]
        public double Longitude { get; set; }
        
        public string? Notes { get; set; }
        public IFormFile? CheckOutImage { get; set; }
    }
    
    public class AttendanceDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public DateTime? CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public double? CheckInLatitude { get; set; }
        public double? CheckInLongitude { get; set; }
        public double? CheckOutLatitude { get; set; }
        public double? CheckOutLongitude { get; set; }
        public string? Notes { get; set; }
        public string? CheckInImagePath { get; set; }
        public string? CheckOutImagePath { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime Date { get; set; }
        public double? TotalHours { get; set; }
    }
    
    public class UpdateProfileDto
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Phone]
        public string Phone { get; set; } = string.Empty;
        
        public string? ProfileImage { get; set; }
    }
    
    public class MonthlyStatsDto
    {
        public int TotalDays { get; set; }
        public int PresentDays { get; set; }
        public double TotalHours { get; set; }
        public double AverageHours { get; set; }
    }

    // Employee Performance Analytics DTOs
    public class EmployeePerformanceDto
    {
        public string UserId { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public string Position { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int TotalWorkingDays { get; set; }
        public int DaysPresent { get; set; }
        public int DaysAbsent { get; set; }
        public int DaysLate { get; set; }
        public double TotalHoursWorked { get; set; }
        public double AverageDailyHours { get; set; }
        public double AttendancePercentage { get; set; }
        public double LatePercentage { get; set; }
        public double AbsencePercentage { get; set; }
        public int ConsecutiveAbsences { get; set; }
        public DateTime? LastAttendanceDate { get; set; }
        public string PerformanceCategory { get; set; } = string.Empty; // Excellent, Good, Poor, Critical
    }

    public class AttendanceAnalyticsDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int TotalEmployees { get; set; }
        public List<EmployeePerformanceDto> EmployeePerformances { get; set; } = new();
        public List<EmployeePerformanceDto> PoorPerformers { get; set; } = new();
        public double AverageAttendanceRate { get; set; }
        public double AverageLateRate { get; set; }
    }

    // User Management DTOs
    public class CreateUserDto
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100, MinimumLength = 6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string Department { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string Position { get; set; } = string.Empty;
        
        [Phone]
        public string Phone { get; set; } = string.Empty;
        
        public bool IsAdmin { get; set; } = false;
    }

    public class UserManagementResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public UserDto? User { get; set; }
        public List<UserDto>? Users { get; set; }
    }

    public class UpdateUserDto
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [StringLength(100)]
        public string Department { get; set; } = string.Empty;
        
        [StringLength(100)]
        public string Position { get; set; } = string.Empty;
        
        [Phone]
        public string Phone { get; set; } = string.Empty;
        
        public bool IsAdmin { get; set; } = false;
    }
}

