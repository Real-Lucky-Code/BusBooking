using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public UserController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/user/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDTO>> GetUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tìm thấy" });

                return Ok(MapToUserDTO(user));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/user/{id}/profile
        [HttpPut("{id}/profile")]
        public async Task<ActionResult<UserDTO>> UpdateProfile(int id, [FromBody] UpdateProfileRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tìm thấy" });

                user.FullName = request.FullName ?? user.FullName;
                user.Phone = request.Phone ?? user.Phone;
                user.AvatarUrl = request.AvatarUrl ?? user.AvatarUrl;

                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật thông tin thành công", user = MapToUserDTO(user) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/user/{id}/passenger-profiles
        [HttpPost("{id}/passenger-profiles")]
        public async Task<ActionResult<PassengerProfileDTO>> CreatePassengerProfile(int id, [FromBody] CreatePassengerProfileRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tìm thấy" });

                var passengerProfile = new PassengerProfile
                {
                    UserId = id,
                    FullName = request.FullName,
                    CCCD = request.CCCD,
                    Phone = request.Phone,
                    IsActive = true
                };

                _context.PassengerProfiles.Add(passengerProfile);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetPassengerProfile), new { id = passengerProfile.Id }, MapToPassengerDTO(passengerProfile));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/user/{id}/passenger-profiles
        [HttpGet("{id}/passenger-profiles")]
        public async Task<ActionResult<List<PassengerProfileDTO>>> GetPassengerProfiles(int id)
        {
            try
            {
                var profiles = await _context.PassengerProfiles
                    .Where(p => p.UserId == id && p.IsActive)
                    .ToListAsync();

                return Ok(profiles.Select(MapToPassengerDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/user/passenger-profile/{id}
        [HttpGet("passenger-profile/{id}")]
        public async Task<ActionResult<PassengerProfileDTO>> GetPassengerProfile(int id)
        {
            try
            {
                var profile = await _context.PassengerProfiles.FindAsync(id);
                if (profile == null)
                    return NotFound(new { message = "Thông tin hành khách không tìm thấy" });

                return Ok(MapToPassengerDTO(profile));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/user/passenger-profile/{id}
        [HttpPut("passenger-profile/{id}")]
        public async Task<ActionResult<PassengerProfileDTO>> UpdatePassengerProfile(int id, [FromBody] CreatePassengerProfileRequest request)
        {
            try
            {
                var profile = await _context.PassengerProfiles.FindAsync(id);
                if (profile == null)
                    return NotFound(new { message = "Thông tin hành khách không tìm thấy" });

                profile.FullName = request.FullName ?? profile.FullName;
                profile.CCCD = request.CCCD ?? profile.CCCD;
                profile.Phone = request.Phone ?? profile.Phone;

                _context.PassengerProfiles.Update(profile);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật thông tin hành khách thành công", profile = MapToPassengerDTO(profile) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/user/passenger-profile/{id}
        [HttpDelete("passenger-profile/{id}")]
        public async Task<ActionResult> DeletePassengerProfile(int id)
        {
            try
            {
                var profile = await _context.PassengerProfiles.FindAsync(id);
                if (profile == null)
                    return NotFound(new { message = "Thông tin hành khách không tìm thấy" });

                profile.IsActive = false;
                _context.PassengerProfiles.Update(profile);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Xóa thông tin hành khách thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
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

        private PassengerProfileDTO MapToPassengerDTO(PassengerProfile profile)
        {
            return new PassengerProfileDTO
            {
                Id = profile.Id,
                FullName = profile.FullName,
                CCCD = profile.CCCD,
                Phone = profile.Phone
            };
        }
    }
}
