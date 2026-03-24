namespace backend.DTOs
{
    // Review DTO
    public class ReviewDTO
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BusCompanyId { get; set; }
        public int Rating { get; set; } // 1-5
        public string Comment { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public UserDTO User { get; set; }
        public dynamic BusCompany { get; set; }
    }

    // Create/Update Review Request
    public class CreateReviewRequest
    {
        public int BusCompanyId { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; }
    }

    // Toggle Review Visibility Request
    public class ToggleReviewVisibilityRequest
    {
        public bool IsActive { get; set; }
    }
}