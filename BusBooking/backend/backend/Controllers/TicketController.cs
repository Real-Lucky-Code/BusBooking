using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TicketController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public TicketController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/ticket/book
        [HttpPost("book")]
        public async Task<ActionResult<TicketDTO>> BookTicket([FromBody] BookTicketRequest request)
        {
            if (request.SeatIds == null || !request.SeatIds.Any())
            {
                return BadRequest(new { message = "Danh sách ghế trống" });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Normalize inputs
                var paymentMethod = (request.PaymentMethod ?? "Cash").Trim();
                var paymentMethodNormalized = paymentMethod.ToLowerInvariant();
                var promoCodeNormalized = request.PromoCode?.Trim();

                var trip = await _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == request.TripId);
                if (trip == null)
                    return BadRequest(new { message = "Chuyến đi không tìm thấy" });

                var passenger = await _context.PassengerProfiles.FindAsync(request.PassengerProfileId);
                if (passenger == null)
                    return BadRequest(new { message = "Thông tin hành khách không tìm thấy" });

                // Validate seats belong to the bus of this trip
                var seats = await _context.Seats
                    .Where(s => request.SeatIds.Contains(s.Id))
                    .ToListAsync();

                if (seats.Count != request.SeatIds.Count)
                    return BadRequest(new { message = "Một số ghế không tồn tại" });

                var seatsNotInBus = seats.Where(s => s.BusId != trip.BusId).ToList();
                if (seatsNotInBus.Any())
                {
                    var details = string.Join(", ", seatsNotInBus.Select(s => $"Ghế {s.SeatNumber} (BusId={s.BusId})"));
                    return BadRequest(new { 
                        message = "Có ghế không thuộc xe của chuyến đi này",
                        details = details,
                        expectedBusId = trip.BusId,
                        seatBusesFound = seatsNotInBus.Select(s => new { seatId = s.Id, seatNumber = s.SeatNumber, busId = s.BusId }).ToList()
                    });
                }

                // Check if seats are already booked for THIS trip
                var activeBookedSeatIds = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => request.SeatIds.Contains(ts.SeatId) 
                        && ts.Ticket != null 
                        && ts.Ticket.TripId == request.TripId
                        && ts.Ticket.Status != "Cancelled")
                    .Select(ts => ts.SeatId)
                    .ToListAsync();

                if (activeBookedSeatIds.Any())
                    return BadRequest(new { message = "Có ghế đã được đặt" });

                // Create ticket
                var ticket = new Ticket
                {
                    UserId = passenger.UserId,
                    PassengerProfileId = request.PassengerProfileId,
                    TripId = request.TripId,
                    Status = "Booked",
                    TicketCode = GenerateTicketCode(),
                    CreatedAt = DateTime.UtcNow
                };

                _context.Tickets.Add(ticket);
                await _context.SaveChangesAsync();

                // Link seats to ticket
                foreach (var seat in seats)
                {
                    var ticketSeat = new TicketSeat
                    {
                        TicketId = ticket.Id,
                        SeatId = seat.Id
                    };
                    _context.TicketSeats.Add(ticketSeat);
                }

                // Validate promotion (only online)
                var originalAmount = trip.Price * request.SeatIds.Count;
                decimal discountAmount = 0;
                string? appliedCode = null;

                if (!string.IsNullOrWhiteSpace(promoCodeNormalized))
                {
                    if (paymentMethodNormalized == "cash")
                    {
                        return BadRequest(new { message = "Mã giảm giá chỉ áp dụng cho thanh toán trực tuyến" });
                    }

                    var now = DateTime.UtcNow;
                    var promoCodeUpper = promoCodeNormalized.ToUpperInvariant();
                    var promo = await _context.Promotions
                        .FirstOrDefaultAsync(p => p.IsActive && p.Code.Trim().ToUpper() == promoCodeUpper);

                    if (promo == null)
                        return BadRequest(new { message = "Mã giảm giá không hợp lệ" });

                    if (now < promo.StartDate || now > promo.EndDate)
                        return BadRequest(new { message = "Mã giảm giá đã hết hạn hoặc chưa hiệu lực" });

                    var tripCompanyId = trip.Bus?.BusCompanyId;
                    if (promo.BusCompanyId.HasValue && promo.BusCompanyId != tripCompanyId)
                        return BadRequest(new { message = "Mã giảm giá không áp dụng cho nhà xe này" });

                    var percent = promo.DiscountPercent / 100m;
                    discountAmount = Math.Min(originalAmount * percent, originalAmount);
                    appliedCode = promo.Code;
                }

                if (paymentMethodNormalized == "cash")
                {
                    discountAmount = 0;
                    appliedCode = null;
                }

                var paidAmount = originalAmount - discountAmount;
                var payment = new Payment
                {
                    TicketId = ticket.Id,
                    Method = paymentMethod,
                    Amount = paidAmount,
                    OriginalAmount = originalAmount,
                    DiscountAmount = discountAmount,
                    PromoCode = appliedCode,
                    Status = request.PaymentMethod == "Cash" ? "Pending" : "Paid",
                    PaidAt = DateTime.UtcNow
                };
                _context.Payments.Add(payment);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return CreatedAtAction(nameof(GetTicket), new { id = ticket.Id }, await MapToTicketDTOAsync(ticket));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/ticket/validate-promo
        [HttpPost("validate-promo")]
        public async Task<ActionResult> ValidatePromo([FromBody] ValidatePromoRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.PromoCode))
                return BadRequest(new { message = "Vui lòng nhập mã giảm giá" });

            var paymentMethod = (request.PaymentMethod ?? "Cash").Trim();
            var paymentMethodNormalized = paymentMethod.ToLowerInvariant();
            if (paymentMethodNormalized == "cash")
                return BadRequest(new { message = "Mã giảm giá chỉ áp dụng cho thanh toán trực tuyến" });

            var trip = await _context.Trips
                .Include(t => t.Bus)
                .FirstOrDefaultAsync(t => t.Id == request.TripId);
            if (trip == null)
                return BadRequest(new { message = "Chuyến đi không tìm thấy" });

            var promoCodeUpper = request.PromoCode.Trim().ToUpperInvariant();
            var promo = await _context.Promotions
                .FirstOrDefaultAsync(p => p.IsActive && p.Code.Trim().ToUpper() == promoCodeUpper);

            if (promo == null)
                return BadRequest(new { message = "Mã giảm giá không hợp lệ" });

            var now = DateTime.UtcNow;
            if (now < promo.StartDate || now > promo.EndDate)
                return BadRequest(new { message = "Mã giảm giá đã hết hạn hoặc chưa hiệu lực" });

            var tripCompanyId = trip.Bus?.BusCompanyId;
            if (promo.BusCompanyId.HasValue && promo.BusCompanyId != tripCompanyId)
                return BadRequest(new { message = "Mã giảm giá không áp dụng cho nhà xe này" });

            var percent = promo.DiscountPercent / 100m;
            var seatCount = request.SeatIds?.Count ?? 0;
            var originalAmount = trip.Price * (seatCount > 0 ? seatCount : 1);
            var discountAmount = Math.Min(originalAmount * percent, originalAmount);

            return Ok(new
            {
                valid = true,
                discountPercent = percent,
                discountAmount,
                message = $"Áp dụng mã {promo.Code} giảm {promo.DiscountPercent}%"
            });
        }

        // GET: api/ticket/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<TicketDTO>> GetTicket(int id)
        {
            try
            {
                var ticket = await _context.Tickets
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus)
                            .ThenInclude(b => b.Seats)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                return Ok(await MapToTicketDTOAsync(ticket));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/ticket/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<TicketDTO>>> GetUserTickets(int userId)
        {
            try
            {
                var tickets = await _context.Tickets
                    .Where(t => t.UserId == userId)
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.Seats)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .ToListAsync();

                var ticketDTOs = new List<TicketDTO>();
                foreach (var ticket in tickets)
                {
                    ticketDTOs.Add(await MapToTicketDTOAsync(ticket));
                }

                return Ok(ticketDTOs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/ticket/trip/{tripId}
        [HttpGet("trip/{tripId}")]
        public async Task<ActionResult<List<TicketDTO>>> GetTripTickets(int tripId)
        {
            try
            {
                var tickets = await _context.Tickets
                    .Where(t => t.TripId == tripId)
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Trip!)
                        .ThenInclude(tr => tr.Bus!)
                            .ThenInclude(b => b.Seats)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .ToListAsync();

                var ticketDTOs = new List<TicketDTO>();
                foreach (var ticket in tickets)
                {
                    ticketDTOs.Add(await MapToTicketDTOAsync(ticket));
                }

                return Ok(ticketDTOs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/ticket/{id}/cancel
        [HttpPost("{id}/cancel")]
        public async Task<ActionResult> CancelTicket(int id)
        {
            try
            {
                var ticket = await _context.Tickets
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                if (ticket.Status == "Cancelled")
                    return BadRequest(new { message = "Vé đã bị hủy" });

                // Update ticket status
                ticket.Status = "Cancelled";
                _context.Tickets.Update(ticket);

                // Update payment status
                var payment = await _context.Payments.FirstOrDefaultAsync(p => p.TicketId == id);
                if (payment != null)
                {
                    payment.Status = "Refunded";
                    _context.Payments.Update(payment);
                }

                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Hủy vé thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        private string GenerateTicketCode()
        {
            return "TK" + DateTime.UtcNow.Ticks;
        }

        private async Task<TicketDTO> MapToTicketDTOAsync(Ticket ticket)
        {
            // Ensure TicketSeats are loaded
            if (ticket.TicketSeats == null || !ticket.TicketSeats.Any())
            {
                await _context.Entry(ticket)
                    .Collection(t => t.TicketSeats)
                    .Query()
                    .Include(ts => ts.Seat)
                    .Include(ts => ts.Ticket)
                    .LoadAsync();
            }

            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.TicketId == ticket.Id);
            var seats = ticket.TicketSeats?.Select(ts => ts.Seat).Where(s => s != null).ToList() ?? new List<Seat>();
            var seatDtos = seats.Select(s => MapToSeatDTO(s!, ticket.Status != "Cancelled")).ToList();

            return new TicketDTO
            {
                Id = ticket.Id,
                UserId = ticket.UserId ?? 0,
                PassengerProfileId = ticket.PassengerProfileId ?? 0,
                TripId = ticket.TripId ?? 0,
                SeatIds = seats.Select(s => s.Id).ToList(),
                Status = ticket.Status,
                TicketCode = ticket.TicketCode,
                CreatedAt = ticket.CreatedAt,
                Trip = ticket.Trip != null ? await MapToTripDTOAsync(ticket.Trip) : null,
                PassengerProfile = ticket.PassengerProfile != null ? MapToPassengerDTO(ticket.PassengerProfile) : null,
                Seats = seatDtos,
                Payment = payment != null ? MapToPaymentDTO(payment) : null
            };
        }

        private async Task<TripDTO> MapToTripDTOAsync(Trip trip)
        {
            // Ensure Bus is loaded if not already
            if (trip.Bus == null && trip.BusId.HasValue)
            {
                trip.Bus ??= _context.Buses
                    .Include(b => b.BusCompany)
                    .FirstOrDefault(b => b.Id == trip.BusId);
            }

            int? busCompanyId = trip.Bus?.BusCompanyId;
            var reviews = _context.Reviews
                .Where(r => busCompanyId == null || r.BusCompanyId == busCompanyId)
                .ToList();
            var avgRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0;

            var busSeats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();
            var seatIds = busSeats.Select(s => s.Id).ToList();
            var bookedSeatIds = await _context.TicketSeats
                .Include(ts => ts.Ticket)
                .Where(ts => seatIds.Contains(ts.SeatId) && ts.Ticket != null && ts.Ticket.Status != "Cancelled")
                .Select(ts => ts.SeatId)
                .ToListAsync();
            var bookedSeatSet = bookedSeatIds.ToHashSet();
            var availableSeats = busSeats.Count(s => !bookedSeatSet.Contains(s.Id));

            return new TripDTO
            {
                Id = trip.Id,
                BusId = trip.BusId ?? 0,
                StartLocation = trip.StartLocation,
                EndLocation = trip.EndLocation,
                DepartureTime = trip.DepartureTime,
                ArrivalTime = trip.ArrivalTime,
                Price = trip.Price,
                IsActive = trip.IsActive,
                Bus = trip.Bus != null ? MapToBusDTO(trip.Bus) : null,
                Seats = busSeats.Select(s => MapToSeatDTO(s, bookedSeatSet.Contains(s.Id))).ToList(),
                AverageRating = avgRating,
                AvailableSeats = availableSeats
            };
        }

        private BusDTO MapToBusDTO(Bus bus)
        {
            if (bus == null) return null!;
            return new BusDTO
            {
                Id = bus.Id,
                BusCompanyId = bus.BusCompanyId ?? 0,
                LicensePlate = bus.LicensePlate,
                Type = bus.Type,
                TotalSeats = bus.TotalSeats,
                ImageUrl = bus.ImageUrl,
                IsActive = bus.IsActive,
                BusCompany = bus.BusCompany != null ? new BusCompanyDTO
                {
                    Id = bus.BusCompany.Id,
                    Name = bus.BusCompany.Name,
                    Description = bus.BusCompany.Description,
                    IsApproved = bus.BusCompany.IsApproved,
                    IsActive = bus.BusCompany.IsActive,
                    CreatedAt = bus.BusCompany.CreatedAt
                } : null
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

        // POST: api/ticket/{ticketId}/cancel-request
        [HttpPost("{ticketId}/cancel-request")]
        public async Task<ActionResult> RequestCancellation(int ticketId, [FromBody] CancelTicketRequest request)
        {
            try
            {
                var ticket = await _context.Tickets
                    .Include(t => t.Trip)
                    .Include(t => t.Payment)
                    .FirstOrDefaultAsync(t => t.Id == ticketId);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                // Check if ticket is already cancelled or cancellation requested
                if (ticket.Status == "Cancelled" || ticket.Status == "CancellationRequested")
                    return BadRequest(new { message = "Vé đã bị hủy hoặc đang chờ xử lý hủy" });

                if (ticket.Status == "Completed")
                    return BadRequest(new { message = "Không thể hủy vé đã hoàn thành chuyến đi" });

                // Check 24 hour rule
                if (ticket.Trip == null || ticket.Trip.DepartureTime <= DateTime.Now.AddHours(24))
                    return BadRequest(new { message = "Chỉ có thể yêu cầu hủy vé trước 24 giờ khởi hành" });

                // Update ticket status
                ticket.Status = "CancellationRequested";
                ticket.CancellationRequestedAt = DateTime.Now;
                ticket.CancellationReason = request.Reason;
                ticket.CancellationStatus = "Pending";

                await _context.SaveChangesAsync();

                return Ok(new { message = "Yêu cầu hủy vé đã được gửi. Vui lòng chờ nhà xe xác nhận." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }
    }

    public class ValidatePromoRequest
    {
        public int TripId { get; set; }
        public List<int> SeatIds { get; set; } = new();
        public string PaymentMethod { get; set; } = "Cash";
        public string? PromoCode { get; set; }
    }
}
