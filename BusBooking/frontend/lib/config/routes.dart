import 'package:flutter/material.dart';

import '../models/company_model.dart';
import '../models/mock_data.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/company/company_all_bookings_screen.dart';
import '../screens/company/company_booking_list_screen.dart';
import '../screens/company/company_buses_screen.dart';
import '../screens/company/company_cancellations_tab.dart';
import '../screens/company/company_main_screen.dart';
import '../screens/company/company_promotions_screen.dart';
import '../screens/company/company_registration_screen.dart';
import '../screens/company/company_registration_status_screen.dart';
import '../screens/company/company_reviews_screen.dart';
import '../screens/company/company_seat_layout_screen.dart';
import '../screens/company/company_trips_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/passenger_profile_form_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/review/add_review_screen.dart';
import '../screens/review/review_list_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/ticket/ticket_detail_screen.dart';
import '../screens/ticket/ticket_list_screen.dart';
import '../screens/trip/booking_success_screen.dart';
import '../screens/trip/home_screen.dart';
import '../screens/trip/trip_detail_screen.dart';
import '../screens/trip/trip_results_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const tripSearch = '/';
  static const home = '/home';
  static const tripResults = '/trip-results';
  static const tripDetail = '/trip-detail';
  static const bookingSuccess = '/booking-success';
  static const ticketList = '/tickets';
  static const ticketDetail = '/ticket-detail';
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const passengerProfile = '/passenger-profile';
  static const companyDashboard = '/company/dashboard';
  static const companyRegistration = '/company/registration';
  static const companyRegistrationStatus = '/company/registration-status';
  static const companyBuses = '/company/buses';
  static const companyTrips = '/company/trips';
  static const companyAllBookings = '/company/all-bookings';
  static const companyCancellations = '/company/cancellations';
  static const companyBookingList = '/company/booking-list';
  static const companySeatLayout = '/company/seat-layout';
  static const companyPromotions = '/company/promotions';
  static const companyReviews = '/company/reviews';
  static const reviews = '/reviews';
  static const addReview = '/add-review';
  static const adminDashboard = '/admin/dashboard';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.home:
      case AppRoutes.tripSearch:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.tripResults:
        return MaterialPageRoute(
          builder: (_) => TripResultsScreen(result: settings.arguments as SearchResult?),
        );
      case AppRoutes.tripDetail:
        return MaterialPageRoute(
          builder: (_) => TripDetailScreen(trip: settings.arguments as TripSummary?),
        );
      case AppRoutes.bookingSuccess:
        return MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(ticket: settings.arguments as TicketSummary),
        );
      case AppRoutes.ticketList:
        return MaterialPageRoute(builder: (_) => const TicketListScreen());
      case AppRoutes.ticketDetail:
        return MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticket: settings.arguments as TicketSummary?),
        );
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.profileEdit:
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: settings.arguments as UserProfile?),
        );
      case AppRoutes.passengerProfile:
        return MaterialPageRoute(
          builder: (_) => PassengerProfileFormScreen(profile: settings.arguments as PassengerProfile?),
        );
      case AppRoutes.companyDashboard:
        return MaterialPageRoute(builder: (_) => const CompanyMainScreen());
      case AppRoutes.companyRegistration:
        return MaterialPageRoute(
          builder: (_) => CompanyRegistrationScreen(
            initialStatus: settings.arguments as CompanyRegistrationStatus?,
          ),
        );
      case AppRoutes.companyRegistrationStatus:
        return MaterialPageRoute(builder: (_) => const CompanyRegistrationStatusScreen());
      case AppRoutes.companyBuses:
        return MaterialPageRoute(builder: (_) => const CompanyBusesScreen());
      case AppRoutes.companyTrips:
        return MaterialPageRoute(builder: (_) => const CompanyTripsScreen());
      case AppRoutes.companyAllBookings:
        return MaterialPageRoute(builder: (_) => const CompanyAllBookingsScreen());
      case AppRoutes.companyCancellations:
        return MaterialPageRoute(builder: (_) => const CompanyCancellationsTab());
      case AppRoutes.companyBookingList:
        final tripId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => CompanyBookingListScreen(tripId: tripId ?? 0),
        );
      case AppRoutes.companySeatLayout:
        final tripId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => CompanySeatLayoutScreen(tripId: tripId ?? 0),
        );
      case AppRoutes.companyPromotions:
        return MaterialPageRoute(builder: (_) => const CompanyPromotionsScreen());
      case AppRoutes.companyReviews:
        return MaterialPageRoute(builder: (_) => const CompanyReviewsScreen());
      case AppRoutes.reviews:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ReviewListScreen(
            busCompanyId: args?['busCompanyId'] ?? 0,
            busCompanyName: args?['busCompanyName'] ?? '',
          ),
        );
      case AppRoutes.addReview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddReviewScreen(
            busCompanyId: args['busCompanyId'],
            busCompanyName: args['busCompanyName'],
            tripId: args['tripId'],
            arrivalTime: args['arrivalTime'] is DateTime
                ? args['arrivalTime'] as DateTime
                : DateTime.tryParse(args['arrivalTime']?.toString() ?? ''),
          ),
        );
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminMainScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
