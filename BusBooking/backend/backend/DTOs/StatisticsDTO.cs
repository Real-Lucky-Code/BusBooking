namespace backend.DTOs
{
    // Daily Statistics
    public class DailyStatistics
    {
        public DateTime Date { get; set; }
        public int TicketsSold { get; set; }
        public decimal Revenue { get; set; }
    }

    // Monthly Statistics
    public class MonthlyStatistics
    {
        public int Month { get; set; }
        public int Year { get; set; }
        public int TicketsSold { get; set; }
        public decimal Revenue { get; set; }
    }

    // Seat Occupancy Statistics
    public class SeatOccupancyStatistics
    {
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public double OccupancyRate { get; set; }
    }

    // System Statistics
    public class SystemStatistics
    {
        public int TotalUsers { get; set; }
        public int TotalBusCompanies { get; set; }
        public int ApprovedBusCompanies { get; set; }
        public int TotalTrips { get; set; }
        public int TotalTickets { get; set; }
        public decimal TotalRevenue { get; set; }
        public List<DailyStatistics> DailyStats { get; set; }
        public List<MonthlyStatistics> MonthlyStats { get; set; }
    }

    // Company Statistics (for Bus Company Dashboard)
    public class CompanyStatistics
    {
        public int TotalBuses { get; set; }
        public int TotalTrips { get; set; }
        public int TotalBookings { get; set; }
        public int TodayBookings { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal TodayRevenue { get; set; }
        public double AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public int TotalPromotions { get; set; }
    }
}
