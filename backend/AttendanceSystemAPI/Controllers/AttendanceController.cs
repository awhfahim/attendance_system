using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AttendanceSystemAPI.Data;
using AttendanceSystemAPI.DTOs;
using AttendanceSystemAPI.Models;
using System.Security.Claims;

namespace AttendanceSystemAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    // [Authorize]
    public class AttendanceController : ControllerBase
    {
        private readonly AttendanceDbContext _context;

        public AttendanceController(AttendanceDbContext context)
        {
            _context = context;
        }

        private string GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? string.Empty;
        }

        [HttpPost("check-in")]
        public async Task<ActionResult<AttendanceDto>> CheckIn([FromBody] CheckInDto checkInDto)
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

                var attendanceRecord = new AttendanceRecord
                {
                    UserId = userId,
                    CheckInTime = DateTime.UtcNow,
                    CheckInLatitude = checkInDto.Latitude,
                    CheckInLongitude = checkInDto.Longitude,
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
        public async Task<ActionResult<AttendanceDto>> CheckOut([FromBody] CheckOutDto checkOutDto)
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

                attendanceRecord.CheckOutTime = DateTime.UtcNow;
                attendanceRecord.CheckOutLatitude = checkOutDto.Latitude;
                attendanceRecord.CheckOutLongitude = checkOutDto.Longitude;
                
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
        public async Task<ActionResult<MonthlyStatsDto>> GetMonthlyStats([FromQuery] int? year = null, [FromQuery] int? month = null)
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
    }
}
