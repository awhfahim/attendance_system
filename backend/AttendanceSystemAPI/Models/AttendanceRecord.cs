using System.ComponentModel.DataAnnotations;

namespace AttendanceSystemAPI.Models
{
    public class AttendanceRecord
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        public User? User { get; set; }
        
        public DateTime? CheckInTime { get; set; }
        
        public DateTime? CheckOutTime { get; set; }
        
        public double? CheckInLatitude { get; set; }
        
        public double? CheckInLongitude { get; set; }
        
        public double? CheckOutLatitude { get; set; }
        
        public double? CheckOutLongitude { get; set; }
        
        [StringLength(500)]
        public string? Notes { get; set; }
        
        // Image paths for check-in and check-out photos
        [StringLength(255)]
        public string? CheckInImagePath { get; set; }
        
        [StringLength(255)]
        public string? CheckOutImagePath { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Computed property for date
        public DateTime Date => CheckInTime?.Date ?? CreatedAt.Date;
        
        // Computed property for total hours
        public double? TotalHours
        {
            get
            {
                if (CheckInTime.HasValue && CheckOutTime.HasValue)
                {
                    return (CheckOutTime.Value - CheckInTime.Value).TotalHours;
                }
                return null;
            }
        }
    }
}
