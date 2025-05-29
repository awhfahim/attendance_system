using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AttendanceSystemAPI.Data;
using AttendanceSystemAPI.DTOs;
using AttendanceSystemAPI.Services;
using BCrypt.Net;

namespace AttendanceSystemAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AttendanceDbContext _context;
        private readonly JwtService _jwtService;

        public AuthController(AttendanceDbContext context, JwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponseDto>> Login([FromBody] LoginDto loginDto)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == loginDto.Email);

                if (user == null || !BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                {
                    return Ok(new LoginResponseDto
                    {
                        Success = false,
                        Message = "Invalid email or password"
                    });
                }

                var token = _jwtService.GenerateToken(user);

                return Ok(new LoginResponseDto
                {
                    Success = true,
                    Message = "Login successful",
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
                    },
                    Token = token
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new LoginResponseDto
                {
                    Success = false,
                    Message = $"Login failed: {ex.Message}"
                });
            }
        }
    }
}
