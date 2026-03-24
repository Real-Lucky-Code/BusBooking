using backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace backend.InsertDatabase
{
    public static class DataSeeder
    {
        public static async Task SeedAsync(ApplicationDbContext db)
        {
            // Chỉ migrate (không xóa) để giữ dữ liệu đã có
            await db.Database.MigrateAsync();

            // Nếu đã có dữ liệu, bỏ qua seeding
            if (db.Users.Any() || db.BusCompanies.Any()) return;

            var now = DateTime.UtcNow;

            // Bus companies (10)
            // Users (12) - Create first so we can assign OwnerId to BusCompanies
            var users = new List<User>
            {
                new() { Email = "provider1@haiau.vn", PasswordHash = "hashed", FullName = "Nguyễn Văn A", Phone = "0901000001", AvatarUrl = "https://via.placeholder.com/100", Role = "Provider", IsActive = true, CreatedAt = now.AddDays(-18) },
                new() { Email = "provider2@futa.vn", PasswordHash = "hashed", FullName = "Trần Thị B", Phone = "0901000002", AvatarUrl = "https://via.placeholder.com/100", Role = "Provider", IsActive = true, CreatedAt = now.AddDays(-17) },
                new() { Email = "provider3@hoanglong.vn", PasswordHash = "hashed", FullName = "Lê Văn C", Phone = "0901000003", AvatarUrl = "https://via.placeholder.com/100", Role = "Provider", IsActive = true, CreatedAt = now.AddDays(-16) },
                new() { Email = "admin@busticket.vn", PasswordHash = "hashed", FullName = "System Admin", Phone = "0901000000", AvatarUrl = "https://via.placeholder.com/100", Role = "Admin", IsActive = true, CreatedAt = now.AddDays(-15) },
                new() { Email = "user1@example.com", PasswordHash = "hashed", FullName = "Phạm Minh Đức", Phone = "0902000001", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-14) },
                new() { Email = "user2@example.com", PasswordHash = "hashed", FullName = "Vũ Thảo", Phone = "0902000002", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-13) },
                new() { Email = "user3@example.com", PasswordHash = "hashed", FullName = "Ngô Tuấn", Phone = "0902000003", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-12) },
                new() { Email = "user4@example.com", PasswordHash = "hashed", FullName = "Đỗ Mai", Phone = "0902000004", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-11) },
                new() { Email = "user5@example.com", PasswordHash = "hashed", FullName = "Bùi Quang", Phone = "0902000005", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-10) },
                new() { Email = "user6@example.com", PasswordHash = "hashed", FullName = "Phan Thanh", Phone = "0902000006", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-9) },
                new() { Email = "user7@example.com", PasswordHash = "hashed", FullName = "Trương Hải", Phone = "0902000007", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-8) },
                new() { Email = "user8@example.com", PasswordHash = "hashed", FullName = "Huỳnh Như", Phone = "0902000008", AvatarUrl = "https://via.placeholder.com/100", Role = "User", IsActive = true, CreatedAt = now.AddDays(-7) }
            };
            await db.Users.AddRangeAsync(users);
            await db.SaveChangesAsync();

            // BusCompanies (10) - Assign OwnerId after Users created
            var busCompanies = new List<BusCompany>
            {
                new() { Name = "Hải Âu Express", Description = "Tuyến Bắc - Trung chất lượng cao", OwnerId = users[0].Id, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-40)},
                new() { Name = "FUTA Bus Lines", Description = "Chuyên tuyến miền Tây", OwnerId = users[1].Id, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-38)},
                new() { Name = "Hoàng Long", Description = "Giường nằm cao cấp", OwnerId = users[2].Id, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-35)},
                new() { Name = "Thanh Buoi", Description = "Tuyến Sài Gòn - Đà Lạt", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-32)},
                new() { Name = "Phương Trang", Description = "Xe đêm chất lượng", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-30)},
                new() { Name = "Sapa Express", Description = "Tuyến Hà Nội - Sapa", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-28)},
                new() { Name = "Queen Cafe", Description = "Limousine tuyến Hà Nội - Quảng Ninh", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-26)},
                new() { Name = "Thành Công", Description = "Tuyến miền Trung", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-24)},
                new() { Name = "Mai Linh", Description = "Xe tiện nghi, phủ toàn quốc", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-22)},
                new() { Name = "Cúc Tùng", Description = "Limousine cao cấp", OwnerId = null, ApprovalStatus = "approved", IsApproved = true, IsActive = true, CreatedAt = now.AddDays(-20)}
            };
            await db.BusCompanies.AddRangeAsync(busCompanies);
            await db.SaveChangesAsync();

            // Passenger profiles (12)
            var passengerProfiles = Enumerable.Range(1, 12).Select(i => new PassengerProfile
            {
                UserId = users[(i + 3) % users.Count].Id,
                FullName = i % 3 == 0 ? $"Nguyễn Hành Khách {i}" : i % 3 == 1 ? $"Trần Hành Khách {i}" : $"Lê Hành Khách {i}",
                CCCD = $"012345678{i:00}",
                Phone = $"0912{i:00000}",
                IsActive = true
            }).ToList();
            await db.PassengerProfiles.AddRangeAsync(passengerProfiles);
            await db.SaveChangesAsync();

            // Buses (10) - Số ghế phải khớp với layout trong seat_layout.dart: 22, 24, 34, 40
            var buses = new List<Bus>
            {
                new() { BusCompanyId = busCompanies[0].Id, LicensePlate = "29B-12345", Type = "Limousine", TotalSeats = 34, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[1].Id, LicensePlate = "51B-54321", Type = "Giường nằm", TotalSeats = 40, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[2].Id, LicensePlate = "43B-22222", Type = "Giường nằm", TotalSeats = 24, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[3].Id, LicensePlate = "29F-88888", Type = "Giường nằm", TotalSeats = 22, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[4].Id, LicensePlate = "60A-77777", Type = "Limousine", TotalSeats = 34, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[5].Id, LicensePlate = "14B-33333", Type = "Giường nằm", TotalSeats = 40, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[6].Id, LicensePlate = "79B-99999", Type = "Giường nằm", TotalSeats = 24, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[7].Id, LicensePlate = "17B-66666", Type = "Limousine", TotalSeats = 22, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[8].Id, LicensePlate = "18B-55555", Type = "Limousine", TotalSeats = 34, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true },
                new() { BusCompanyId = busCompanies[9].Id, LicensePlate = "20B-44444", Type = "Giường nằm", TotalSeats = 40, ImageUrl = "https://via.placeholder.com/300x200", IsActive = true }
            };
            await db.Buses.AddRangeAsync(buses);
            await db.SaveChangesAsync();

            // Trips (10)
            var tripTemplates = new List<(string start, string end, TimeSpan duration, decimal price)>
            {
                ("Hà Nội", "Đà Nẵng", TimeSpan.FromHours(15), 550_000),
                ("Hà Nội", "Thừa Thiên Huế", TimeSpan.FromHours(13), 500_000),
                ("TP Hồ Chí Minh", "Lâm Đồng", TimeSpan.FromHours(7), 320_000),
                ("TP Hồ Chí Minh", "Khánh Hòa", TimeSpan.FromHours(9), 380_000),
                ("Hà Nội", "Lào Cai", TimeSpan.FromHours(6.5), 280_000),
                ("Hà Nội", "Quảng Ninh", TimeSpan.FromHours(3.5), 180_000),
                ("TP Hồ Chí Minh", "Cần Thơ", TimeSpan.FromHours(4), 220_000),
                ("TP Hồ Chí Minh", "Bà Rịa - Vũng Tàu", TimeSpan.FromHours(2.5), 160_000),
                ("Đà Nẵng", "Quảng Ngãi", TimeSpan.FromHours(3), 150_000),
                ("Thừa Thiên Huế", "Quảng Bình", TimeSpan.FromHours(4), 190_000)
            };

            var trips = tripTemplates.Select((tpl, idx) => new Trip
            {
                BusId = buses[idx % buses.Count].Id,
                StartLocation = tpl.start,
                EndLocation = tpl.end,
                DepartureTime = now.AddDays(idx + 1).Date.AddHours(6 + idx),
                ArrivalTime = now.AddDays(idx + 1).Date.AddHours(6 + idx).Add(tpl.duration),
                Price = tpl.price,
                IsActive = true
            }).ToList();
            await db.Trips.AddRangeAsync(trips);
            await db.SaveChangesAsync();

            // Seats (tạo theo Bus, không theo Trip)
            var seats = new List<Seat>();
            foreach (var bus in buses)
            {
                var totalSeats = bus.TotalSeats;
                
                seats.AddRange(Enumerable.Range(1, totalSeats).Select(j => new Seat
                {
                    BusId = bus.Id,
                    SeatNumber = GenerateSeatNumber(j),
                    IsActive = true
                }));
            }
            await db.Seats.AddRangeAsync(seats);
            await db.SaveChangesAsync();

            // Tickets (15) with multiple seats support via TicketSeat
            var ticketSeed = Enumerable.Range(1, 15).Select(i =>
            {
                var status = i % 4 == 0 ? "Completed" : i % 5 == 0 ? "Cancelled" : "Booked";
                var trip = trips[i % trips.Count];
                var busSeats = seats.Where(s => s.BusId == trip.BusId).ToList();
                var seat = busSeats[i % busSeats.Count];

                var ticket = new Ticket
                {
                    UserId = users[4 + (i % 6)].Id,
                    PassengerProfileId = passengerProfiles[i % passengerProfiles.Count].Id,
                    TripId = trips[i % trips.Count].Id,
                    Status = status,
                    TicketCode = $"TCK{i:0000}",
                    CreatedAt = now.AddDays(-i)
                };

                return new { Ticket = ticket, Seat = seat, Status = status };
            }).ToList();

            var tickets = ticketSeed.Select(x => x.Ticket).ToList();
            await db.Tickets.AddRangeAsync(tickets);
            await db.SaveChangesAsync();

            // Link seats to tickets (booking status is derived from Ticket.Status)
            var ticketSeats = ticketSeed.Select((x, idx) => new TicketSeat
            {
                TicketId = tickets[idx].Id,
                SeatId = x.Seat.Id
            }).ToList();

            await db.TicketSeats.AddRangeAsync(ticketSeats);
            await db.SaveChangesAsync();

            // Payments (theo tickets Booked/Completed)
            var paidTickets = tickets.Where(t => t.Status != "Cancelled").ToList();
            var payments = paidTickets.Select((t, idx) =>
            {
                var tripPrice = trips.First(tr => tr.Id == t.TripId).Price;
                var discountPercent = idx % 5 == 0 ? 0.1m : 0m; // 10% discount for every 5th ticket
                var originalAmount = tripPrice;
                var discountAmount = originalAmount * discountPercent;
                var finalAmount = originalAmount - discountAmount;
                
                return new Payment
                {
                    TicketId = t.Id,
                    Method = idx % 3 == 0 ? "MoMo" : idx % 3 == 1 ? "VNPay" : "Cash",
                    OriginalAmount = originalAmount,
                    DiscountAmount = discountAmount,
                    Amount = finalAmount,
                    PromoCode = discountPercent > 0 ? $"PROMO{idx}" : null,
                    Status = "Paid",
                    PaidAt = now.AddDays(-idx)
                };
            }).ToList();
            await db.Payments.AddRangeAsync(payments);
            await db.SaveChangesAsync();

            // Reviews (10)
            var reviews = Enumerable.Range(1, 10).Select(i => new Review
            {
                UserId = users[4 + (i % 6)].Id,
                BusCompanyId = busCompanies[i % busCompanies.Count].Id,
                Rating = (i % 5) + 1,
                Comment = i % 3 == 0 ? "Xe sạch sẽ, tài xế thân thiện" : i % 3 == 1 ? "Khởi hành đúng giờ" : "Giá hợp lý, sẽ đi lại",
                IsActive = true,
                CreatedAt = now.AddDays(-i)
            }).ToList();
            await db.Reviews.AddRangeAsync(reviews);
            await db.SaveChangesAsync();

            // Promotions (10)
            var promotions = new List<Promotion>
            {
                new() { BusCompanyId = busCompanies[0].Id, Code = "HAIAU10", DiscountPercent = 10, StartDate = now.AddDays(-5), EndDate = now.AddDays(30), IsActive = true },
                new() { BusCompanyId = busCompanies[1].Id, Code = "FUTA15", DiscountPercent = 15, StartDate = now.AddDays(-3), EndDate = now.AddDays(25), IsActive = true },
                new() { BusCompanyId = busCompanies[2].Id, Code = "HL20", DiscountPercent = 20, StartDate = now.AddDays(-2), EndDate = now.AddDays(20), IsActive = true },
                new() { BusCompanyId = busCompanies[3].Id, Code = "TB05", DiscountPercent = 5, StartDate = now.AddDays(-1), EndDate = now.AddDays(15), IsActive = true },
                new() { BusCompanyId = busCompanies[4].Id, Code = "PT12", DiscountPercent = 12, StartDate = now.AddDays(-7), EndDate = now.AddDays(18), IsActive = true },
                new() { BusCompanyId = busCompanies[5].Id, Code = "SPX08", DiscountPercent = 8, StartDate = now.AddDays(-4), EndDate = now.AddDays(22), IsActive = true },
                new() { BusCompanyId = busCompanies[6].Id, Code = "QC10", DiscountPercent = 10, StartDate = now.AddDays(-6), EndDate = now.AddDays(28), IsActive = true },
                new() { BusCompanyId = busCompanies[7].Id, Code = "TC07", DiscountPercent = 7, StartDate = now.AddDays(-9), EndDate = now.AddDays(21), IsActive = true },
                new() { BusCompanyId = busCompanies[8].Id, Code = "ML09", DiscountPercent = 9, StartDate = now.AddDays(-8), EndDate = now.AddDays(24), IsActive = true },
                new() { BusCompanyId = busCompanies[9].Id, Code = "CT11", DiscountPercent = 11, StartDate = now.AddDays(-10), EndDate = now.AddDays(26), IsActive = true }
            };
            await db.Promotions.AddRangeAsync(promotions);
            await db.SaveChangesAsync();
        }

        private static string GenerateSeatNumber(int index)
        {
            // Generate seat numbers: A1-A6, B1-B6, C1-C6, etc.
            int row = ((index - 1) % 6) + 1;
            char column = (char)('A' + ((index - 1) / 6));
            return $"{column}{row}";
        }
    }
}
