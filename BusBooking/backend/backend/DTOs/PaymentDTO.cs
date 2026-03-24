namespace backend.DTOs
{
    // Payment DTO
    public class PaymentDTO
    {
        public int Id { get; set; }
        public int TicketId { get; set; }
        public string Method { get; set; } // MoMo | VNPay | Cash
        public decimal Amount { get; set; }
        public decimal OriginalAmount { get; set; }
        public decimal DiscountAmount { get; set; }
        public string? PromoCode { get; set; }
        public string Status { get; set; } // Paid | Refunded
        public DateTime PaidAt { get; set; }
    }

    // Create Payment Request
    public class CreatePaymentRequest
    {
        public int TicketId { get; set; }
        public string Method { get; set; }
        public decimal Amount { get; set; }
    }
}
