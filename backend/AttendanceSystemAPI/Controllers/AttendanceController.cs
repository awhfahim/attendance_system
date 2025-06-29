using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AttendanceSystemAPI.Data;
using AttendanceSystemAPI.DTOs;
using AttendanceSystemAPI.Models;
using System.Security.Claims;
using AttendanceSystemAPI.Options;
using AttendanceSystemAPI.Services;
using Microsoft.Extensions.Options;

namespace AttendanceSystemAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AttendanceController : ControllerBase
    {
        private readonly AttendanceDbContext _context;
        private readonly IFileStorageService _fileStorageService;
        private readonly MinioOptions _minioOptions;

        public AttendanceController(AttendanceDbContext context, IFileStorageService fileStorageService, 
            IOptions<MinioOptions> minioOptions)
        {
            _context = context;
            _fileStorageService = fileStorageService;
            _minioOptions = minioOptions.Value;

            // Try to ensure images directory exists, but don't fail if we can't create it
            try
            {
                var imagesPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "attendance");
                if (!Directory.Exists(imagesPath))
                {
                    Directory.CreateDirectory(imagesPath);
                }
            }
            catch (Exception ex)
            {
                // Log the error but don't fail the controller initialization
                Console.WriteLine($"Warning: Could not create images directory: {ex.Message}");
            }
        }

        private string GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? string.Empty;
        }

        private async Task<string?> SaveAttendanceImage(string? base64Image, string imageType)
        {
            if (string.IsNullOrEmpty(base64Image))
                return null;

            try
            {
                // Remove data:image/jpeg;base64, prefix if present
                var base64Data = base64Image.Contains(',') ? base64Image.Split(',')[1] : base64Image;
                var imageBytes = Convert.FromBase64String(base64Data);

                var fileName = $"{imageType}_{DateTime.UtcNow:yyyyMMdd_HHmmss}_{Guid.NewGuid():N}.jpg";
                var imagesPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "attendance");

                // Ensure the directory exists before writing
                if (!Directory.Exists(imagesPath))
                {
                    try
                    {
                        Directory.CreateDirectory(imagesPath);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Warning: Could not create images directory: {ex.Message}");
                        // If we can't create the directory, don't save the image
                        return null;
                    }
                }

                var filePath = Path.Combine(imagesPath, fileName);
                await System.IO.File.WriteAllBytesAsync(filePath, imageBytes);

                // Return relative path for storing in database
                return $"/images/attendance/{fileName}";
            }
            catch (Exception ex)
            {
                // Log the error in production
                Console.WriteLine($"Error saving attendance image: {ex.Message}");
                return null;
            }
        }

        private async Task<string?> UploadImageToS3(IFormFile? imageFile, string imageType)
        {
            if (imageFile == null || imageFile.Length == 0)
                return null;

            try
            {   
                
                var fileExtension = Path.GetExtension(imageFile.FileName);
                string uniqueFileName = $"{Guid.NewGuid():N}{fileExtension}";

                await using var stream = imageFile.OpenReadStream();
                var contentType = imageFile.ContentType;

                var isUploaded =
                    await _fileStorageService.UploadFileAsync("bhsoftbucket", uniqueFileName,
                        stream, contentType);
                
                return $"https://{_minioOptions.ExternalEndpoint}/bhsoftbucket/{uniqueFileName}";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error uploading image to S3: {ex.Message}");
                return null;
            }
        }

        [HttpPost("check-in")]
        public async Task<ActionResult<AttendanceDto>> CheckIn([FromForm] CheckInDto checkInDto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var today = DateTime.UtcNow.Date;

                // Check if user already checked in today
                var existingRecord = await _context.AttendanceRecords
                    .FirstOrDefaultAsync(a => a.UserId == userId &&
                                              a.CheckInTime.HasValue &&
                                              a.CheckInTime.Value.Date == today);

                if (existingRecord != null)
                {
                    return BadRequest(new { message = "You have already checked in today" });
                }

                // Upload check-in image to S3 if provided
                var checkInImagePath = await UploadImageToS3(checkInDto.CheckInImage, $"checkin_{userId}");

                var attendanceRecord = new AttendanceRecord
                {
                    UserId = userId,
                    CheckInTime = DateTime.Now,
                    CheckInLatitude = checkInDto.Latitude,
                    CheckInLongitude = checkInDto.Longitude,
                    CheckInImagePath = checkInImagePath,
                    Notes = checkInDto.Notes
                };

                _context.AttendanceRecords.Add(attendanceRecord);
                await _context.SaveChangesAsync();

                var attendanceDto = new AttendanceDto
                {
                    Id = attendanceRecord.Id,
                    UserId = attendanceRecord.UserId,
                    CheckInTime = attendanceRecord.CheckInTime,
                    CheckOutTime = attendanceRecord.CheckOutTime,
                    CheckInLatitude = attendanceRecord.CheckInLatitude,
                    CheckInLongitude = attendanceRecord.CheckInLongitude,
                    CheckOutLatitude = attendanceRecord.CheckOutLatitude,
                    CheckOutLongitude = attendanceRecord.CheckOutLongitude,
                    CheckInImagePath = attendanceRecord.CheckInImagePath,
                    CheckOutImagePath = attendanceRecord.CheckOutImagePath,
                    Notes = attendanceRecord.Notes,
                    CreatedAt = attendanceRecord.CreatedAt,
                    Date = attendanceRecord.Date,
                    TotalHours = attendanceRecord.TotalHours
                };

                return Ok(attendanceDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Check-in failed: {ex.Message}" });
            }
        }

        [HttpPost("check-out")]
        public async Task<ActionResult<AttendanceDto>> CheckOut([FromForm] CheckOutDto checkOutDto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var today = DateTime.UtcNow.Date;

                // Find today's attendance record
                var attendanceRecord = await _context.AttendanceRecords
                    .FirstOrDefaultAsync(a => a.UserId == userId &&
                                              a.CheckInTime.HasValue &&
                                              a.CheckInTime.Value.Date == today &&
                                              !a.CheckOutTime.HasValue);

                if (attendanceRecord == null)
                {
                    return BadRequest(new { message = "No check-in record found for today or already checked out" });
                }

                // Upload check-out image to S3 if provided
                var checkOutImagePath = await UploadImageToS3(checkOutDto.CheckOutImage, $"checkout_{userId}");

                attendanceRecord.CheckOutTime = DateTime.Now;
                attendanceRecord.CheckOutLatitude = checkOutDto.Latitude;
                attendanceRecord.CheckOutLongitude = checkOutDto.Longitude;
                attendanceRecord.CheckOutImagePath = checkOutImagePath;

                if (!string.IsNullOrEmpty(checkOutDto.Notes))
                {
                    attendanceRecord.Notes = string.IsNullOrEmpty(attendanceRecord.Notes)
                        ? checkOutDto.Notes
                        : $"{attendanceRecord.Notes}; {checkOutDto.Notes}";
                }

                await _context.SaveChangesAsync();

                var attendanceDto = new AttendanceDto
                {
                    Id = attendanceRecord.Id,
                    UserId = attendanceRecord.UserId,
                    CheckInTime = attendanceRecord.CheckInTime,
                    CheckOutTime = attendanceRecord.CheckOutTime,
                    CheckInLatitude = attendanceRecord.CheckInLatitude,
                    CheckInLongitude = attendanceRecord.CheckInLongitude,
                    CheckOutLatitude = attendanceRecord.CheckOutLatitude,
                    CheckOutLongitude = attendanceRecord.CheckOutLongitude,
                    CheckInImagePath = attendanceRecord.CheckInImagePath,
                    CheckOutImagePath = attendanceRecord.CheckOutImagePath,
                    Notes = attendanceRecord.Notes,
                    CreatedAt = attendanceRecord.CreatedAt,
                    Date = attendanceRecord.Date,
                    TotalHours = attendanceRecord.TotalHours
                };

                return Ok(attendanceDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Check-out failed: {ex.Message}" });
            }
        }

        [HttpGet("today")]
        public async Task<ActionResult<AttendanceDto?>> GetTodayAttendance()
        {
            try
            {
                var userId = GetCurrentUserId();
                var today = DateTime.UtcNow.Date;

                var attendanceRecord = await _context.AttendanceRecords
                    .FirstOrDefaultAsync(a => a.UserId == userId &&
                                              a.CheckInTime.HasValue &&
                                              a.CheckInTime.Value.Date == today);

                if (attendanceRecord == null)
                {
                    return Ok((AttendanceDto?)null);
                }

                var attendanceDto = new AttendanceDto
                {
                    Id = attendanceRecord.Id,
                    UserId = attendanceRecord.UserId,
                    CheckInTime = attendanceRecord.CheckInTime,
                    CheckOutTime = attendanceRecord.CheckOutTime,
                    CheckInLatitude = attendanceRecord.CheckInLatitude,
                    CheckInLongitude = attendanceRecord.CheckInLongitude,
                    CheckOutLatitude = attendanceRecord.CheckOutLatitude,
                    CheckOutLongitude = attendanceRecord.CheckOutLongitude,
                    CheckInImagePath = attendanceRecord.CheckInImagePath,
                    CheckOutImagePath = attendanceRecord.CheckOutImagePath,
                    Notes = attendanceRecord.Notes,
                    CreatedAt = attendanceRecord.CreatedAt,
                    Date = attendanceRecord.Date,
                    TotalHours = attendanceRecord.TotalHours
                };

                return Ok(attendanceDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to get today's attendance: {ex.Message}" });
            }
        }

        [HttpGet("history")]
        public async Task<ActionResult<List<AttendanceDto>>> GetAttendanceHistory(
            [FromQuery] int page = 1,
            [FromQuery] int limit = 10,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                var userId = GetCurrentUserId();
                var query = _context.AttendanceRecords
                    .Where(a => a.UserId == userId);

                if (startDate.HasValue)
                {
                    query = query.Where(a => a.CheckInTime >= startDate.Value);
                }

                if (endDate.HasValue)
                {
                    query = query.Where(a => a.CheckInTime <= endDate.Value.AddDays(1));
                }

                var attendanceRecords = await query
                    .OrderByDescending(a => a.CheckInTime)
                    .Skip((page - 1) * limit)
                    .Take(limit)
                    .ToListAsync();

                var attendanceDtos = attendanceRecords.Select(a => new AttendanceDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    CheckInLatitude = a.CheckInLatitude,
                    CheckInLongitude = a.CheckInLongitude,
                    CheckOutLatitude = a.CheckOutLatitude,
                    CheckOutLongitude = a.CheckOutLongitude,
                    CheckInImagePath = a.CheckInImagePath,
                    CheckOutImagePath = a.CheckOutImagePath,
                    Notes = a.Notes,
                    CreatedAt = a.CreatedAt,
                    Date = a.Date,
                    TotalHours = a.TotalHours
                }).ToList();

                return Ok(attendanceDtos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to get attendance history: {ex.Message}" });
            }
        }

        [HttpGet("monthly-stats")]
        public async Task<ActionResult<MonthlyStatsDto>> GetMonthlyStats([FromQuery] int? year = null,
            [FromQuery] int? month = null)
        {
            try
            {
                var userId = GetCurrentUserId();
                var targetDate = new DateTime(year ?? DateTime.UtcNow.Year, month ?? DateTime.UtcNow.Month, 1);
                var startOfMonth = new DateTime(targetDate.Year, targetDate.Month, 1);
                var endOfMonth = startOfMonth.AddMonths(1).AddDays(-1);

                var attendanceRecords = await _context.AttendanceRecords
                    .Where(a => a.UserId == userId &&
                                a.CheckInTime.HasValue &&
                                a.CheckInTime.Value.Date >= startOfMonth &&
                                a.CheckInTime.Value.Date <= endOfMonth)
                    .ToListAsync();

                var totalDays = DateTime.DaysInMonth(targetDate.Year, targetDate.Month);
                var presentDays = attendanceRecords.Count;
                var totalHours = attendanceRecords.Sum(a => a.TotalHours ?? 0);
                var averageHours = presentDays > 0 ? totalHours / presentDays : 0;

                var stats = new MonthlyStatsDto
                {
                    TotalDays = totalDays,
                    PresentDays = presentDays,
                    TotalHours = Math.Round(totalHours, 2),
                    AverageHours = Math.Round(averageHours, 2)
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to get monthly stats: {ex.Message}" });
            }
        }

        [HttpGet("recent")]
        public async Task<ActionResult<List<AttendanceDto>>> GetRecentAttendance([FromQuery] int limit = 5)
        {
            try
            {
                var userId = GetCurrentUserId();

                var recentRecords = await _context.AttendanceRecords
                    .Where(a => a.UserId == userId)
                    .OrderByDescending(a => a.CheckInTime)
                    .Take(limit)
                    .ToListAsync();

                var attendanceDtos = recentRecords.Select(a => new AttendanceDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    CheckInLatitude = a.CheckInLatitude,
                    CheckInLongitude = a.CheckInLongitude,
                    CheckOutLatitude = a.CheckOutLatitude,
                    CheckOutLongitude = a.CheckOutLongitude,
                    CheckInImagePath = a.CheckInImagePath,
                    CheckOutImagePath = a.CheckOutImagePath,
                    Notes = a.Notes,
                    CreatedAt = a.CreatedAt,
                    Date = a.Date,
                    TotalHours = a.TotalHours
                }).ToList();

                return Ok(attendanceDtos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to get recent attendance: {ex.Message}" });
            }
        }

        [HttpGet("analytics")]
        public async Task<ActionResult<AttendanceAnalyticsDto>> GetAttendanceAnalytics(
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                // Check if current user is admin
                var currentUserId = GetCurrentUserId();
                var currentUser = await _context.Users.FirstOrDefaultAsync(u => u.Id == currentUserId);
                
                if (currentUser?.IsAdmin != true)
                {
                    return Forbid("Only administrators can access attendance analytics");
                }

                // Set default date range (last 30 days if not specified)
                var end = endDate ?? DateTime.UtcNow.Date;
                var start = startDate ?? end.AddDays(-30);

                // Get all users
                var allUsers = await _context.Users.Where(u => !u.IsAdmin).ToListAsync();
                
                // Get all attendance records for the date range
                var attendanceRecords = await _context.AttendanceRecords
                    .Include(a => a.User)
                    .Where(a => a.CheckInTime.HasValue && 
                               a.CheckInTime.Value.Date >= start && 
                               a.CheckInTime.Value.Date <= end)
                    .ToListAsync();

                var employeePerformances = new List<EmployeePerformanceDto>();

                foreach (var user in allUsers)
                {
                    var userRecords = attendanceRecords.Where(a => a.UserId == user.Id).ToList();
                    
                    // Calculate working days in the period (excluding weekends)
                    var totalWorkingDays = 0;
                    for (var date = start; date <= end; date = date.AddDays(1))
                    {
                        if (date.DayOfWeek != DayOfWeek.Saturday && date.DayOfWeek != DayOfWeek.Sunday)
                        {
                            totalWorkingDays++;
                        }
                    }

                    var daysPresent = userRecords.Count;
                    var daysAbsent = totalWorkingDays - daysPresent;
                    var daysLate = userRecords.Count(r => r.CheckInTime?.Hour > 9 || 
                                                          (r.CheckInTime?.Hour == 9 && r.CheckInTime?.Minute > 0));
                    
                    var totalHours = userRecords.Sum(r => r.TotalHours ?? 0);
                    var avgDailyHours = daysPresent > 0 ? totalHours / daysPresent : 0;
                    var attendancePercentage = totalWorkingDays > 0 ? (double)daysPresent / totalWorkingDays * 100 : 0;
                    var latePercentage = daysPresent > 0 ? (double)daysLate / daysPresent * 100 : 0;
                    var absencePercentage = totalWorkingDays > 0 ? (double)daysAbsent / totalWorkingDays * 100 : 0;

                    // Calculate consecutive absences
                    var consecutiveAbsences = CalculateConsecutiveAbsences(user.Id, attendanceRecords, end);
                    
                    // Determine performance category
                    var performanceCategory = DeterminePerformanceCategory(attendancePercentage, latePercentage, absencePercentage, consecutiveAbsences);

                    var lastAttendance = userRecords.OrderByDescending(r => r.CheckInTime).FirstOrDefault()?.CheckInTime;

                    employeePerformances.Add(new EmployeePerformanceDto
                    {
                        UserId = user.Id,
                        UserName = user.Name,
                        Department = user.Department,
                        Position = user.Position,
                        Email = user.Email,
                        TotalWorkingDays = totalWorkingDays,
                        DaysPresent = daysPresent,
                        DaysAbsent = daysAbsent,
                        DaysLate = daysLate,
                        TotalHoursWorked = Math.Round(totalHours, 2),
                        AverageDailyHours = Math.Round(avgDailyHours, 2),
                        AttendancePercentage = Math.Round(attendancePercentage, 2),
                        LatePercentage = Math.Round(latePercentage, 2),
                        AbsencePercentage = Math.Round(absencePercentage, 2),
                        ConsecutiveAbsences = consecutiveAbsences,
                        LastAttendanceDate = lastAttendance,
                        PerformanceCategory = performanceCategory
                    });
                }

                // Identify poor performers (attendance < 80% OR late > 30% OR absence > 20% OR consecutive absences > 3)
                var poorPerformers = employeePerformances
                    .Where(ep => ep.AttendancePercentage < 80 || 
                                ep.LatePercentage > 30 || 
                                ep.AbsencePercentage > 20 || 
                                ep.ConsecutiveAbsences > 3 ||
                                ep.PerformanceCategory == "Critical" ||
                                ep.PerformanceCategory == "Poor")
                    .OrderBy(ep => ep.AttendancePercentage)
                    .ThenByDescending(ep => ep.AbsencePercentage)
                    .ToList();

                var avgAttendanceRate = employeePerformances.Average(ep => ep.AttendancePercentage);
                var avgLateRate = employeePerformances.Average(ep => ep.LatePercentage);

                var analytics = new AttendanceAnalyticsDto
                {
                    StartDate = start,
                    EndDate = end,
                    TotalEmployees = allUsers.Count,
                    EmployeePerformances = employeePerformances.OrderBy(ep => ep.UserName).ToList(),
                    PoorPerformers = poorPerformers,
                    AverageAttendanceRate = Math.Round(avgAttendanceRate, 2),
                    AverageLateRate = Math.Round(avgLateRate, 2)
                };

                return Ok(analytics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Failed to get attendance analytics: {ex.Message}" });
            }
        }

        private int CalculateConsecutiveAbsences(string userId, List<AttendanceRecord> allRecords, DateTime endDate)
        {
            var userRecords = allRecords.Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CheckInTime)
                .ToList();

            var consecutiveDays = 0;
            var currentDate = endDate.Date;

            while (currentDate.DayOfWeek != DayOfWeek.Saturday && currentDate.DayOfWeek != DayOfWeek.Sunday)
            {
                var hasRecord = userRecords.Any(r => r.CheckInTime?.Date == currentDate);
                if (hasRecord)
                {
                    break;
                }
                consecutiveDays++;
                currentDate = currentDate.AddDays(-1);
                
                // Limit to prevent infinite loop
                if (consecutiveDays > 30) break;
            }

            return consecutiveDays;
        }

        private string DeterminePerformanceCategory(double attendancePercentage, double latePercentage, double absencePercentage, int consecutiveAbsences)
        {
            // Critical: Very poor attendance or excessive absences
            if (attendancePercentage < 60 || absencePercentage > 40 || consecutiveAbsences > 5)
                return "Critical";
            
            // Poor: Below acceptable standards
            if (attendancePercentage < 80 || latePercentage > 30 || absencePercentage > 20 || consecutiveAbsences > 3)
                return "Poor";
            
            // Good: Acceptable performance with room for improvement
            if (attendancePercentage < 95 || latePercentage > 15 || absencePercentage > 10)
                return "Good";
            
            // Excellent: Outstanding performance
            return "Excellent";
        }
    }
}