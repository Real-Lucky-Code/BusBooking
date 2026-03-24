using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ReviewController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/review/buscompany/{companyId}
        [HttpGet("buscompany/{companyId}")]
        public async Task<ActionResult<List<ReviewDTO>>> GetCompanyReviews(int companyId)
        {
            try
            {
                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == companyId && r.IsActive)
                    .Include(r => r.User)
                    .ToListAsync();

                return Ok(reviews.Select(MapToReviewDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/review/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<ReviewDTO>> GetReview(int id)
        {
            try
            {
                var review = await _context.Reviews
                    .Include(r => r.User)
                    .FirstOrDefaultAsync(r => r.Id == id);

                if (review == null)
                    return NotFound(new { message = "Đánh giá không tìm thấy" });

                return Ok(MapToReviewDTO(review));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/review
        [HttpPost]
        public async Task<ActionResult<ReviewDTO>> CreateReview([FromBody] CreateReviewRequest request)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(request.BusCompanyId);
                if (company == null)
                    return BadRequest(new { message = "Nhà xe không tìm thấy" });

                // Validate rating
                if (request.Rating < 1 || request.Rating > 5)
                    return BadRequest(new { message = "Xếp hạng phải từ 1 đến 5" });

                var review = new Review
                {
                    BusCompanyId = request.BusCompanyId,
                    Rating = request.Rating,
                    Comment = request.Comment,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Reviews.Add(review);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetReview), new { id = review.Id }, MapToReviewDTO(review));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/review/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<ReviewDTO>> UpdateReview(int id, [FromBody] CreateReviewRequest request)
        {
            try
            {
                var review = await _context.Reviews
                    .Include(r => r.User)
                    .FirstOrDefaultAsync(r => r.Id == id);

                if (review == null)
                    return NotFound(new { message = "Đánh giá không tìm thấy" });

                if (request.Rating < 1 || request.Rating > 5)
                    return BadRequest(new { message = "Xếp hạng phải từ 1 đến 5" });

                review.Rating = request.Rating;
                review.Comment = request.Comment ?? review.Comment;

                _context.Reviews.Update(review);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật đánh giá thành công", review = MapToReviewDTO(review) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/review/{id}
        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteReview(int id)
        {
            try
            {
                var review = await _context.Reviews.FindAsync(id);
                if (review == null)
                    return NotFound(new { message = "Đánh giá không tìm thấy" });

                review.IsActive = false;
                _context.Reviews.Update(review);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Xóa đánh giá thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        private ReviewDTO MapToReviewDTO(Review review)
        {
            return new ReviewDTO
            {
                Id = review.Id,
                UserId = review.UserId ?? 0,
                BusCompanyId = review.BusCompanyId ?? 0,
                Rating = review.Rating,
                Comment = review.Comment,
                IsActive = review.IsActive,
                CreatedAt = review.CreatedAt,
                User = review.User != null ? MapToUserDTO(review.User) : null
            };
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
    }
}
