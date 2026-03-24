namespace backend.DTOs
{
    // Bus DTO
    public class BusDTO
    {
        public int Id { get; set; }
        public int BusCompanyId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int TotalSeats { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public BusCompanyDTO? BusCompany { get; set; }
    }

    // Create/Update Bus Request
    public class CreateBusRequest
    {
        public string LicensePlate { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int TotalSeats { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
    }
}
