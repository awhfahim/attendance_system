using Microsoft.EntityFrameworkCore;
using AttendanceSystemAPI.Models;
using BCrypt.Net;

namespace AttendanceSystemAPI.Data
{
    public class AttendanceDbContext : DbContext
    {
        public AttendanceDbContext(DbContextOptions<AttendanceDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.Email).IsRequired();
                entity.Property(e => e.Name).IsRequired();
                entity.Property(e => e.PasswordHash).IsRequired();
            });

            // Configure AttendanceRecord entity
            modelBuilder.Entity<AttendanceRecord>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasOne(e => e.User)
                    .WithMany(u => u.AttendanceRecords)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Seed data
            SeedData(modelBuilder);
        }

        private static void SeedData(ModelBuilder modelBuilder)
        {
            // Seed users with different performance profiles
            var adminId = "admin-user-id-123";
            var employeeId = "employee-user-id-456";
            var goodEmployeeId = "good-employee-id-789";
            var poorEmployeeId = "poor-employee-id-101";
            var averageEmployeeId = "average-employee-id-112";

            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = adminId,
                    Name = "Super Admin",
                    Email = "imon523@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("imon123"),
                    Department = "IT",
                    Position = "Software Developer",
                    Phone = "+1234567890",
                    IsAdmin = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-60)
                },
                new User
                {
                    Id = employeeId,
                    Name = "Fahim Hasan",
                    Email = "fahimhasan314@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("fahim123"),
                    Department = "Marketing",
                    Position = "Marketing Specialist",
                    Phone = "+0987654321",
                    IsAdmin = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-50)
                },
                new User
                {
                    Id = goodEmployeeId,
                    Name = "Mushfiqur Rahman",
                    Email = "mushfiqur485@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("mushfiq123"),
                    Department = "Sales",
                    Position = "Sales Manager",
                    Phone = "+1122334455",
                    IsAdmin = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-45)
                },
                new User
                {
                    Id = poorEmployeeId,
                    Name = "Samia Jahan Luna",
                    Email = "samia123@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("samia123"),
                    Department = "Operations",
                    Position = "Operations Assistant",
                    Phone = "+2233445566",
                    IsAdmin = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-40)
                },
                new User
                {
                    Id = averageEmployeeId,
                    Name = "Fatema Chowdhury",
                    Email = "fatema532@gmail.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("fatema123"),
                    Department = "HR",
                    Position = "HR Coordinator",
                    Phone = "+3344556677",
                    IsAdmin = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-35)
                }
            );

            // Generate comprehensive attendance records for the last 30 days
            var attendanceRecords = new List<AttendanceRecord>();
            var today = DateTime.UtcNow.Date;
            var recordId = 1;

            // Create attendance patterns for each user
            for (int dayOffset = 30; dayOffset >= 1; dayOffset--)
            {
                var currentDate = today.AddDays(-dayOffset);
                
                // Skip weekends
                if (currentDate.DayOfWeek == DayOfWeek.Saturday || currentDate.DayOfWeek == DayOfWeek.Sunday)
                    continue;

                // Admin (Excellent attendance - 95% present, rarely late)
                if (dayOffset % 20 != 0) // Absent 1 day out of 20
                {
                    var checkInTime = currentDate.AddHours(9).AddMinutes(Random.Shared.Next(-5, 15)); // Mostly on time
                    attendanceRecords.Add(new AttendanceRecord
                    {
                        Id = $"attendance-record-{recordId++}",
                        UserId = adminId,
                        CheckInTime = checkInTime,
                        CheckOutTime = checkInTime.AddHours(8).AddMinutes(Random.Shared.Next(0, 60)),
                        CheckInLatitude = 40.7128 + Random.Shared.NextDouble() * 0.01,
                        CheckInLongitude = -74.0060 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLatitude = 40.7128 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLongitude = -74.0060 + Random.Shared.NextDouble() * 0.01,
                        Notes = dayOffset % 10 == 0 ? "Project deadline" : "Regular work",
                        CreatedAt = checkInTime
                    });
                }

                // Regular Employee (Good attendance - 88% present, occasionally late)
                if (dayOffset % 8 != 0) // Absent 1 day out of 8
                {
                    var checkInTime = currentDate.AddHours(9).AddMinutes(Random.Shared.Next(-10, 25)); // Sometimes late
                    attendanceRecords.Add(new AttendanceRecord
                    {
                        Id = $"attendance-record-{recordId++}",
                        UserId = employeeId,
                        CheckInTime = checkInTime,
                        CheckOutTime = checkInTime.AddHours(8).AddMinutes(Random.Shared.Next(-30, 45)),
                        CheckInLatitude = 40.7128 + Random.Shared.NextDouble() * 0.01,
                        CheckInLongitude = -74.0060 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLatitude = 40.7128 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLongitude = -74.0060 + Random.Shared.NextDouble() * 0.01,
                        Notes = dayOffset % 7 == 0 ? "Client meeting" : "Standard work",
                        CreatedAt = checkInTime
                    });
                }

                // Good Employee (Excellent attendance - 96% present, always on time)
                if (dayOffset % 25 != 0) // Absent 1 day out of 25
                {
                    var checkInTime = currentDate.AddHours(8).AddMinutes(45).AddMinutes(Random.Shared.Next(0, 10)); // Always early/on time
                    attendanceRecords.Add(new AttendanceRecord
                    {
                        Id = $"attendance-record-{recordId++}",
                        UserId = goodEmployeeId,
                        CheckInTime = checkInTime,
                        CheckOutTime = checkInTime.AddHours(8).AddMinutes(Random.Shared.Next(15, 75)), // Often works extra
                        CheckInLatitude = 40.7589 + Random.Shared.NextDouble() * 0.01,
                        CheckInLongitude = -73.9851 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLatitude = 40.7589 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLongitude = -73.9851 + Random.Shared.NextDouble() * 0.01,
                        Notes = dayOffset % 5 == 0 ? "Sales calls" : "Office work",
                        CreatedAt = checkInTime
                    });
                }

                // Poor Employee (Bad attendance - 65% present, frequently late, consecutive absences)
                if (dayOffset <= 25 && (dayOffset % 3 != 0 || (dayOffset >= 15 && dayOffset <= 18))) // Poor pattern with consecutive absences
                {
                    // Skip days 15-18 for consecutive absences, then random absences
                    if (dayOffset >= 15 && dayOffset <= 18)
                        continue; // 4 consecutive absent days
                    
                    if (dayOffset % 3 == 0)
                        continue; // Additional random absences
                    
                    var checkInTime = currentDate.AddHours(9).AddMinutes(Random.Shared.Next(15, 90)); // Frequently late
                    attendanceRecords.Add(new AttendanceRecord
                    {
                        Id = $"attendance-record-{recordId++}",
                        UserId = poorEmployeeId,
                        CheckInTime = checkInTime,
                        CheckOutTime = checkInTime.AddHours(Random.Shared.Next(6, 8)), // Sometimes leaves early
                        CheckInLatitude = 40.7128 + Random.Shared.NextDouble() * 0.02,
                        CheckInLongitude = -74.0060 + Random.Shared.NextDouble() * 0.02,
                        CheckOutLatitude = 40.7128 + Random.Shared.NextDouble() * 0.02,
                        CheckOutLongitude = -74.0060 + Random.Shared.NextDouble() * 0.02,
                        Notes = dayOffset % 4 == 0 ? "Personal issues" : "Traffic/transport",
                        CreatedAt = checkInTime
                    });
                }

                // Average Employee (Average attendance - 80% present, moderately late)
                if (dayOffset % 5 != 0) // Absent 1 day out of 5
                {
                    var checkInTime = currentDate.AddHours(9).AddMinutes(Random.Shared.Next(0, 35)); // Moderately late
                    attendanceRecords.Add(new AttendanceRecord
                    {
                        Id = $"attendance-record-{recordId++}",
                        UserId = averageEmployeeId,
                        CheckInTime = checkInTime,
                        CheckOutTime = checkInTime.AddHours(8).AddMinutes(Random.Shared.Next(-15, 30)),
                        CheckInLatitude = 40.7505 + Random.Shared.NextDouble() * 0.01,
                        CheckInLongitude = -73.9934 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLatitude = 40.7505 + Random.Shared.NextDouble() * 0.01,
                        CheckOutLongitude = -73.9934 + Random.Shared.NextDouble() * 0.01,
                        Notes = dayOffset % 6 == 0 ? "HR meetings" : "Regular duties",
                        CreatedAt = checkInTime
                    });
                }
            }

            modelBuilder.Entity<AttendanceRecord>().HasData(attendanceRecords.ToArray());
        }
    }
}
