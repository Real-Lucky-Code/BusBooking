namespace backend.Models
{
    public class TicketSeat
    {
        public int Id { get; set; }

        public int TicketId { get; set; }
    public Ticket? Ticket { get; set; }

        public int SeatId { get; set; }
    public Seat? Seat { get; set; }
    }
}
