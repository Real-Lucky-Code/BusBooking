namespace backend.Models
{
    public class Review
    {
        public int Id { get; set; }

        public int? UserId { get; set; }
        public User User { get; set; }

        public int? BusCompanyId { get; set; }
        public BusCompany BusCompany { get; set; }

        public int Rating { get; set; } // 1–5
        public string Comment { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }
    }
}
