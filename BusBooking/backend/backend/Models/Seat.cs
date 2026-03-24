namespace backend.Models
{
    public class Seat
    {
        public int Id { get; set; }

        public int? BusId { get; set; }
        public Bus? Bus { get; set; }

        public string SeatNumber { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
        
        public ICollection<TicketSeat>? TicketSeats { get; set; }
    }
}
