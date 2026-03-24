namespace backend.DTOs
{
    // Bus Company DTO
    public class BusCompanyDTO
    {
        public int Id { get; set; }
        public int? OwnerId { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsApproved { get; set; }
        public bool IsActive { get; set; }
        public string ApprovalStatus { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public double AverageRating { get; set; }
    }

    // Create/Update Bus Company Request
    public class CreateBusCompanyRequest
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public int? OwnerId { get; set; } // Optional fallback until JWT auth is in place
    }

    // Response for company registration status
    public class CompanyRegistrationResponse
    {
        public bool HasCompany { get; set; }
        public BusCompanyDTO? Company { get; set; }
        public string? Status { get; set; } // "none", "pending", "approved", "rejected"
        public string? Message { get; set; }
    }

    // Reject company request
    public class RejectCompanyRequest
    {
        public string Reason { get; set; } = string.Empty;
    }
}
