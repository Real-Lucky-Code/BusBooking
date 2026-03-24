namespace backend.Models
{
    public class Ticket
    {
        public int Id { get; set; }

        public int? UserId { get; set; }
        public User? User { get; set; }

        public int? PassengerProfileId { get; set; }
        public PassengerProfile? PassengerProfile { get; set; }

        public int? TripId { get; set; }
        public Trip? Trip { get; set; }

        public ICollection<TicketSeat> TicketSeats { get; set; } = new List<TicketSeat>();

        public string Status { get; set; } = string.Empty;
        // Booked | CancellationRequested | Cancelled | Completed

        public string TicketCode { get; set; } = string.Empty; // QR / ID
        public DateTime CreatedAt { get; set; }

        // Cancellation fields
        public DateTime? CancellationRequestedAt { get; set; }
        public string? CancellationStatus { get; set; } // Pending | Approved | Rejected
        public decimal? RefundAmount { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime? CancellationProcessedAt { get; set; }
        public string? CancellationNote { get; set; } // Admin/company note

        public Payment? Payment { get; set; }
    }
}
