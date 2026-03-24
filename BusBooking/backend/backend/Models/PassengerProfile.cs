namespace backend.Models
{
    public class PassengerProfile
    {
        public int Id { get; set; }

        public int? UserId { get; set; }
        public User User { get; set; }

        public string FullName { get; set; }
        public string CCCD { get; set; }
        public string Phone { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
