using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TripController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public TripController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/trip/search
        [HttpPost("search")]
        public async Task<ActionResult<List<TripDTO>>> SearchTrips([FromBody] SearchTripRequest request)
        {
            try
            {
                var query = _context.Trips
                    .Where(t => t.IsActive)
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .AsQueryable();

                // Exclude trips whose bus is inactive
                query = query.Where(t => t.Bus != null && t.Bus.IsActive);

                // Filter by location
                if (!string.IsNullOrEmpty(request.StartLocation))
                    query = query.Where(t => t.StartLocation.Contains(request.StartLocation));

                if (!string.IsNullOrEmpty(request.EndLocation))
                    query = query.Where(t => t.EndLocation.Contains(request.EndLocation));

                // Filter by date
                query = query.Where(t => t.DepartureTime.Date == request.DepartureDate.Date);

                // Filter by price
                if (request.MinPrice.HasValue)
                    query = query.Where(t => t.Price >= request.MinPrice);
                if (request.MaxPrice.HasValue)
                    query = query.Where(t => t.Price <= request.MaxPrice);

                // Filter by bus type
                if (!string.IsNullOrEmpty(request.BusType))
                    query = query.Where(t => t.Bus.Type == request.BusType);

                // Filter by bus company
                if (request.BusCompanyId.HasValue)
                    query = query.Where(t => t.Bus.BusCompanyId == request.BusCompanyId);

                // Filter by departure hour
                if (request.DepartureHourStart.HasValue)
                    query = query.Where(t => t.DepartureTime.Hour >= request.DepartureHourStart);
                if (request.DepartureHourEnd.HasValue)
                    query = query.Where(t => t.DepartureTime.Hour < request.DepartureHourEnd);

                var trips = await query.ToListAsync();
                var reviews = await _context.Reviews.ToListAsync();

                // Get all bus seat IDs from these trips
                var busIds = trips.Select(t => t.BusId).Distinct().ToList();
                var allSeats = await _context.Seats
                    .Where(s => busIds.Contains(s.BusId))
                    .ToListAsync();

                // Get booked seat IDs for each trip
                var tripIds = trips.Select(t => t.Id).ToList();
                var bookedSeatsPerTrip = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => ts.Ticket != null && tripIds.Contains(ts.Ticket.TripId ?? 0) && ts.Ticket.Status != "Cancelled")
                    .Select(ts => new { ts.SeatId, TripId = ts.Ticket!.TripId ?? 0 })
                    .ToListAsync();

                return Ok(trips.Select(t =>
                {
                    var tripSeats = allSeats.Where(s => s.BusId == t.BusId).Select(s => s.Id).ToHashSet();
                    var bookedInTrip = bookedSeatsPerTrip.Where(bs => bs.TripId == t.Id).Select(bs => bs.SeatId).ToHashSet();
                    return MapToTripDTO(t, allSeats.Where(s => s.BusId == t.BusId).ToList(), reviews, bookedInTrip);
                }).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/trip/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<TripDTO>> GetTrip(int id)
        {
            try
            {
                var trip = await _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == trip.Bus.BusCompanyId)
                    .ToListAsync();

                // Get bus seats
                var busSeats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();
                var seatIds = busSeats.Select(s => s.Id).ToList();
                
                // Get booked seats for THIS trip only
                var bookedSeatIds = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => seatIds.Contains(ts.SeatId) 
                        && ts.Ticket != null 
                        && ts.Ticket.TripId == id
                        && ts.Ticket.Status != "Cancelled")
                    .Select(ts => ts.SeatId)
                    .ToListAsync();

                return Ok(MapToTripDTO(trip, busSeats, reviews, bookedSeatIds.ToHashSet()));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/trip (For Bus Company)
        [HttpPost]
        public async Task<ActionResult<TripDTO>> CreateTrip([FromBody] CreateTripRequest request)
        {
            try
            {
                var bus = await _context.Buses.FindAsync(request.BusId);
                if (bus == null)
                    return BadRequest(new { message = "Xe không tìm thấy" });

                var trip = new Trip
                {
                    BusId = request.BusId,
                    StartLocation = request.StartLocation,
                    EndLocation = request.EndLocation,
                    DepartureTime = request.DepartureTime,
                    ArrivalTime = request.ArrivalTime,
                    Price = request.Price,
                    IsActive = true
                };

                _context.Trips.Add(trip);
                await _context.SaveChangesAsync();

                // Load trip with bus and seats
                trip = await _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == trip.Id);

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == bus.BusCompanyId)
                    .ToListAsync();

                var busSeats = trip?.Bus?.Seats?.ToList() ?? new List<Seat>();
                return CreatedAtAction(nameof(GetTrip), new { id = trip.Id }, MapToTripDTO(trip, busSeats, reviews, new HashSet<int>()));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/trip/{id} (For Bus Company)
        [HttpPut("{id}")]
        public async Task<ActionResult<TripDTO>> UpdateTrip(int id, [FromBody] CreateTripRequest request)
        {
            try
            {
                var trip = await _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                trip.StartLocation = request.StartLocation ?? trip.StartLocation;
                trip.EndLocation = request.EndLocation ?? trip.EndLocation;
                trip.DepartureTime = request.DepartureTime;
                trip.ArrivalTime = request.ArrivalTime;
                trip.Price = request.Price;

                _context.Trips.Update(trip);
                await _context.SaveChangesAsync();

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == trip.Bus.BusCompanyId)
                    .ToListAsync();

                var busSeats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();
                var seatIds = busSeats.Select(s => s.Id).ToList();
                var bookedSeatIds = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => seatIds.Contains(ts.SeatId) && ts.Ticket != null && ts.Ticket.Status != "Cancelled")
                    .Select(ts => ts.SeatId)
                    .ToListAsync();

                return Ok(new { success = true, message = "Cập nhật chuyến đi thành công", trip = MapToTripDTO(trip, busSeats, reviews, bookedSeatIds.ToHashSet()) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/trip/{id} (For Bus Company)
        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteTrip(int id)
        {
            try
            {
                var trip = await _context.Trips.FindAsync(id);
                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                trip.IsActive = false;
                _context.Trips.Update(trip);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Xóa chuyến đi thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/trip/{id}/bookings (For Bus Company - get passenger list)
        [HttpGet("{id}/bookings")]
        public async Task<ActionResult> GetTripBookings(int id)
        {
            try
            {
                var trip = await _context.Trips.FindAsync(id);
                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                var tickets = await _context.Tickets
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.Payment)
                    .Where(t => t.TripId == id && t.Status != "Cancelled")
                    .ToListAsync();

                var ticketIds = tickets.Select(t => t.Id).ToList();
                var ticketSeats = await _context.TicketSeats
                    .Include(ts => ts.Seat)
                    .Where(ts => ticketIds.Contains(ts.TicketId))
                    .ToListAsync();

                var bookings = tickets.Select(ticket =>
                {
                    var seats = ticketSeats
                        .Where(ts => ts.TicketId == ticket.Id)
                        .Select(ts => ts.Seat?.SeatNumber ?? "")
                        .ToList();

                    var payment = ticket.Payment;
                    var paymentStatus = payment?.Status == "Completed" ? "Đã thanh toán" : "Chưa thanh toán";
                    var boardingStatus = ticket.Status == "Completed" ? "Đã lên xe" : "Chưa lên xe";

                    return new
                    {
                        id = ticket.Id,
                        passengerName = ticket.PassengerProfile?.FullName ?? "Chưa có tên",
                        phone = ticket.PassengerProfile?.Phone ?? "",
                        seatNumbers = seats,
                        paymentStatus,
                        bookingTime = ticket.CreatedAt,
                        boardingStatus,
                        paidAmount = payment?.Amount ?? 0
                    };
                }).ToList();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/trip/{tripId}/bookings/{ticketId}/checkin
        [HttpPut("{tripId}/bookings/{ticketId}/checkin")]
        public async Task<ActionResult> CheckInPassenger(int tripId, int ticketId)
        {
            try
            {
                var ticket = await _context.Tickets
                    .FirstOrDefaultAsync(t => t.Id == ticketId && t.TripId == tripId);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                ticket.Status = ticket.Status == "Completed" ? "Booked" : "Completed";
                _context.Tickets.Update(ticket);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = ticket.Status == "Completed" ? "Đã check-in" : "Đã hủy check-in",
                    boardingStatus = ticket.Status == "Completed" ? "Đã lên xe" : "Chưa lên xe"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/trip/{id}/seats (For Bus Company - get seat layout)
        [HttpGet("{id}/seats")]
        public async Task<ActionResult> GetTripSeats(int id)
        {
            try
            {
                var trip = await _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                var busSeats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();
                var seatIds = busSeats.Select(s => s.Id).ToList();
                var ticketSeats = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .ThenInclude(t => t.PassengerProfile)
                    .Where(ts => seatIds.Contains(ts.SeatId) && ts.Ticket != null && ts.Ticket.TripId == id)
                    .ToListAsync();

                var seats = busSeats.Select(seat =>
                {
                    var activeTicketSeat = ticketSeats.FirstOrDefault(ts => ts.SeatId == seat.Id && ts.Ticket != null && ts.Ticket.Status != "Cancelled");
                    var passengerName = activeTicketSeat?.Ticket?.PassengerProfile?.FullName;
                    var isBooked = activeTicketSeat != null;

                    return new
                    {
                        number = seat.SeatNumber,
                        isBooked = isBooked,
                        bookedBy = passengerName
                    };
                }).ToList();

                return Ok(seats);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/trip/{tripId}/seats/{seatNumber}/release
        [HttpPut("{tripId}/seats/{seatNumber}/release")]
        public async Task<ActionResult> ReleaseSeat(int tripId, string seatNumber)
        {
            try
            {
                var trip = await _context.Trips.FindAsync(tripId);
                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                var seat = await _context.Seats
                    .FirstOrDefaultAsync(s => s.BusId == trip.BusId && s.SeatNumber == seatNumber);

                if (seat == null)
                    return NotFound(new { message = "Ghế không tìm thấy" });

                var ticketSeat = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .FirstOrDefaultAsync(ts => ts.SeatId == seat.Id && ts.Ticket != null && ts.Ticket.Status != "Cancelled");

                if (ticketSeat?.Ticket == null)
                    return BadRequest(new { message = "Ghế này chưa được đặt" });

                ticketSeat.Ticket.Status = "Cancelled";
                _context.Tickets.Update(ticketSeat.Ticket);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã hủy đặt ghế thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        private TripDTO MapToTripDTO(Trip trip, List<Seat> seats, List<Review> allReviews, HashSet<int>? bookedSeatIds = null)
        {
            bookedSeatIds ??= new HashSet<int>();
            var companyReviews = allReviews.Where(r => r.BusCompanyId == trip.Bus?.BusCompanyId).ToList();
            var avgRating = companyReviews.Any() ? companyReviews.Average(r => r.Rating) : 0;
            // Available seats = total seats - booked seats - locked seats (IsActive = false)
            var availableSeats = seats.Count(s => !bookedSeatIds.Contains(s.Id) && s.IsActive);

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
                Bus = MapToBusDTO(trip.Bus),
                Seats = seats.Select(s => MapToSeatDTO(s, bookedSeatIds.Contains(s.Id))).ToList(),
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
    }
}
