namespace backend.DTOs
{
    // Ticket DTO
    public class TicketDTO
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int PassengerProfileId { get; set; }
        public int TripId { get; set; }
        public List<int> SeatIds { get; set; } = new();
        public string Status { get; set; } = string.Empty; // Booked | CancellationRequested | Cancelled | Completed
        public string TicketCode { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public TripDTO? Trip { get; set; }
        public PassengerProfileDTO? PassengerProfile { get; set; }
        public List<SeatDTO> Seats { get; set; } = new();
        public PaymentDTO? Payment { get; set; }

        // Cancellation info
        public DateTime? CancellationRequestedAt { get; set; }
        public string? CancellationStatus { get; set; } // Pending | Approved | Rejected
        public decimal? RefundAmount { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime? CancellationProcessedAt { get; set; }
        public string? CancellationNote { get; set; }
    }

    // Book Ticket Request (single ticket with multiple seats)
    public class BookTicketRequest
    {
        public int TripId { get; set; }
        public int PassengerProfileId { get; set; }
        public List<int> SeatIds { get; set; } = new();
        public string PaymentMethod { get; set; } = string.Empty; // MoMo | VNPay | Cash
        public string? PromoCode { get; set; }
        public decimal DiscountAmount { get; set; } = 0;
    }

    // Cancel Ticket Request (from user)
    public class CancelTicketRequest
    {
        public string? Reason { get; set; }
    }

    // Process Cancellation Request (from admin/company)
    public class ProcessCancellationRequest
    {
        public bool Approve { get; set; } // true = approve, false = reject
        public decimal? RefundAmount { get; set; } // Required if Approve = true
        public string? Note { get; set; } // Admin note
    }

    // Booking DTO (for company booking list)
    public class BookingDTO
    {
        public int Id { get; set; }
        public string TicketCode { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        
        // Passenger info
        public string PassengerName { get; set; } = string.Empty;
        public string PassengerPhone { get; set; } = string.Empty;
        public string PassengerCCCD { get; set; } = string.Empty;
        
        // Trip info
        public int TripId { get; set; }
        public string StartLocation { get; set; } = string.Empty;
        public string EndLocation { get; set; } = string.Empty;
        public DateTime DepartureTime { get; set; }
        public string BusLicensePlate { get; set; } = string.Empty;
        
        // Booking details
        public List<string> SeatNumbers { get; set; } = new();
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        
        // Cancellation info
        public DateTime? CancellationRequestedAt { get; set; }
        public string? CancellationStatus { get; set; }
        public string? CancellationReason { get; set; }
        public decimal? RefundAmount { get; set; }
    }
}
