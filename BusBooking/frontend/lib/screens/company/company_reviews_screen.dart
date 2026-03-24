import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/review_repository.dart';
import '../../models/mock_data.dart';

class CompanyReviewsScreen extends StatefulWidget {
  const CompanyReviewsScreen({super.key});

  @override
  State<CompanyReviewsScreen> createState() => _CompanyReviewsScreenState();
}

class _CompanyReviewsScreenState extends State<CompanyReviewsScreen> {
  String ratingFilter = 'Tất cả'; // Tất cả, 5 sao, 4 sao, 3 sao, 2 sao, 1 sao
  String searchQuery = '';
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    final companyId = AuthRepository.instance.currentCompanyId;
    if (companyId != null) {
      setState(() {
        _reviewsFuture = ReviewRepository.instance.getCompanyReviews(companyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AuthRepository.instance.currentCompanyId;

    if (companyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đánh giá công ty')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Không tìm thấy thông tin công ty',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Đánh giá công ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<Review>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const SizedBox.shrink();
                }

                final avgRating = reviews.isEmpty ? 0.0 : reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
                final reviewCounts = <int, int>{
                  5: reviews.where((r) => r.rating == 5).length,
                  4: reviews.where((r) => r.rating == 4).length,
                  3: reviews.where((r) => r.rating == 3).length,
                  2: reviews.where((r) => r.rating == 2).length,
                  1: reviews.where((r) => r.rating == 1).length,
                };

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.medium,
                    boxShadow: AppShadows.soft,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < avgRating.round() ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [5, 4, 3, 2, 1].map((star) {
                                final count = reviewCounts[star] ?? 0;
                                final percentage = reviews.isEmpty ? 0 : (count / reviews.length * 100);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text('$star sao', style: const TextStyle(fontSize: 12)),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation(Colors.amber.shade600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 30,
                                        child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tổng ${reviews.length} đánh giá',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo nội dung bình luận...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter chip
          if (ratingFilter != 'Tất cả')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(ratingFilter),
                    onDeleted: () => setState(() => ratingFilter = 'Tất cả'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          // Reviews list
          Expanded(
            child: FutureBuilder<List<Review>>(
              key: ValueKey('reviews-$ratingFilter-$searchQuery'),
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Không tải được đánh giá', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadReviews,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final reviews = snapshot.data ?? [];

                // Filter reviews
                var filteredReviews = reviews.where((review) {
                  final matchesSearch = searchQuery.isEmpty ||
                      review.comment.toLowerCase().contains(searchQuery.toLowerCase());
                  final matchesRating = ratingFilter == 'Tất cả' ||
                      (ratingFilter == '5 sao' && review.rating == 5) ||
                      (ratingFilter == '4 sao' && review.rating == 4) ||
                      (ratingFilter == '3 sao' && review.rating == 3) ||
                      (ratingFilter == '2 sao' && review.rating == 2) ||
                      (ratingFilter == '1 sao' && review.rating == 1);
                  return matchesSearch && matchesRating;
                }).toList();

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Chưa có đánh giá', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Đánh giá sẽ xuất hiện ở đây', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                if (filteredReviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy đánh giá', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filteredReviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = filteredReviews[index];
                    return _ReviewCard(review: review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lọc theo số sao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...['Tất cả', '5 sao', '4 sao', '3 sao', '2 sao', '1 sao'].map((filter) => RadioListTile<String>(
                title: Text(filter),
                value: filter,
                groupValue: ratingFilter,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  setState(() => ratingFilter = value!);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final userName = review.user?.fullName ?? 'Khách hàng ẩn danh';
    final createdDate = DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
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
                      userName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                createdDate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review.comment,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Công khai',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
