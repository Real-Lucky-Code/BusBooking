import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/company_model.dart';
import '../../services/bus_company_service.dart';

class CompanyRegistrationStatusScreen extends StatefulWidget {
  const CompanyRegistrationStatusScreen({super.key});

  @override
  State<CompanyRegistrationStatusScreen> createState() =>
      _CompanyRegistrationStatusScreenState();
}

class _CompanyRegistrationStatusScreenState
    extends State<CompanyRegistrationStatusScreen> {
  bool _isLoading = true;
  CompanyRegistrationStatus? _status;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanyStatus();
  }

  Future<void> _loadCompanyStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await BusCompanyService.instance.getMyCompany();
      setState(() => _status = status);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Trạng thái đăng ký công ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanyStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _status == null || !_status!.hasCompany
                  ? _buildNoCompanyView()
                  : _buildStatusView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông tin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCompanyStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompanyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.domain_add_outlined,
                size: 100, color: Colors.blue[300]),
            const SizedBox(height: 24),
            Text(
              'Chưa đăng ký công ty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có yêu cầu đăng ký công ty nào.\nHãy đăng ký ngay để bắt đầu quản lý nhà xe của bạn.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.companyRegistration,
                  arguments: _status,
                ).then((_) => _loadCompanyStatus());
              },
              icon: const Icon(Icons.domain_add),
              label: const Text('Đăng ký công ty'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    final company = _status!.company;
    final isPending = _status!.isPending;
    final isApproved = _status!.isApproved;
    final isRejected = _status!.isRejected;

    return RefreshIndicator(
      onRefresh: _loadCompanyStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            _buildStatusCard(isPending, isApproved, isRejected),
            const SizedBox(height: 20),

            // Company info
            if (company != null) ...[
              _buildInfoSection('Thông tin công ty', [
                _InfoRow(
                  icon: Icons.business,
                  label: 'Tên công ty',
                  value: company.name,
                ),
                _InfoRow(
                  icon: Icons.description_outlined,
                  label: 'Mô tả',
                  value: company.description.isNotEmpty
                      ? company.description
                      : 'Chưa có mô tả',
                ),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Ngày tạo',
                  value: _formatDate(company.createdAt),
                ),
                if (company.updatedAt != null)
                  _InfoRow(
                    icon: Icons.update,
                    label: 'Cập nhật lần cuối',
                    value: _formatDate(company.updatedAt!),
                  ),
                if (company.averageRating != null && company.averageRating! > 0)
                  _InfoRow(
                    icon: Icons.star,
                    label: 'Đánh giá trung bình',
                    value: '${company.averageRating!.toStringAsFixed(1)} ⭐',
                  ),
              ]),
              const SizedBox(height: 20),
            ],

            // Timeline
            _buildTimelineSection(),
            const SizedBox(height: 24),

            // Actions
            if (isRejected || isPending) ...[
              _buildActionButtons(isRejected),
              const SizedBox(height: 20),
            ],

            // Help section
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isPending, bool isApproved, bool isRejected) {
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isApproved) {
      bgColor = Colors.green;
      iconColor = Colors.white;
      icon = Icons.check_circle;
      title = 'Đã được phê duyệt';
      subtitle =
          'Công ty của bạn đã được phê duyệt. Bạn có thể bắt đầu quản lý nhà xe.';
    } else if (isPending) {
      bgColor = Colors.orange;
      iconColor = Colors.white;
      icon = Icons.hourglass_top;
      title = 'Đang chờ phê duyệt';
      subtitle =
          'Yêu cầu đăng ký của bạn đang được xem xét. Vui lòng chờ admin phê duyệt.';
    } else {
      bgColor = Colors.red;
      iconColor = Colors.white;
      icon = Icons.cancel;
      title = 'Bị từ chối';
      subtitle =
          'Yêu cầu đăng ký bị từ chối. Vui lòng kiểm tra thông tin và gửi lại.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_status?.message != null && _status!.message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: AppRadius.medium,
              ),
              child: Text(
                _status!.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến trình',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _TimelineItem(
            icon: Icons.send,
            title: 'Gửi yêu cầu',
            subtitle: 'Đã gửi yêu cầu đăng ký công ty',
            isCompleted: true,
            isLast: false,
          ),
          _TimelineItem(
            icon: Icons.pending_actions,
            title: 'Đang xem xét',
            subtitle: _status!.isPending
                ? 'Admin đang xem xét yêu cầu của bạn'
                : 'Đã xem xét',
            isCompleted: !_status!.isPending,
            isLast: false,
          ),
          _TimelineItem(
            icon: _status!.isApproved
                ? Icons.check_circle
                : _status!.isRejected
                    ? Icons.cancel
                    : Icons.pending,
            title: _status!.isApproved
                ? 'Đã phê duyệt'
                : _status!.isRejected
                    ? 'Bị từ chối'
                    : 'Chờ kết quả',
            subtitle: _status!.isApproved
                ? 'Công ty đã được phê duyệt'
                : _status!.isRejected
                    ? 'Yêu cầu bị từ chối'
                    : 'Chờ admin phê duyệt',
            isCompleted: _status!.isApproved,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isRejected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRejected)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.companyRegistration,
                arguments: _status,
              ).then((_) => _loadCompanyStatus());
            },
            icon: const Icon(Icons.edit),
            label: const Text('Cập nhật thông tin và gửi lại'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        if (!isRejected)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Liên hệ admin qua email: admin@busapp.com'),
                ),
              );
            },
            icon: const Icon(Icons.contact_support),
            label: const Text('Liên hệ hỗ trợ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: AppRadius.large,
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Câu hỏi thường gặp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HelpItem(
            question: 'Mất bao lâu để được phê duyệt?',
            answer: 'Thường mất từ 1-3 ngày làm việc để admin xem xét và phê duyệt.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            question: 'Tại sao yêu cầu của tôi bị từ chối?',
            answer:
                'Có thể do thông tin không đầy đủ hoặc không chính xác. Vui lòng kiểm tra và cập nhật lại.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            question: 'Làm sao để liên hệ admin?',
            answer:
                'Bạn có thể liên hệ qua email: admin@busapp.com hoặc hotline: 1900-xxxx.',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có thông tin';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: AppRadius.small,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Colors.green : Colors.grey[400]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCompleted ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q: $question',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A: $answer',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
