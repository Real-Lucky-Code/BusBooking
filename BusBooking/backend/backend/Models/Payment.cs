namespace backend.Models
{
    public class Payment
    {
        public int Id { get; set; }

        public int? TicketId { get; set; }
        public Ticket Ticket { get; set; }

        public string Method { get; set; }
        // MoMo | VNPay | Cash

        public decimal Amount { get; set; }
        // Amount actually paid after discount

        public decimal OriginalAmount { get; set; }
        public decimal DiscountAmount { get; set; }
        public string? PromoCode { get; set; }
        public string Status { get; set; }
        // Paid | Refunded

        public DateTime PaidAt { get; set; }
    }
}
