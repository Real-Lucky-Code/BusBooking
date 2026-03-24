namespace backend.DTOs
{
    // Promotion DTO
    public class PromotionDTO
    {
        public int Id { get; set; }
        public int BusCompanyId { get; set; }
        public string Code { get; set; }
        public decimal DiscountPercent { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; }
    }

    // Create/Update Promotion Request
    public class CreatePromotionRequest
    {
        public string Code { get; set; }
        public decimal DiscountPercent { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    // Apply Promotion Request
    public class ApplyPromotionRequest
    {
        public string Code { get; set; }
    }
}
