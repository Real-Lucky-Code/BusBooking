using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Models;
using backend.DTOs;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BusCompanyController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BusCompanyController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/buscompany
        [HttpGet]
        public async Task<ActionResult<List<BusCompanyDTO>>> GetBusCompanies()
        {
            try
            {
                var companies = await _context.BusCompanies
                    .Where(c => c.IsActive)
                    .ToListAsync();

                var reviews = await _context.Reviews.ToListAsync();

                return Ok(companies.Select(c => MapToBusCompanyDTO(c, reviews)).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/my-company (Get current user's company - for Provider)
        [HttpGet("my-company")]
        public async Task<ActionResult<CompanyRegistrationResponse>> GetMyCompany()
        {
            try
            {
                // Try resolve user id from header/query until JWT is implemented
                if (!TryResolveUserId(out int userId))
                {
                    return BadRequest(new CompanyRegistrationResponse
                    {
                        HasCompany = false,
                        Status = "none",
                        Message = "Không thể xác định người dùng. Vui lòng đăng nhập lại."
                    });
                }

                var company = await _context.BusCompanies
                    .FirstOrDefaultAsync(c => c.OwnerId == userId);

                if (company == null)
                {
                    return Ok(new CompanyRegistrationResponse
                    {
                        HasCompany = false,
                        Status = "none",
                        Message = "Chưa đăng ký công ty"
                    });
                }

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == company.Id)
                    .ToListAsync();

                // Use ApprovalStatus field for proper status tracking
                string status = company.ApprovalStatus ?? "none";
                string message = status switch
                {
                    "pending" => "Công ty đang chờ duyệt",
                    "approved" => "Công ty đã được phê duyệt",
                    "rejected" => "Công ty bị từ chối. Vui lòng tạo lại.",
                    _ => "Công ty chưa được đăng ký"
                };

                return Ok(new CompanyRegistrationResponse
                {
                    HasCompany = true,
                    Company = MapToBusCompanyDTO(company, reviews),
                    Status = status,
                    Message = message
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/statistics (Get current user's company statistics)
        [HttpGet("statistics")]
        public async Task<ActionResult<CompanyStatistics>> GetCompanyStatistics()
        {
            try
            {
                if (!TryResolveUserId(out int userId))
                {
                    return BadRequest(new { message = "Không thể xác định người dùng" });
                }

                var company = await _context.BusCompanies
                    .FirstOrDefaultAsync(c => c.OwnerId == userId);

                if (company == null)
                {
                    return NotFound(new { message = "Công ty không tìm thấy" });
                }

                // Get company's buses
                var totalBuses = await _context.Buses
                    .CountAsync(b => b.BusCompanyId == company.Id && b.IsActive);

                // Get company's trips
                var totalTrips = await _context.Trips
                    .Where(t => t.Bus.BusCompanyId == company.Id && t.IsActive)
                    .CountAsync();

                // Get company's total bookings
                var totalBookings = await _context.Tickets
                    .Where(t => t.Trip.Bus.BusCompanyId == company.Id && t.Status == "Booked")
                    .CountAsync();

                // Get today's bookings
                var todayBookings = await _context.Tickets
                    .Where(t => t.Trip.Bus.BusCompanyId == company.Id && 
                           t.Status == "Booked" && 
                           t.CreatedAt.Date == DateTime.UtcNow.Date)
                    .CountAsync();

                // Get company's total revenue from paid tickets
                var totalRevenue = await _context.Payments
                    .Where(p => p.Ticket.Trip.Bus.BusCompanyId == company.Id && p.Status == "Paid")
                    .SumAsync(p => p.Amount);

                // Get today's revenue
                var todayRevenue = await _context.Payments
                    .Where(p => p.Ticket.Trip.Bus.BusCompanyId == company.Id && 
                           p.Status == "Paid" && 
                           p.PaidAt.Date == DateTime.UtcNow.Date)
                    .SumAsync(p => (decimal?)p.Amount) ?? 0;

                // Get company's active promotions
                var totalPromotions = await _context.Promotions
                    .Where(p => p.BusCompanyId == company.Id && p.IsActive)
                    .CountAsync();

                // Get company's reviews and average rating
                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == company.Id)
                    .ToListAsync();

                var avgRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0;

                var statistics = new CompanyStatistics
                {
                    TotalBuses = totalBuses,
                    TotalTrips = totalTrips,
                    TotalBookings = totalBookings,
                    TodayBookings = todayBookings,
                    TotalRevenue = totalRevenue,
                    TodayRevenue = todayRevenue,
                    AverageRating = avgRating,
                    TotalReviews = reviews.Count,
                    TotalPromotions = totalPromotions
                };

                return Ok(statistics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany/register-my-company (Register or resubmit company - for Provider)
        [HttpPost("register-my-company")]
        public async Task<ActionResult<BusCompanyDTO>> RegisterMyCompany([FromBody] CreateBusCompanyRequest request)
        {
            try
            {
                // Accept user id from header/query/body to avoid client failures until JWT is added
                if (!TryResolveUserId(out int userId) && !request.OwnerId.HasValue)
                {
                    return BadRequest(new { message = "Không thể xác định người dùng" });
                }

                if (!TryResolveUserId(out userId) && request.OwnerId.HasValue)
                {
                    userId = request.OwnerId.Value;
                }

                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                    return BadRequest(new { message = "Người dùng không tìm thấy" });

                if (user.Role != "Provider")
                    return BadRequest(new { message = "Chỉ chủ xe mới có thể đăng ký công ty" });

                // Check if user already has a company
                var existingCompany = await _context.BusCompanies
                    .FirstOrDefaultAsync(c => c.OwnerId == userId);

                BusCompanyDTO result;

                if (existingCompany != null)
                {
                    // Update existing company (can only update if rejected or pending)
                    if (existingCompany.IsApproved)
                    {
                        return BadRequest(new { message = "Công ty của bạn đã được phê duyệt. Không thể sửa đổi." });
                    }

                    existingCompany.Name = request.Name;
                    existingCompany.Description = request.Description;
                    existingCompany.ApprovalStatus = "pending";
                    existingCompany.IsApproved = false;
                    existingCompany.IsActive = true;
                    existingCompany.UpdatedAt = DateTime.UtcNow;

                    _context.BusCompanies.Update(existingCompany);
                    await _context.SaveChangesAsync();

                    result = MapToBusCompanyDTO(existingCompany, new List<Review>());

                    return Ok(new { 
                        success = true, 
                        message = "Cập nhật thông tin công ty thành công. Vui lòng chờ admin duyệt.", 
                        company = result 
                    });
                }
                else
                {
                    // Create new company
                    var company = new BusCompany
                    {
                        OwnerId = userId,
                        Name = request.Name,
                        Description = request.Description,
                        ApprovalStatus = "pending",
                        IsApproved = false,
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.BusCompanies.Add(company);
                    await _context.SaveChangesAsync();

                    result = MapToBusCompanyDTO(company, new List<Review>());

                    return CreatedAtAction(nameof(GetBusCompany), new { id = company.Id }, new { 
                        success = true, 
                        message = "Đăng ký công ty thành công. Vui lòng chờ admin duyệt.", 
                        company = result 
                    });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // Temporary helper to resolve user id from JWT token or fallback to header/query
        private bool TryResolveUserId(out int userId)
        {
            // Try to get from JWT token first (Authorization: Bearer <token>)
            var authHeader = Request.Headers["Authorization"].ToString();
            if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer "))
            {
                var token = authHeader.Substring("Bearer ".Length).Trim();
                try
                {
                    // Simple JWT payload decode (base64 decode middle part)
                    var parts = token.Split('.');
                    if (parts.Length == 3)
                    {
                        var payload = parts[1];
                        // Pad base64 string if needed
                        var remainder = payload.Length % 4;
                        if (remainder > 0)
                            payload += new string('=', 4 - remainder);
                        
                        var json = System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(payload));
                        var claims = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(json);
                        
                        if (claims != null)
                        {
                            // Try common JWT claim names for user ID
                            foreach (var key in new[] { "userId", "sub", "id", "nameid" })
                            {
                                if (claims.ContainsKey(key))
                                {
                                    var value = claims[key].ToString();
                                    if (int.TryParse(value, out userId))
                                        return true;
                                }
                            }
                        }
                    }
                }
                catch
                {
                    // If JWT decode fails, continue to fallback methods
                }
            }

            // Fallback: Try header X-User-Id
            var userIdHeader = Request.Headers["X-User-Id"].ToString();
            if (int.TryParse(userIdHeader, out userId))
                return true;

            // Fallback: Try query parameter userId
            var userIdQuery = Request.Query["userId"].ToString();
            if (int.TryParse(userIdQuery, out userId))
                return true;

            userId = 0;
            return false;
        }

        // GET: api/buscompany/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<BusCompanyDTO>> GetBusCompany(int id)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == id)
                    .ToListAsync();

                return Ok(MapToBusCompanyDTO(company, _context.Reviews.ToList()));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany (Register new company)
        [HttpPost]
        public async Task<ActionResult<BusCompanyDTO>> RegisterBusCompany([FromBody] CreateBusCompanyRequest request)
        {
            try
            {
                var company = new BusCompany
                {
                    Name = request.Name,
                    Description = request.Description,
                    IsApproved = false, // Pending admin approval
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                _context.BusCompanies.Add(company);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetBusCompany), new { id = company.Id }, MapToBusCompanyDTO(company, new List<Review>()));
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/buscompany/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<BusCompanyDTO>> UpdateBusCompany(int id, [FromBody] CreateBusCompanyRequest request)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.Name = request.Name ?? company.Name;
                company.Description = request.Description ?? company.Description;

                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == id)
                    .ToListAsync();

                return Ok(new { success = true, message = "Cập nhật thông tin nhà xe thành công", company = MapToBusCompanyDTO(company, _context.Reviews.ToList()) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/buscompany/{id}
        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteBusCompany(int id)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                company.IsActive = false;
                _context.BusCompanies.Update(company);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Xóa nhà xe thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany/{id}/buses
        [HttpPost("{id}/buses")]
        public async Task<ActionResult<BusDTO>> CreateBus(int id, [FromBody] CreateBusRequest request)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return BadRequest(new { message = "Nhà xe không tìm thấy" });

                var bus = new Bus
                {
                    BusCompanyId = id,
                    LicensePlate = request.LicensePlate,
                    Type = request.Type,
                    TotalSeats = request.TotalSeats,
                    ImageUrl = request.ImageUrl,
                    IsActive = true
                };

                _context.Buses.Add(bus);
                await _context.SaveChangesAsync();

                // Auto-generate seats based on predefined layouts
                var seats = new List<Seat>();
                
                switch (request.TotalSeats)
                {
                    case 22:
                        // 22 Ghế: A1-A6, B1-B6, A7-A11, B7-B11
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 7; i <= 11; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 7; i <= 11; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        break;
                    
                    case 24:
                        // 24 Ghế: A1-A6, B1-B6, A7-A12, B7-B12
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 7; i <= 12; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 7; i <= 12; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        break;
                    
                    case 34:
                        // 34 Ghế: A1-A6, B1-B5, C1-C6, A7-A12, B6-B10, C7-C12
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 1; i <= 5; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"C{i}", IsActive = true });
                        for (int i = 7; i <= 12; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 6; i <= 10; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 7; i <= 12; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"C{i}", IsActive = true });
                        break;
                    
                    case 40:
                        // 40 Ghế: A1-A7, B1-B6, C1-C7, A8-A14, B7-B12, C8-C14
                        for (int i = 1; i <= 7; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 1; i <= 6; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 1; i <= 7; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"C{i}", IsActive = true });
                        for (int i = 8; i <= 14; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"A{i}", IsActive = true });
                        for (int i = 7; i <= 12; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"B{i}", IsActive = true });
                        for (int i = 8; i <= 14; i++)
                            seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"C{i}", IsActive = true });
                        break;
                    
                    default:
                        // For other seat counts, distribute evenly across 3 rows
                        var seatsPerRow = request.TotalSeats / 3;
                        var remainder = request.TotalSeats % 3;
                        var rows = new[] { 'A', 'B', 'C' };
                        int seatIndex = 0;
                        
                        foreach (var row in rows)
                        {
                            int rowCapacity = seatsPerRow + (seatIndex < remainder ? 1 : 0);
                            for (int seatNum = 1; seatNum <= rowCapacity; seatNum++)
                                seats.Add(new Seat { BusId = bus.Id, SeatNumber = $"{row}{seatNum}", IsActive = true });
                            seatIndex++;
                        }
                        break;
                }

                _context.Seats.AddRange(seats);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Thêm xe thành công. Ghế tự động được tạo.", bus = MapToBusDTO(bus) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/{id}/buses
        [HttpGet("{id}/buses")]
        public async Task<ActionResult<List<BusDTO>>> GetBuses(int id)
        {
            try
            {
                var buses = await _context.Buses
                    .Where(b => b.BusCompanyId == id)
                    .ToListAsync();

                return Ok(buses.Select(MapToBusDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/{id}/trips
        [HttpGet("{id}/trips")]
        public async Task<ActionResult<List<TripDTO>>> GetTrips(int id, [FromQuery] ManageTripFilterRequest? filter)
        {
            try
            {
                var tripsQuery = _context.Trips
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.BusCompany)
                    .Include(t => t.Bus)
                        .ThenInclude(b => b.Seats)
                    .Where(t => t.Bus != null && t.Bus.BusCompanyId == id)
                    .AsQueryable();

                // Default show active trips unless explicitly requested otherwise
                if (filter?.IsActive.HasValue == true)
                    tripsQuery = tripsQuery.Where(t => t.IsActive == filter.IsActive.Value);
                else
                    tripsQuery = tripsQuery.Where(t => t.IsActive);

                if (!string.IsNullOrWhiteSpace(filter?.StartLocation))
                    tripsQuery = tripsQuery.Where(t => t.StartLocation.Contains(filter.StartLocation!));

                if (!string.IsNullOrWhiteSpace(filter?.EndLocation))
                    tripsQuery = tripsQuery.Where(t => t.EndLocation.Contains(filter.EndLocation!));

                if (filter?.DateFrom.HasValue == true)
                    tripsQuery = tripsQuery.Where(t => t.DepartureTime.Date >= filter.DateFrom.Value.Date);

                if (filter?.DateTo.HasValue == true)
                    tripsQuery = tripsQuery.Where(t => t.DepartureTime.Date <= filter.DateTo.Value.Date);

                if (filter?.BusId.HasValue == true)
                    tripsQuery = tripsQuery.Where(t => t.BusId == filter.BusId.Value);

                if (!string.IsNullOrWhiteSpace(filter?.BusType))
                    tripsQuery = tripsQuery.Where(t => t.Bus != null && t.Bus.Type == filter.BusType);

                var trips = await tripsQuery
                    .OrderBy(t => t.DepartureTime)
                    .ToListAsync();

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == id)
                    .ToListAsync();

                var seatIds = trips
                    .Where(t => t.Bus?.Seats != null)
                    .SelectMany(t => t.Bus.Seats)
                    .Select(s => s.Id)
                    .ToList();

                var bookedSeatIds = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => seatIds.Contains(ts.SeatId) && ts.Ticket != null && ts.Ticket.Status != "Cancelled")
                    .Select(ts => ts.SeatId)
                    .ToListAsync();

                var bookedSeatSet = bookedSeatIds.ToHashSet();

                return Ok(trips.Select(t => MapToTripDTOForCompany(t, reviews, bookedSeatSet)).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany/{id}/trips (create trip for this company)
        [HttpPost("{id}/trips")]
        public async Task<ActionResult> CreateTripForCompany(int id, [FromBody] CreateTripRequest request)
        {
            try
            {
                var bus = await _context.Buses
                    .Include(b => b.BusCompany)
                    .FirstOrDefaultAsync(b => b.Id == request.BusId);

                if (bus == null)
                    return BadRequest(new { message = "Xe không tìm thấy" });

                if (bus.BusCompanyId != id)
                    return BadRequest(new { message = "Xe không thuộc nhà xe này" });

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

                trip = await _context.Trips
                    .Include(t => t.Bus)!.ThenInclude(b => b.Seats)
                    .Include(t => t.Bus)!.ThenInclude(b => b.BusCompany)
                    .FirstAsync(t => t.Id == trip.Id);

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == bus.BusCompanyId)
                    .ToListAsync();

                var busSeats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();

                return Ok(new { success = true, message = "Tạo chuyến đi thành công", trip = MapToTripDTOForCompany(trip, reviews, new HashSet<int>()) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/buscompany/{id}/trips/{tripId} (update trip for this company)
        [HttpPut("{id}/trips/{tripId}")]
        public async Task<ActionResult> UpdateTripForCompany(int id, int tripId, [FromBody] CreateTripRequest request)
        {
            try
            {
                var trip = await _context.Trips
                    .Include(t => t.Bus)!.ThenInclude(b => b.BusCompany)
                    .Include(t => t.Bus)!.ThenInclude(b => b.Seats)
                    .FirstOrDefaultAsync(t => t.Id == tripId);

                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                if (trip.Bus?.BusCompanyId != id)
                    return BadRequest(new { message = "Chuyến đi không thuộc nhà xe này" });

                // Optional: allow switching bus within same company
                if (request.BusId != 0 && request.BusId != trip.BusId)
                {
                    var newBus = await _context.Buses.FirstOrDefaultAsync(b => b.Id == request.BusId && b.BusCompanyId == id);
                    if (newBus == null)
                        return BadRequest(new { message = "Xe mới không hợp lệ" });
                    trip.BusId = request.BusId;
                }

                trip.StartLocation = string.IsNullOrWhiteSpace(request.StartLocation) ? trip.StartLocation : request.StartLocation;
                trip.EndLocation = string.IsNullOrWhiteSpace(request.EndLocation) ? trip.EndLocation : request.EndLocation;
                trip.DepartureTime = request.DepartureTime;
                trip.ArrivalTime = request.ArrivalTime;
                trip.Price = request.Price;

                _context.Trips.Update(trip);
                await _context.SaveChangesAsync();

                var reviews = await _context.Reviews
                    .Where(r => r.BusCompanyId == trip.Bus!.BusCompanyId)
                    .ToListAsync();

                var seatIds = trip.Bus?.Seats?.Select(s => s.Id).ToList() ?? new List<int>();
                var bookedSeatIds = await _context.TicketSeats
                    .Include(ts => ts.Ticket)
                    .Where(ts => seatIds.Contains(ts.SeatId) && ts.Ticket != null && ts.Ticket.Status != "Cancelled")
                    .Select(ts => ts.SeatId)
                    .ToListAsync();

                return Ok(new { success = true, message = "Cập nhật chuyến đi thành công", trip = MapToTripDTOForCompany(trip, reviews, bookedSeatIds.ToHashSet()) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/buscompany/{id}/trips/{tripId}
        [HttpDelete("{id}/trips/{tripId}")]
        public async Task<ActionResult> DeleteTripForCompany(int id, int tripId)
        {
            try
            {
                var trip = await _context.Trips
                    .Include(t => t.Bus)
                    .FirstOrDefaultAsync(t => t.Id == tripId);

                if (trip == null)
                    return NotFound(new { message = "Chuyến đi không tìm thấy" });

                if (trip.Bus?.BusCompanyId != id)
                    return BadRequest(new { message = "Chuyến đi không thuộc nhà xe này" });

                // Hard delete - remove from database completely
                _context.Trips.Remove(trip);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã xóa chuyến đi hoàn toàn" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/buscompany/bus/{id}
        [HttpPut("bus/{id}/toggle-status")]
        public async Task<ActionResult> ToggleBusStatus(int id)
        {
            try
            {
                var bus = await _context.Buses.FindAsync(id);
                if (bus == null)
                    return NotFound(new { message = "Xe không tìm thấy" });

                bus.IsActive = !bus.IsActive;
                _context.Buses.Update(bus);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = bus.IsActive ? "Kích hoạt xe thành công" : "Tạm dừng xe thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        [HttpPut("bus/{id}")]
        public async Task<ActionResult<BusDTO>> UpdateBus(int id, [FromBody] CreateBusRequest request)
        {
            try
            {
                var bus = await _context.Buses.FindAsync(id);
                if (bus == null)
                    return NotFound(new { message = "Xe không tìm thấy" });

                bus.LicensePlate = request.LicensePlate ?? bus.LicensePlate;
                bus.Type = request.Type ?? bus.Type;
                bus.TotalSeats = request.TotalSeats > 0 ? request.TotalSeats : bus.TotalSeats;
                bus.ImageUrl = request.ImageUrl ?? bus.ImageUrl;

                _context.Buses.Update(bus);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật thông tin xe thành công", bus = MapToBusDTO(bus) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/buscompany/bus/{id}
        [HttpDelete("bus/{id}")]
        public async Task<ActionResult> DeleteBus(int id)
        {
            try
            {
                var bus = await _context.Buses
                    .Include(b => b.Seats)
                    .FirstOrDefaultAsync(b => b.Id == id);
                    
                if (bus == null)
                    return NotFound(new { message = "Xe không tìm thấy" });

                // Hard delete - remove from database completely
                // Remove all seats first (cascade should handle this but being explicit)
                if (bus.Seats != null && bus.Seats.Any())
                {
                    _context.Seats.RemoveRange(bus.Seats);
                }
                
                _context.Buses.Remove(bus);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã xóa xe hoàn toàn" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        [HttpGet("bus/{busId}/seats")]
        public async Task<ActionResult<List<object>>> GetBusSeats(int busId)
        {
            try
            {
                var bus = await _context.Buses
                    .Include(b => b.Seats)
                    .FirstOrDefaultAsync(b => b.Id == busId);
                
                if (bus == null)
                    return NotFound(new { message = "Xe không tìm thấy" });

                var seatsData = bus.Seats
                    .OrderBy(s => s.SeatNumber)
                    .Select(s => new
                    {
                        s.Id,
                        s.SeatNumber,
                        s.IsActive,
                        BusId = busId,
                        BusType = bus.Type,
                        TotalSeats = bus.TotalSeats
                    })
                    .ToList<object>();

                return Ok(seatsData);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/buscompany/bus/{busId}/seats/{seatId}
        [HttpPut("bus/{busId}/seats/{seatId}")]
        public async Task<ActionResult> UpdateBusSeat(int busId, int seatId, [FromBody] UpdateSeatRequest request)
        {
            try
            {
                var bus = await _context.Buses.FindAsync(busId);
                if (bus == null)
                    return NotFound(new { message = "Xe không tìm thấy" });

                var seat = await _context.Seats.FirstOrDefaultAsync(s => s.Id == seatId && s.BusId == busId);
                if (seat == null)
                    return NotFound(new { message = "Ghế không tìm thấy" });

                if (!string.IsNullOrEmpty(request.SeatNumber))
                    seat.SeatNumber = request.SeatNumber;

                if (request.IsActive.HasValue)
                    seat.IsActive = request.IsActive.Value;

                _context.Seats.Update(seat);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật thông tin ghế thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany/{id}/promotions
        [HttpPost("{id}/promotions")]
        public async Task<ActionResult<PromotionDTO>> CreatePromotion(int id, [FromBody] CreatePromotionRequest request)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return BadRequest(new { message = "Nhà xe không tìm thấy" });

                var promotion = new Promotion
                {
                    BusCompanyId = id,
                    Code = request.Code,
                    DiscountPercent = request.DiscountPercent,
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    IsActive = true
                };

                _context.Promotions.Add(promotion);
                await _context.SaveChangesAsync();

                return Created($"/api/buscompany/{id}/promotions/{promotion.Id}", new { success = true, data = MapToPromotionDTO(promotion) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/{id}/promotions
        [HttpGet("{id}/promotions")]
        public async Task<ActionResult<List<PromotionDTO>>> GetPromotions(int id)
        {
            try
            {
                var promotions = await _context.Promotions
                    .Where(p => p.BusCompanyId == id && p.IsActive)
                    .ToListAsync();

                return Ok(promotions.Select(MapToPromotionDTO).ToList());
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // PUT: api/buscompany/{id}/promotions/{promotionId}
        [HttpPut("{id}/promotions/{promotionId}")]
        public async Task<ActionResult<PromotionDTO>> UpdatePromotion(int id, int promotionId, [FromBody] CreatePromotionRequest request)
        {
            try
            {
                var promotion = await _context.Promotions
                    .FirstOrDefaultAsync(p => p.Id == promotionId && p.BusCompanyId == id);

                if (promotion == null)
                    return NotFound(new { message = "Khuyến mãi không tìm thấy" });

                promotion.Code = request.Code ?? promotion.Code;
                promotion.DiscountPercent = request.DiscountPercent > 0 ? request.DiscountPercent : promotion.DiscountPercent;
                promotion.StartDate = request.StartDate;
                promotion.EndDate = request.EndDate;

                _context.Promotions.Update(promotion);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Cập nhật khuyến mãi thành công", promotion = MapToPromotionDTO(promotion) });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // DELETE: api/buscompany/{id}/promotions/{promotionId} (Hard delete - mark as inactive)
        [HttpDelete("{id}/promotions/{promotionId}")]
        public async Task<ActionResult> DeletePromotion(int id, int promotionId)
        {
            try
            {
                var promotion = await _context.Promotions
                    .FirstOrDefaultAsync(p => p.Id == promotionId && p.BusCompanyId == id);

                if (promotion == null)
                    return NotFound(new { message = "Khuyến mãi không tìm thấy" });

                promotion.IsActive = false;
                _context.Promotions.Update(promotion);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã xóa khuyến mãi" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/buscompany/{id}/bookings - Get list of bookings for company's trips
        [HttpGet("{id}/bookings")]
        public async Task<ActionResult<List<BookingDTO>>> GetCompanyBookings(int id, 
            [FromQuery] string? status = null,
            [FromQuery] int? tripId = null,
            [FromQuery] DateTime? fromDate = null,
            [FromQuery] DateTime? toDate = null)
        {
            try
            {
                var company = await _context.BusCompanies.FindAsync(id);
                if (company == null)
                    return NotFound(new { message = "Nhà xe không tìm thấy" });

                // Get all trips for this company
                var companyTripIds = await _context.Trips
                    .Where(t => t.Bus != null && t.Bus.BusCompanyId == id)
                    .Select(t => t.Id)
                    .ToListAsync();

                // Build query for tickets
                var query = _context.Tickets
                    .Include(t => t.Trip)
                        .ThenInclude(trip => trip!.Bus)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.Payment)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .Where(t => t.TripId.HasValue && companyTripIds.Contains(t.TripId.Value));

                // Apply filters
                if (!string.IsNullOrEmpty(status))
                    query = query.Where(t => t.Status == status);

                if (tripId.HasValue)
                    query = query.Where(t => t.TripId == tripId.Value);

                if (fromDate.HasValue)
                    query = query.Where(t => t.CreatedAt >= fromDate.Value);

                if (toDate.HasValue)
                    query = query.Where(t => t.CreatedAt <= toDate.Value);

                var tickets = await query
                    .OrderByDescending(t => t.CreatedAt)
                    .ToListAsync();

                var bookings = tickets.Select(ticket => new BookingDTO
                {
                    Id = ticket.Id,
                    TicketCode = ticket.TicketCode,
                    Status = ticket.Status,
                    CreatedAt = ticket.CreatedAt,
                    PassengerName = ticket.PassengerProfile?.FullName ?? "N/A",
                    PassengerPhone = ticket.PassengerProfile?.Phone ?? "N/A",
                    PassengerCCCD = ticket.PassengerProfile?.CCCD ?? "N/A",
                    TripId = ticket.TripId ?? 0,
                    StartLocation = ticket.Trip?.StartLocation ?? "N/A",
                    EndLocation = ticket.Trip?.EndLocation ?? "N/A",
                    DepartureTime = ticket.Trip?.DepartureTime ?? DateTime.MinValue,
                    BusLicensePlate = ticket.Trip?.Bus?.LicensePlate ?? "N/A",
                    SeatNumbers = ticket.TicketSeats.Select(ts => ts.Seat?.SeatNumber ?? "").Where(s => !string.IsNullOrEmpty(s)).ToList(),
                    TotalAmount = ticket.Payment?.Amount ?? 0,
                    PaymentMethod = ticket.Payment?.Method ?? "N/A",
                    CancellationRequestedAt = ticket.CancellationRequestedAt,
                    CancellationStatus = ticket.CancellationStatus,
                    CancellationReason = ticket.CancellationReason,
                    RefundAmount = ticket.RefundAmount
                }).ToList();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
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

        private BusDTO MapToBusDTO(Bus bus)
        {
            if (bus == null)
            {
                return new BusDTO();
            }

            return new BusDTO
            {
                Id = bus.Id,
                BusCompanyId = bus.BusCompanyId ?? 0,
                LicensePlate = bus.LicensePlate,
                Type = bus.Type,
                TotalSeats = bus.TotalSeats,
                ImageUrl = bus.ImageUrl,
                IsActive = bus.IsActive
            };
        }

        private PromotionDTO MapToPromotionDTO(Promotion promotion)
        {
            return new PromotionDTO
            {
                Id = promotion.Id,
                BusCompanyId = promotion.BusCompanyId ?? 0,
                Code = promotion.Code,
                DiscountPercent = promotion.DiscountPercent,
                StartDate = promotion.StartDate,
                EndDate = promotion.EndDate,
                IsActive = promotion.IsActive
            };
        }

        private TripDTO MapToTripDTOForCompany(Trip trip, List<Review> allReviews, HashSet<int> bookedSeatIds)
        {
            var companyReviews = allReviews.Where(r => r.BusCompanyId == trip.Bus?.BusCompanyId).ToList();
            var avgRating = companyReviews.Any() ? companyReviews.Average(r => r.Rating) : 0;

            var seats = trip.Bus?.Seats?.ToList() ?? new List<Seat>();
            var seatDtos = seats.Select(s => new SeatDTO
            {
                Id = s.Id,
                SeatNumber = s.SeatNumber,
                IsBooked = bookedSeatIds.Contains(s.Id),
                IsActive = s.IsActive
            }).ToList();

            var availableSeats = seatDtos.Count(s => !s.IsBooked);

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
                Seats = seatDtos,
                AverageRating = avgRating,
                AvailableSeats = availableSeats
            };
        }

        // ============= Ticket Cancellation Management (for Company) =============

        // GET: api/buscompany/cancellation-requests
        [HttpGet("cancellation-requests")]
        public async Task<ActionResult<List<BookingDTO>>> GetCancellationRequests()
        {
            try
            {
                // Get current user's company
                if (!TryResolveUserId(out int userId))
                {
                    return BadRequest(new { message = "Không thể xác định người dùng" });
                }

                var company = await _context.BusCompanies
                    .FirstOrDefaultAsync(c => c.OwnerId == userId);

                if (company == null)
                {
                    return BadRequest(new { message = "Không tìm thấy công ty của bạn" });
                }

                // Get all buses for this company
                var companyBusIds = await _context.Buses
                    .Where(b => b.BusCompanyId == company.Id)
                    .Select(b => b.Id)
                    .ToListAsync();

                // Get all cancellation requests for tickets on company's buses
                var tickets = await _context.Tickets
                    .Where(t => t.Status == "CancellationRequested" && t.CancellationStatus == "Pending"
                        && t.Trip != null && companyBusIds.Contains(t.Trip.BusId ?? 0))
                    .Include(t => t.Trip)!
                        .ThenInclude(tr => tr.Bus)
                    .Include(t => t.PassengerProfile)
                    .Include(t => t.Payment)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .OrderBy(t => t.CancellationRequestedAt)
                    .ToListAsync();

                var bookings = tickets.Select(ticket => new BookingDTO
                {
                    Id = ticket.Id,
                    TicketCode = ticket.TicketCode,
                    Status = ticket.Status,
                    CreatedAt = ticket.CreatedAt,
                    PassengerName = ticket.PassengerProfile?.FullName ?? "N/A",
                    PassengerPhone = ticket.PassengerProfile?.Phone ?? "N/A",
                    PassengerCCCD = ticket.PassengerProfile?.CCCD ?? "N/A",
                    TripId = ticket.TripId ?? 0,
                    StartLocation = ticket.Trip?.StartLocation ?? "N/A",
                    EndLocation = ticket.Trip?.EndLocation ?? "N/A",
                    DepartureTime = ticket.Trip?.DepartureTime ?? DateTime.MinValue,
                    BusLicensePlate = ticket.Trip?.Bus?.LicensePlate ?? "N/A",
                    SeatNumbers = ticket.TicketSeats.Select(ts => ts.Seat?.SeatNumber ?? "").Where(s => !string.IsNullOrEmpty(s)).ToList(),
                    TotalAmount = ticket.Payment?.Amount ?? 0,
                    PaymentMethod = ticket.Payment?.Method ?? "N/A",
                    CancellationRequestedAt = ticket.CancellationRequestedAt,
                    CancellationStatus = ticket.CancellationStatus,
                    CancellationReason = ticket.CancellationReason,
                    RefundAmount = ticket.RefundAmount
                }).ToList();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/buscompany/tickets/{ticketId}/process-cancellation
        [HttpPost("tickets/{ticketId}/process-cancellation")]
        public async Task<ActionResult> ProcessCancellation(int ticketId, [FromBody] ProcessCancellationRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Get current user's company
                if (!TryResolveUserId(out int userId))
                {
                    return BadRequest(new { message = "Không thể xác định người dùng" });
                }

                var company = await _context.BusCompanies
                    .FirstOrDefaultAsync(c => c.OwnerId == userId);

                if (company == null)
                {
                    return BadRequest(new { message = "Không tìm thấy công ty của bạn" });
                }

                var ticket = await _context.Tickets
                    .Include(t => t.Trip)
                    .Include(t => t.Payment)
                    .Include(t => t.TicketSeats)
                        .ThenInclude(ts => ts.Seat)
                    .FirstOrDefaultAsync(t => t.Id == ticketId);

                if (ticket == null)
                    return NotFound(new { message = "Vé không tìm thấy" });

                // Verify this ticket belongs to company's bus
                var bus = await _context.Buses
                    .FirstOrDefaultAsync(b => b.Id == ticket.Trip!.BusId && b.BusCompanyId == company.Id);

                if (bus == null)
                    return Forbid(); // Unauthorized - ticket doesn't belong to this company

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
                TicketCode = ticket.TicketCode,
                Status = ticket.Status,
                CreatedAt = ticket.CreatedAt,
                PassengerProfile = ticket.PassengerProfile != null ? new PassengerProfileDTO
                {
                    Id = ticket.PassengerProfile.Id,
                    FullName = ticket.PassengerProfile.FullName,
                    CCCD = ticket.PassengerProfile.CCCD,
                    Phone = ticket.PassengerProfile.Phone,
                } : null,
                Trip = ticket.Trip != null ? MapToTripDTOForCompany(ticket.Trip, new List<Review>(), new HashSet<int>()) : null,
                CancellationStatus = ticket.CancellationStatus,
                CancellationReason = ticket.CancellationReason,
                CancellationRequestedAt = ticket.CancellationRequestedAt,
                RefundAmount = ticket.RefundAmount
            };
        }
    }
}
