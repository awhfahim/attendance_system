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
            // Seed users
            var adminId = "admin-user-id-123";
            var employeeId = "employee-user-id-456";

            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = adminId,
                    Name = "John Doe",
                        Email = "admin@company.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
                    Department = "IT",
                    Position = "Software Developer",
                    Phone = "+1234567890",
                    IsAdmin = true,
                    CreatedAt = DateTime.UtcNow
                },
                new User
                {
                    Id = employeeId,
                    Name = "Jane Smith",
                    Email = "employee@company.com",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("emp123"),
                    Department = "Marketing",
                    Position = "Marketing Specialist",
                    Phone = "+0987654321",
                    IsAdmin = false,
                    CreatedAt = DateTime.UtcNow
                }
            );

            // Seed some attendance records
            var today = DateTime.UtcNow.Date;
            var yesterday = today.AddDays(-1);
            
            modelBuilder.Entity<AttendanceRecord>().HasData(
                new AttendanceRecord
                {
                    Id = "attendance-record-1",
                    UserId = adminId,
                    CheckInTime = today.AddDays(-1).AddHours(9),
                    CheckOutTime = today.AddDays(-1).AddHours(17),
                    CheckInLatitude = 40.7128,
                    CheckInLongitude = -74.0060,
                    CheckOutLatitude = 40.7128,
                    CheckOutLongitude = -74.0060,
                    Notes = "Regular work day",
                    CreatedAt = today.AddHours(9)
                },
                new AttendanceRecord
                {
                    Id = "attendance-record-2",
                    UserId = employeeId,
                    CheckInTime = yesterday.AddHours(8.5),
                    CheckOutTime = yesterday.AddHours(16.5),
                    CheckInLatitude = 40.7128,
                    CheckInLongitude = -74.0060,
                    CheckOutLatitude = 40.7128,
                    CheckOutLongitude = -74.0060,
                    Notes = "Early start",
                    CreatedAt = yesterday.AddHours(8.5)
                }
            );
        }
    }
}
