using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;
using System.Security.Cryptography;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // POST: api/auth/register
        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
        {
            try
            {
                // Validate required fields
                if (string.IsNullOrWhiteSpace(request.Email))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Email không được để trống"
                    });
                }

                if (string.IsNullOrWhiteSpace(request.Password))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Mật khẩu không được để trống"
                    });
                }

                if (string.IsNullOrWhiteSpace(request.FullName))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Họ tên không được để trống"
                    });
                }

                if (string.IsNullOrWhiteSpace(request.Phone))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Số điện thoại không được để trống"
                    });
                }

                // Check if user exists
                if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Email đã được đăng ký"
                    });
                }

                // Create new user
                var user = new User
                {
                    Email = request.Email,
                    PasswordHash = HashPassword(request.Password),
                    FullName = request.FullName,
                    Phone = request.Phone,
                    AvatarUrl = request.AvatarUrl ?? "", // Set default empty string
                    Role = request.Role ?? "User",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var token = GenerateJwtToken(user);

                return Ok(new AuthResponse
                {
                    Success = true,
                    Message = "Đăng ký thành công",
                    User = MapToUserDTO(user),
                    Token = token
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new AuthResponse
                {
                    Success = false,
                    Message = $"Lỗi: {ex.Message}"
                });
            }
        }

        // POST: api/auth/login
        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email);

                if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Email hoặc mật khẩu không chính xác"
                    });
                }

                if (!user.IsActive)
                {
                    return BadRequest(new AuthResponse
                    {
                        Success = false,
                        Message = "Tài khoản đã bị vô hiệu hóa"
                    });
                }

                var response = new AuthResponse
                {
                    Success = true,
                    Message = "Đăng nhập thành công",
                    User = MapToUserDTO(user),
                    Token = GenerateJwtToken(user)
                };

                // Check company registration status for Provider role
                if (user.Role == "Provider")
                {
                    var company = await _context.BusCompanies
                        .FirstOrDefaultAsync(c => c.OwnerId == user.Id);

                    if (company == null)
                    {
                        response.CompanyStatus = new CompanyRegistrationStatus
                        {
                            HasCompany = false,
                            Status = "none",
                            Message = "Vui lòng đăng ký thông tin công ty để tiếp tục"
                        };
                    }
                    else
                    {
                        // Use ApprovalStatus field for proper status tracking
                        string status = company.ApprovalStatus ?? "pending";
                        string message = status switch
                        {
                            "pending" => "Thông tin công ty đang chờ duyệt từ admin. Vui lòng chờ hoặc cập nhật thông tin.",
                            "approved" => "Công ty của bạn đã được phê duyệt",
                            "rejected" => "Công ty bị từ chối. Vui lòng cập nhật thông tin.",
                            _ => "Vui lòng đăng ký thông tin công ty để tiếp tục"
                        };

                        response.CompanyStatus = new CompanyRegistrationStatus
                        {
                            HasCompany = true,
                            Status = status,
                            Company = MapToBusCompanyDTO(company, new List<Review>()),
                            Message = message
                        };
                    }
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new AuthResponse
                {
                    Success = false,
                    Message = $"Lỗi: {ex.Message}"
                });
            }
        }

        // POST: api/auth/logout
        [HttpPost("logout")]
        public ActionResult Logout()
        {
            // Token-based authentication - client should remove token
            return Ok(new { success = true, message = "Đã đăng xuất" });
        }

        private string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(hashedBytes);
            }
        }

        private bool VerifyPassword(string password, string hash)
        {
            var hashOfInput = HashPassword(password);
            return hashOfInput.Equals(hash);
        }

        private string GenerateJwtToken(User user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim("userId", user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("role", user.Role),
                new Claim("fullName", user.FullName),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpireMinutes"])),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private UserDTO MapToUserDTO(User user)
        {
            return new UserDTO
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                Phone = user.Phone,
                AvatarUrl = user.AvatarUrl,
                Role = user.Role,
                IsActive = user.IsActive,
                CreatedAt = user.CreatedAt
            };
        }

        private BusCompanyDTO MapToBusCompanyDTO(BusCompany company, List<Review> allReviews)
        {
            var companyReviews = allReviews.Where(r => r.BusCompanyId == company.Id).ToList();
            var avgRating = companyReviews.Any() ? companyReviews.Average(r => r.Rating) : 0;

            return new BusCompanyDTO
            {
                Id = company.Id,
                OwnerId = company.OwnerId,
                Name = company.Name,
                Description = company.Description,
                IsApproved = company.IsApproved,
                IsActive = company.IsActive,
                CreatedAt = company.CreatedAt,
                UpdatedAt = company.UpdatedAt,
                AverageRating = avgRating
            };
        }
    }
}
