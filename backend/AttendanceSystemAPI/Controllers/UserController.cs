using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AttendanceSystemAPI.Data;
using AttendanceSystemAPI.DTOs;
using AttendanceSystemAPI.Models;
using System.Security.Claims;
using BCrypt.Net;

namespace AttendanceSystemAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly AttendanceDbContext _context;

        public UserController(AttendanceDbContext context)
        {
            _context = context;
        }

        private string GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? string.Empty;
        }

        private async Task<bool> IsCurrentUserAdmin()
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            return user?.IsAdmin ?? false;
        }

        [HttpPost("create")]
        public async Task<ActionResult<UserManagementResponseDto>> CreateUser([FromBody] CreateUserDto createUserDto)
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can create users");
                }

                // Check if email already exists
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == createUserDto.Email);

                if (existingUser != null)
                {
                    return Ok(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "Email already exists"
                    });
                }

                // Create new user
                var user = new User
                {
                    Name = createUserDto.Name,
                    Email = createUserDto.Email,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(createUserDto.Password),
                    Department = createUserDto.Department,
                    Position = createUserDto.Position,
                    Phone = createUserDto.Phone,
                    IsAdmin = createUserDto.IsAdmin,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "User created successfully",
                    User = new UserDto
                    {
                        Id = user.Id,
                        Name = user.Name,
                        Email = user.Email,
                        Department = user.Department,
                        Position = user.Position,
                        Phone = user.Phone,
                        ProfileImage = user.ProfileImage,
                        IsAdmin = user.IsAdmin,
                        CreatedAt = user.CreatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to create user: {ex.Message}"
                });
            }
        }

        [HttpGet("list")]
        public async Task<ActionResult<UserManagementResponseDto>> GetAllUsers()
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can view user list");
                }

                var users = await _context.Users
                    .OrderBy(u => u.Name)
                    .Select(u => new UserDto
                    {
                        Id = u.Id,
                        Name = u.Name,
                        Email = u.Email,
                        Department = u.Department,
                        Position = u.Position,
                        Phone = u.Phone,
                        ProfileImage = u.ProfileImage,
                        IsAdmin = u.IsAdmin,
                        CreatedAt = u.CreatedAt
                    })
                    .ToListAsync();

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "Users retrieved successfully",
                    Users = users
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to retrieve users: {ex.Message}"
                });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserManagementResponseDto>> GetUser(string id)
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can view user details");
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == id);

                if (user == null)
                {
                    return NotFound(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "User not found"
                    });
                }

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "User retrieved successfully",
                    User = new UserDto
                    {
                        Id = user.Id,
                        Name = user.Name,
                        Email = user.Email,
                        Department = user.Department,
                        Position = user.Position,
                        Phone = user.Phone,
                        ProfileImage = user.ProfileImage,
                        IsAdmin = user.IsAdmin,
                        CreatedAt = user.CreatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to retrieve user: {ex.Message}"
                });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UserManagementResponseDto>> UpdateUser(string id, [FromBody] UpdateUserDto updateUserDto)
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can update users");
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == id);

                if (user == null)
                {
                    return NotFound(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "User not found"
                    });
                }

                // Check if email already exists for another user
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == updateUserDto.Email && u.Id != id);

                if (existingUser != null)
                {
                    return Ok(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "Email already exists"
                    });
                }

                // Update user properties
                user.Name = updateUserDto.Name;
                user.Email = updateUserDto.Email;
                user.Department = updateUserDto.Department;
                user.Position = updateUserDto.Position;
                user.Phone = updateUserDto.Phone;
                user.IsAdmin = updateUserDto.IsAdmin;

                await _context.SaveChangesAsync();

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "User updated successfully",
                    User = new UserDto
                    {
                        Id = user.Id,
                        Name = user.Name,
                        Email = user.Email,
                        Department = user.Department,
                        Position = user.Position,
                        Phone = user.Phone,
                        ProfileImage = user.ProfileImage,
                        IsAdmin = user.IsAdmin,
                        CreatedAt = user.CreatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to update user: {ex.Message}"
                });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult<UserManagementResponseDto>> DeleteUser(string id)
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can delete users");
                }

                var currentUserId = GetCurrentUserId();
                
                // Prevent admin from deleting themselves
                if (id == currentUserId)
                {
                    return BadRequest(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "You cannot delete your own account"
                    });
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == id);

                if (user == null)
                {
                    return NotFound(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "User not found"
                    });
                }

                // Delete associated attendance records first
                var attendanceRecords = await _context.AttendanceRecords
                    .Where(a => a.UserId == id)
                    .ToListAsync();

                _context.AttendanceRecords.RemoveRange(attendanceRecords);
                _context.Users.Remove(user);
                
                await _context.SaveChangesAsync();

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "User deleted successfully"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to delete user: {ex.Message}"
                });
            }
        }

        [HttpPost("{id}/reset-password")]
        public async Task<ActionResult<UserManagementResponseDto>> ResetPassword(string id, [FromBody] ResetPasswordDto resetPasswordDto)
        {
            try
            {
                // Check if current user is admin
                if (!await IsCurrentUserAdmin())
                {
                    return Forbid("Only administrators can reset passwords");
                }

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == id);

                if (user == null)
                {
                    return NotFound(new UserManagementResponseDto
                    {
                        Success = false,
                        Message = "User not found"
                    });
                }

                // Update password
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(resetPasswordDto.NewPassword);
                await _context.SaveChangesAsync();

                return Ok(new UserManagementResponseDto
                {
                    Success = true,
                    Message = "Password reset successfully"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new UserManagementResponseDto
                {
                    Success = false,
                    Message = $"Failed to reset password: {ex.Message}"
                });
            }
        }
    }

    public class ResetPasswordDto
    {
        [Required]
        [StringLength(100, MinimumLength = 6)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
