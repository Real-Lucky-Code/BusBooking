namespace backend.DTOs
{
    // Passenger Profile DTO
    public class PassengerProfileDTO
    {
        public int Id { get; set; }
        public string FullName { get; set; }
        public string CCCD { get; set; }
        public string Phone { get; set; }
    }

    // Create/Update Passenger Profile
    public class CreatePassengerProfileRequest
    {
        public string FullName { get; set; }
        public string CCCD { get; set; }
        public string Phone { get; set; }
    }
}
