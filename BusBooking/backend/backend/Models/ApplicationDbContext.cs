using Microsoft.EntityFrameworkCore;

namespace backend.Models
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<PassengerProfile> PassengerProfiles { get; set; }
        public DbSet<BusCompany> BusCompanies { get; set; }
        public DbSet<Bus> Buses { get; set; }
        public DbSet<Trip> Trips { get; set; }
        public DbSet<Seat> Seats { get; set; }
        public DbSet<Ticket> Tickets { get; set; }
        public DbSet<TicketSeat> TicketSeats { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Promotion> Promotions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configure BusCompany -> User (Company owned by Provider)
            modelBuilder.Entity<BusCompany>()
                .HasOne(c => c.Owner)
                .WithOne()
                .HasForeignKey<BusCompany>(c => c.OwnerId)
                .OnDelete(DeleteBehavior.SetNull);

            // Configure TicketSeat with CASCADE delete
            modelBuilder.Entity<TicketSeat>()
                .HasKey(ts => ts.Id);

            modelBuilder.Entity<TicketSeat>()
                .HasOne(ts => ts.Ticket)
                .WithMany(t => t.TicketSeats)
                .HasForeignKey(ts => ts.TicketId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TicketSeat>()
                .HasOne(ts => ts.Seat)
                .WithMany(s => s.TicketSeats)
                .HasForeignKey(ts => ts.SeatId)
                .OnDelete(DeleteBehavior.Restrict);

            // ÁP DỤNG SET NULL CHO TẤT CẢ FK KHÁC (trừ TicketSeat)
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                if (entityType.ClrType == typeof(TicketSeat))
                    continue;

                foreach (var fk in entityType.GetForeignKeys()
                    .Where(fk => fk.DeleteBehavior != DeleteBehavior.Cascade))
                {
                    fk.DeleteBehavior = DeleteBehavior.SetNull;
                }
            }
        }
    }
}
