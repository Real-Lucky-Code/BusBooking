namespace backend.DTOs
{
    // Trip DTO
    public class TripDTO
    {
        public int Id { get; set; }
        public int BusId { get; set; }
        public string StartLocation { get; set; } = string.Empty;
        public string EndLocation { get; set; } = string.Empty;
        public DateTime DepartureTime { get; set; }
        public DateTime ArrivalTime { get; set; }
        public decimal Price { get; set; }
        public bool IsActive { get; set; }
        public BusDTO? Bus { get; set; }
        public List<SeatDTO> Seats { get; set; } = new();
        public double AverageRating { get; set; }
        public int AvailableSeats { get; set; }
    }

    // Create/Update Trip Request
    public class CreateTripRequest
    {
        public int BusId { get; set; }
        public string StartLocation { get; set; } = string.Empty;
        public string EndLocation { get; set; } = string.Empty;
        public DateTime DepartureTime { get; set; }
        public DateTime ArrivalTime { get; set; }
        public decimal Price { get; set; }
    }

    // Search Trip Filter
    public class SearchTripRequest
    {
        public string StartLocation { get; set; } = string.Empty;
        public string EndLocation { get; set; } = string.Empty;
        public DateTime DepartureDate { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? BusType { get; set; }
        public int? BusCompanyId { get; set; }
        public int? DepartureHourStart { get; set; }
        public int? DepartureHourEnd { get; set; }
    }

    // Trip management filter (for provider dashboards)
    public class ManageTripFilterRequest
    {
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public string? StartLocation { get; set; }
        public string? EndLocation { get; set; }
        public int? BusId { get; set; }
        public string? BusType { get; set; }
        public bool? IsActive { get; set; }
    }
}
