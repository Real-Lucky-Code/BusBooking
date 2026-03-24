using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AdminController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ============= User Management =============

        // GET: api/admin/users
        [HttpGet("users")]
        public async Task<ActionResult<List<UserDTO>>> GetAllUsers()
        {
            try
            {
                var users = await _context.Users.ToListAsync();
                return Ok(users.Select(MapToUserDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/admin/users/{id}
        [HttpDelete("users/{id}")]
        public async Task<ActionResult> DeactivateUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tìm thấy" });

                user.IsActive = false;
                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Vô hiệu hóa người dùng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/admin/users/{id}/reactivate
        [HttpPut("users/{id}/reactivate")]
        public async Task<ActionResult> ReactivateUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                if (user == null)
                    return NotFound(new { message = "Người dùng không tìm thấy" });

                user.IsActive = true;
                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Kích hoạt lại người dùng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // ============= Bus Company Management =============

        // GET: api/admin/buscompanies
        [HttpGet("buscompanies")]
        public async Task<ActionResult<List<BusCompanyDTO>>> GetAllBusCompanies()
        {
            try
            {
                var companies = await _context.BusCompanies.ToListAsync();
                var reviews = await _context.Reviews.ToListAsync();

                return Ok(companies.Select(c => MapToBusCompanyDTO(c, reviews)).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/admin/buscompanies/pending
        [HttpGet("buscompanies/pending")]
        public async Task<ActionResult<List<BusCompanyDTO>>> GetPendingBusCompanies()
        {
            try
            {
                var companies = await _context.BusCompanies
                    .Where(c => !c.IsApproved)
                    .ToListAsync();

                var reviews = await _context.Reviews.ToListAsync();

                return Ok(companies.Select(c => MapToBusCompanyDTO(c, reviews)).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/admin/buscompanies/{id}/approve
        [HttpPut("buscompanies/{id}/approve")]
        public async Task<ActionResult> ApproveBusCompany(int id)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.IsApproved = true;
                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Phê duyệt nhà xe thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/admin/buscompanies/{id}/reject
        [HttpPut("buscompanies/{id}/reject")]
        public async Task<ActionResult> RejectBusCompany(int id, [FromBody] RejectCompanyRequest request)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.IsActive = false;
                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = $"Từ chối nhà xe thành công. Chủ xe có thể nộp lại thông tin.",
                    rejectionReason = request.Reason
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/admin/buscompanies/{id}
        [HttpDelete("buscompanies/{id}")]
        public async Task<ActionResult> DeactivateCompany(int id)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.IsActive = false;
                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Vô hiệu hóa nhà xe thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/admin/buscompanies/{id}/reactivate
        [HttpPut("buscompanies/{id}/reactivate")]
        public async Task<ActionResult> ReactivateCompany(int id)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.IsActive = true;
                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Kích hoạt lại nhà xe thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // ============= Statistics =============

        // GET: api/admin/statistics
        [HttpGet("statistics")]
        public async Task<ActionResult<SystemStatistics>> GetSystemStatistics()
        {
            try
            {
                var totalUsers = await _context.Users.CountAsync();
                var totalBusCompanies = await _context.BusCompanies.CountAsync();
                var approvedBusCompanies = await _context.BusCompanies.CountAsync(c => c.IsApproved);
                var totalTrips = await _context.Trips.CountAsync();
                var totalTickets = await _context.Tickets.CountAsync();
                var totalRevenue = await _context.Payments.Where(p => p.Status == "Paid").SumAsync(p => p.Amount);

                // Daily statistics (last 30 days)
                var dailyStats = new List<DailyStatistics>();
                for (int i = 29; i >= 0; i--)
                {
                    var date = DateTime.UtcNow.AddDays(-i).Date;
                    var ticketsSold = await _context.Tickets
                        .CountAsync(t => t.CreatedAt.Date == date && t.Status == "Booked");
                    var revenue = await _context.Payments
                        .Where(p => p.PaidAt.Date == date && p.Status == "Paid")
                        .SumAsync(p => p.Amount);

                    dailyStats.Add(new DailyStatistics
                    {
                        Date = date,
                        TicketsSold = ticketsSold,
                        Revenue = revenue
                    });
                }

                // Monthly statistics (last 12 months)
                var monthlyStats = new List<MonthlyStatistics>();
                for (int i = 11; i >= 0; i--)
                {
                    var now = DateTime.UtcNow;
                    var month = now.AddMonths(-i).Month;
                    var year = now.AddMonths(-i).Year;

                    var ticketsSold = await _context.Tickets
                        .CountAsync(t => t.CreatedAt.Month == month && t.CreatedAt.Year == year && t.Status == "Booked");
                    var revenue = await _context.Payments
                        .Where(p => p.PaidAt.Month == month && p.PaidAt.Year == year && p.Status == "Paid")
                        .SumAsync(p => p.Amount);

                    monthlyStats.Add(new MonthlyStatistics
                    {
                        Month = month,
                        Year = year,
                        TicketsSold = ticketsSold,
                        Revenue = revenue
                    });
                }

                var statistics = new SystemStatistics
                {
                    TotalUsers = totalUsers,
                    TotalBusCompanies = totalBusCompanies,
                    ApprovedBusCompanies = approvedBusCompanies,
                    TotalTrips = totalTrips,
                    TotalTickets = totalTickets,
                    TotalRevenue = totalRevenue,
                    DailyStats = dailyStats,
                    MonthlyStats = monthlyStats
                };

                return Ok(statistics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/admin/statistics/seats
        [HttpGet("statistics/seats")]
        public async Task<ActionResult<SeatOccupancyStatistics>> GetSeatOccupancyStatistics()
        {
            try
            {
                var totalSeats = await _context.Seats.CountAsync();
                var bookedSeats = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .CountAsync(ts => ts.Ticket != null && ts.Ticket.Status != "Cancelled");
                var availableSeats = totalSeats - bookedSeats;
                var occupancyRate = totalSeats > 0 ? (double)bookedSeats / totalSeats * 100 : 0;

                var statistics = new SeatOccupancyStatistics
                {
                    TotalSeats = totalSeats,
                    BookedSeats = bookedSeats,
                    AvailableSeats = availableSeats,
                    OccupancyRate = occupancyRate
                };

                return Ok(statistics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // ============= Review Management =============

        // GET: api/admin/reviews
        [HttpGet("reviews")]
        public async Task<ActionResult<List<ReviewDTO>>> GetAllReviews()
        {
            try
            {
                var reviews = await _context.Reviews
                    .Include(r => r.User)
                    .Include(r => r.BusCompany)
                    .ToListAsync();

                return Ok(reviews.Select(MapToReviewDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/admin/reviews/{id}
        [HttpDelete("reviews/{id}")]
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

        // PUT: api/admin/reviews/{id}/visibility
        [HttpPut("reviews/{id}/visibility")]
        public async Task<ActionResult> ToggleReviewVisibility(int id, [FromBody] ToggleReviewVisibilityRequest request)
        {
            try
            {
                var review = await _context.Reviews.FindAsync(id);
                if (review == null)
                    return NotFound(new { message = "Đánh giá không tìm thấy" });

                review.IsActive = request.IsActive;
                _context.Reviews.Update(review);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = request.IsActive ? "Hiện review thành công" : "Ẩn review thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // ============= Ticket Cancellation Management =============

        // GET: api/admin/tickets/cancellation-requests
        [HttpGet("tickets/cancellation-requests")]
        public async Task<ActionResult<List<TicketDTO>>> GetCancellationRequests()
        {
            try
            {
                var tickets = await _context.Tickets
                    .Where(t => t.Status == "CancellationRequested" && t.CancellationStatus == "Pending")
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.BusCompany)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.Payment)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .OrderBy(t => t.CancellationRequestedAt)
                    .ToListAsync();

                var ticketDTOs = tickets.Select(MapToTicketDTO).ToList();
                return Ok(ticketDTOs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/admin/tickets/{ticketId}/process-cancellation
        [HttpPost("tickets/{ticketId}/process-cancellation")]
        public async Task<ActionResult> ProcessCancellation(int ticketId, [FromBody] ProcessCancellationRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var ticket = await _context.Tickets
                    .Include(t => t.Trip)
                    .Include(t => t.Payment)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .FirstOrDefaultAsync(t => t.Id == ticketId);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                if (ticket.Status != "CancellationRequested" || ticket.CancellationStatus != "Pending")
                    return BadRequest(new { message = "Vé không ở trạng thái chờ xử lý hủy" });

                if (request.Approve)
                {
                    // Approve cancellation
                    if (request.RefundAmount == null || request.RefundAmount < 0)
                        return BadRequest(new { message = "Số tiền hoàn trả không hợp lệ" });

                    ticket.Status = "Cancelled";
                    ticket.CancellationStatus = "Approved";
                    ticket.RefundAmount = request.RefundAmount;
                    ticket.CancellationProcessedAt = DateTime.Now;
                    ticket.CancellationNote = request.Note;

                    // Update payment status
                    if (ticket.Payment != null)
                    {
                        ticket.Payment.Status = "Refunded";
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { 
                        message = $"Đã phê duyệt hủy vé. Số tiền hoàn trả: {request.RefundAmount:N0} VND",
                        refundAmount = request.RefundAmount
                    });
                }
                else
                {
                    // Reject cancellation
                    ticket.CancellationStatus = "Rejected";
                    ticket.CancellationProcessedAt = DateTime.Now;
                    ticket.CancellationNote = request.Note;
                    ticket.Status = "Booked"; // Restore to Booked status

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { message = "Đã từ chối yêu cầu hủy vé" });
                }
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        private TicketDTO MapToTicketDTO(Ticket ticket)
        {
            return new TicketDTO
            {
                Id = ticket.Id,
                UserId = ticket.UserId ?? 0,
                PassengerProfileId = ticket.PassengerProfileId ?? 0,
                TripId = ticket.TripId ?? 0,
                Status = ticket.Status,
                TicketCode = ticket.TicketCode,
                CreatedAt = ticket.CreatedAt,
                Trip = ticket.Trip != null ? MapToTripDTO(ticket.Trip) : null,
                PassengerProfile = ticket.PassengerProfile != null ? MapToPassengerDTO(ticket.PassengerProfile) : null,
                Seats = ticket.TicketSeats.Select(ts => MapToSeatDTO(ts.Seat!, ticket.Status != "Cancelled")).ToList(),
                Payment = ticket.Payment != null ? MapToPaymentDTO(ticket.Payment) : null,
                CancellationRequestedAt = ticket.CancellationRequestedAt,
                CancellationStatus = ticket.CancellationStatus,
                RefundAmount = ticket.RefundAmount,
                CancellationReason = ticket.CancellationReason,
                CancellationProcessedAt = ticket.CancellationProcessedAt,
                CancellationNote = ticket.CancellationNote
            };
        }

        private TripDTO MapToTripDTO(Trip trip)
        {
            return new TripDTO
            {
                Id = trip.Id,
                BusId = trip.BusId ?? 0,
                StartLocation = trip.StartLocation,
                EndLocation = trip.EndLocation,
                DepartureTime = trip.DepartureTime,
                ArrivalTime = trip.ArrivalTime,
                Price = trip.Price,
                AvailableSeats = 0 // Default, can be calculated if seats are loaded
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

        private SeatDTO MapToSeatDTO(Seat seat, bool isBooked)
        {
            // Mark locked seats (IsActive = false) as booked so they appear as unavailable to passengers
            var markedAsBooked = isBooked || !seat.IsActive;
            
            return new SeatDTO
            {
                Id = seat.Id,
                SeatNumber = seat.SeatNumber,
                IsBooked = markedAsBooked,
                IsActive = seat.IsActive
            };
        }

        private PaymentDTO MapToPaymentDTO(Payment payment)
        {
            return new PaymentDTO
            {
                Id = payment.Id,
                TicketId = payment.TicketId ?? 0,
                Method = payment.Method,
                Amount = payment.Amount,
                OriginalAmount = payment.OriginalAmount,
                DiscountAmount = payment.DiscountAmount,
                PromoCode = payment.PromoCode,
                Status = payment.Status,
                PaidAt = payment.PaidAt
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

        private BusCompanyDTO MapToBusCompanyDTO(BusCompany company, List<Review> allReviews)
        {
            var companyReviews = allReviews.Where(r => r.BusCompanyId == company.Id).ToList();
            var avgRating = companyReviews.Any() ? companyReviews.Average(r => r.Rating) : 0;

            return new BusCompanyDTO
            {
                Id = company.Id,
                Name = company.Name,
                Description = company.Description,
                IsApproved = company.IsApproved,
                IsActive = company.IsActive,
                ApprovalStatus = company.ApprovalStatus,
                CreatedAt = company.CreatedAt,
                AverageRating = avgRating
            };
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
                User = review.User != null ? MapToUserDTO(review.User) : null,
                BusCompany = review.BusCompany != null ? new { id = review.BusCompany.Id, name = review.BusCompany.Name } : null
            };
        }
    }
}
