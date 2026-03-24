import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key}) : super();

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
  late Future<List<ReviewInfo>> _reviewsFuture;
  bool _isRefreshing = false;

  String _searchQuery = '';
  String _ratingFilter = 'All';
  String _sortBy = 'newest';

  late ScrollController _scrollController;
  List<ReviewInfo> _allReviews = [];
  List<ReviewInfo> _displayedReviews = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _reviewsFuture = _loadReviews();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreReviews();
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;

      if (startIndex < _displayedReviews.length) {
        if (endIndex > _displayedReviews.length) {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
      _isLoadingMore = false;
    });
  }

  Future<List<ReviewInfo>> _loadReviews() async {
    final reviews = await AdminService.instance.getAllReviews();
    _allReviews = reviews;
    _filterAndSort();
    return reviews;
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 0;
      _hasMoreData = true;
    });

    _reviewsFuture = _loadReviews();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _filterAndSort() {
    List<ReviewInfo> filtered = List.from(_allReviews);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.busCompanyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.userName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Rating filter
    if (_ratingFilter != 'All') {
      int rating = int.parse(_ratingFilter);
      filtered = filtered.where((r) => r.rating >= rating).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'rating-high':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating-low':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _displayedReviews = filtered;
    _currentPage = 0;
    _hasMoreData = _displayedReviews.length > _itemsPerPage;
  }

  void _deleteReview(int id, String companyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: Text('Bạn có chắc chắn muốn xóa đánh giá về nhà xe "$companyName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AdminService.instance.deleteReview(id);
              await _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đánh giá đã được xóa')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReviewVisibility(int id, bool newStatus, String companyName) async {
    try {
      await AdminService.instance.toggleReviewVisibility(id, newStatus);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Hiện review thành công' : 'Ẩn review thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lọc theo sao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              ('All', 'Tất cả'),
              ('5', '5 sao'),
              ('4', '4 sao'),
              ('3', '3 sao'),
              ('2', '2 sao'),
              ('1', '1 sao'),
            ].map((e) => ListTile(
              leading: Radio<String>(
                value: e.$1,
                groupValue: _ratingFilter,
                onChanged: (value) {
                  setState(() => _ratingFilter = value ?? 'All');
                  _filterAndSort();
                  Navigator.pop(context);
                },
              ),
              title: Text(e.$2),
            )),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sắp xếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              ('newest', 'Mới nhất'),
              ('oldest', 'Cũ nhất'),
              ('rating-high', 'Sao cao → thấp'),
              ('rating-low', 'Sao thấp → cao'),
            ].map((e) => ListTile(
              leading: Radio<String>(
                value: e.$1,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value ?? 'newest');
                  _filterAndSort();
                  Navigator.pop(context);
                },
              ),
              title: Text(e.$2),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản lý đánh giá'),
        elevation: 0,
      ),
      body: FutureBuilder<List<ReviewInfo>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final reviews = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Tổng số đánh giá',
                          value: '${reviews.length}',
                          icon: Icons.rate_review,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Đánh giá 5 sao',
                          value: '${reviews.where((r) => r.rating == 5).length}',
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Điểm trung bình',
                    value: reviews.isEmpty
                        ? '0'
                        : '${(reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length).toStringAsFixed(1)}',
                    icon: Icons.assessment,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 20),

                  // Rating Breakdown
                  if (reviews.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phân bố đánh giá',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[5, 4, 3].map((rating) {
                      int count = reviews.where((r) => r.rating == rating).length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RatingBar(
                          rating: rating,
                          count: count,
                          total: reviews.length,
                          color: Colors.amber,
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Search and Filters
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhà xe hoặc người dùng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _filterAndSort();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: AppRadius.medium),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterAndSort();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          label: _ratingFilter == 'All' ? 'Tất cả sao' : '$_ratingFilter sao',
                          onTap: _showRatingFilter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterButton(
                          label: _sortBy == 'newest'
                              ? 'Mới nhất'
                              : _sortBy == 'oldest'
                                  ? 'Cũ nhất'
                                  : _sortBy == 'rating-high'
                                      ? 'Sao cao'
                                      : 'Sao thấp',
                          onTap: _showSortOptions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reviews List
                  if (_displayedReviews.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Không có đánh giá',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _displayedReviews.length > _itemsPerPage * (_currentPage + 1)
                          ? _itemsPerPage * (_currentPage + 1)
                          : _displayedReviews.length,
                      itemBuilder: (context, index) {
                        if (index >= _displayedReviews.length) return const SizedBox();
                        final review = _displayedReviews[index];
                        return _ReviewCard(
                          review: review,
                          onDelete: () => _deleteReview(review.id, review.busCompanyName),
                          onToggleVisibility: (newStatus) => _toggleReviewVisibility(review.id, newStatus, review.busCompanyName),
                        );
                      },
                    ),
                  if (_isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      ),
                    ),
                  if (!_hasMoreData && _displayedReviews.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Hết dữ liệu', style: TextStyle(color: Colors.grey.shade500)),
                    ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.rating,
    required this.count,
    required this.total,
    required this.color,
  });

  final int rating, count, total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double percentage = total > 0 ? (count / total * 100) : 0;
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$rating ★',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '$count (${percentage.toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final ReviewInfo review;
  final VoidCallback onDelete;
  final Function(bool) onToggleVisibility;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhà xe: ${review.busCompanyName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người review: ${review.userName}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email: ${review.userEmail}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.toInt() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              IconButton(
                icon: Icon(
                  review.isActive ? Icons.visibility : Icons.visibility_off,
                  color: review.isActive ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                onPressed: () => onToggleVisibility(!review.isActive),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
