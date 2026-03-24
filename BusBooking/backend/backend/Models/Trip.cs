using System.Net.Sockets;

namespace backend.Models
{
    public class Trip
    {
        public int Id { get; set; }

        public int? BusId { get; set; }
        public Bus Bus { get; set; }

        public string StartLocation { get; set; }
        public string EndLocation { get; set; }

        public DateTime DepartureTime { get; set; }
        public DateTime ArrivalTime { get; set; }

        public decimal Price { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation
        public ICollection<Ticket> Tickets { get; set; }

    }
}
