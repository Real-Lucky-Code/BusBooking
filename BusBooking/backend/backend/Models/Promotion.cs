namespace backend.Models
{
    public class Promotion
    {
        public int Id { get; set; }

        public int? BusCompanyId { get; set; }
        public BusCompany BusCompany { get; set; }

        public string Code { get; set; }
        public decimal DiscountPercent { get; set; }

        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
