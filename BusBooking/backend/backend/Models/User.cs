namespace backend.Models
{
    public class User
    {
        public int Id { get; set; }

        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;

        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string AvatarUrl { get; set; } = string.Empty;

        public string Role { get; set; } = "User";
        // User | Provider | Admin

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }

        // Navigation
        public ICollection<PassengerProfile> PassengerProfiles { get; set; }
        public ICollection<Ticket> Tickets { get; set; }
    }
}
