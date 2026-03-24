import 'api_client.dart';

class TicketService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Request cancellation for a ticket
  /// Returns success message if cancellation request submitted successfully
  Future<Map<String, dynamic>> requestCancellation({
    required int ticketId,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ticket/$ticketId/cancel-request',
        body: {
          'reason': reason,
        },
      );

      return {
        'success': true,
        'message': response['message'] ?? 'Yêu cầu hủy vé đã được gửi',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Check if ticket can be cancelled (24h before departure)
  bool canCancelTicket(DateTime departureTime) {
    final now = DateTime.now();
    final hoursDifference = departureTime.difference(now).inHours;
    return hoursDifference >= 24;
  }

  /// Get user-friendly cancellation status
  String getCancellationStatusText(String? status) {
    switch (status) {
      case 'Pending':
        return 'Đang chờ xử lý';
      case 'Approved':
        return 'Đã chấp nhận';
      case 'Rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }
}
