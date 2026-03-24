import '../models/mock_data.dart';
import '../services/api_client.dart';

class TicketRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();

  Future<List<TicketSummary>> getUserTickets(int userId) async {
    final res = await ApiClient.instance.get('/ticket/user/$userId');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => TicketSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TicketSummary> getTicketDetail(int id) async {
    final res = await ApiClient.instance.get('/ticket/$id');
    final data = res['data'] ?? res;
    return TicketSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<TicketSummary> bookTicket({
    required int tripId,
    required List<int> seatIds,
    required int passengerProfileId,
    String paymentMethod = 'Cash',
    String? promoCode,
    num discountAmount = 0,
  }) async {
    final res = await ApiClient.instance.post('/ticket/book', body: {
      'tripId': tripId,
      'seatIds': seatIds,
      'passengerProfileId': passengerProfileId,
      'paymentMethod': paymentMethod,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      'discountAmount': discountAmount,
    });
    final data = res['data'] ?? res;
    return TicketSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<TicketSummary> bookTicketsBulk({
    required int tripId,
    required List<int> seatIds,
    required int passengerProfileId,
    String paymentMethod = 'Cash',
    String? promoCode,
    num discountAmount = 0,
  }) async {
    // Alias to align old call sites; backend returns a single ticket for multiple seats.
    return bookTicket(
      tripId: tripId,
      seatIds: seatIds,
      passengerProfileId: passengerProfileId,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      discountAmount: discountAmount,
    );
  }

  Future<void> cancelTicket(int id) async {
    await ApiClient.instance.post('/ticket/$id/cancel');
  }
}
