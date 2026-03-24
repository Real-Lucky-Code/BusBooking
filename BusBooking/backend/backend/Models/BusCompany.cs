using Microsoft.AspNetCore.Mvc.ViewEngines;

namespace backend.Models
{
    public class BusCompany
    {
        public int Id { get; set; }

        public int? OwnerId { get; set; }
        public User? Owner { get; set; }

        public string Name { get; set; }
        public string Description { get; set; }

        // Approval workflow: "none" | "pending" | "approved" | "rejected"
        public string ApprovalStatus { get; set; } = "none";
        
        public bool IsApproved { get; set; }
        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation
        public ICollection<Bus> Buses { get; set; }
        public ICollection<Review> Reviews { get; set; }
        public ICollection<Promotion> Promotions { get; set; }
    }
}
