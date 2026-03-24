namespace backend.DTOs
{
    // Seat DTO
    public class SeatDTO
    {
        public int Id { get; set; }
        public int TripId { get; set; }
        public string SeatNumber { get; set; }
        public bool IsBooked { get; set; }
        public bool IsActive { get; set; }
    }

    // Bulk Create Seats Request
    public class BulkCreateSeatsRequest
    {
        public int TripId { get; set; }
        public List<string> SeatNumbers { get; set; }
    }
}
