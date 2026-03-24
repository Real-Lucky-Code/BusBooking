namespace backend.Models
{
    public class Bus
    {
        public int Id { get; set; }

        public int? BusCompanyId { get; set; }
        public BusCompany BusCompany { get; set; }

        public string LicensePlate { get; set; }
        public string Type { get; set; } // Giường nằm, Limousine
        public int TotalSeats { get; set; }
        public string ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        public ICollection<Trip> Trips { get; set; }
        public ICollection<Seat> Seats { get; set; }
    }
}
