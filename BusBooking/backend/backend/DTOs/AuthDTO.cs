namespace backend.DTOs
{
    // Login Request
    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }

    // Register Request
    public class RegisterRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
        public string FullName { get; set; }
        public string Phone { get; set; }
        public string? AvatarUrl { get; set; }
        public string? Role { get; set; } // "User" | "Provider"
    }

    // Auth Response
    public class AuthResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public UserDTO User { get; set; }
        public string Token { get; set; }
        public CompanyRegistrationStatus? CompanyStatus { get; set; } // For Provider role
    }

    // Company registration status in auth response
    public class CompanyRegistrationStatus
    {
        public bool HasCompany { get; set; }
        public string Status { get; set; } // "none", "pending", "approved", "rejected"
        public BusCompanyDTO? Company { get; set; }
        public string Message { get; set; }
    }

    // User DTO
    public class UserDTO
    {
        public int Id { get; set; }
        public string Email { get; set; }
        public string FullName { get; set; }
        public string Phone { get; set; }
        public string AvatarUrl { get; set; }
        public string Role { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Update Profile Request
    public class UpdateProfileRequest
    {
        public string FullName { get; set; }
        public string Phone { get; set; }
        public string AvatarUrl { get; set; }
    }
}
