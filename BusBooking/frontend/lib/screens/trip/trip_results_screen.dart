import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';

class TripResultsScreen extends StatelessWidget {
  final SearchResult? result;

  const TripResultsScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final sortedTrips = result?.trips ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả tìm kiếm"),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7F9),
      body: sortedTrips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy chuyến phù hợp', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Hãy thử đổi tiêu chí tìm kiếm', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : AnimationLimiter(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (result != null) ...[
                    Container(
                      decoration: glassSurface(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${result!.startLocation} → ${result!.endLocation}', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          4.vSpace,
                          Text('${result!.departureDate.day}/${result!.departureDate.month}/${result!.departureDate.year}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                    16.vSpace,
                  ],
                  Container(
                    decoration: glassSurface(),
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _FilterChip(icon: Icons.tune, label: "Bộ lọc"),
                        _FilterChip(icon: Icons.star, label: "Đánh giá 4.5+"),
                        _FilterChip(icon: Icons.event_seat, label: "Còn chỗ"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListView.builder(
                    itemCount: sortedTrips.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final trip = sortedTrips[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: ScaleAnimation(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          scale: 0.88,
                          child: SlideAnimation(
                            verticalOffset: 60,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuart,
                            child: FadeInAnimation(
                              duration: const Duration(milliseconds: 400),
                              child: _TripCard(
                                trip: trip,
                                index: index,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.tripDetail,
                                  arguments: trip,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final TripSummary trip;
  final VoidCallback onTap;
  final int index;
  const _TripCard({required this.trip, required this.onTap, required this.index});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: glassSurface(),
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
          child: AnimatedScale(
            scale: _isPressed ? 0.985 : 1,
            duration: const Duration(milliseconds: 140),
            child: Row(
              children: [
                Hero(
                  tag: 'trip_image_${widget.trip.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 1.06),
                      duration: const Duration(milliseconds: 4500),
                      curve: Curves.easeInOutSine,
                      builder: (context, v, _) => Transform.scale(
                        scale: v,
                        child: Container(
                          width: 120,
                          height: 116,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade400, Colors.blue.shade200],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.shade400.withOpacity(0.2),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus, size: 48, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;
                            final infoMaxWidth = (availableWidth - 64).clamp(80.0, availableWidth);
                            return Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: infoMaxWidth),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.trip.busCompanyName.isNotEmpty ? widget.trip.busCompanyName : 'Nhà xe',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.trip.busName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                _ratingChip(widget.trip.rating.toStringAsFixed(1)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${widget.trip.startLocation} → ${widget.trip.endLocation}",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _infoTag(Icons.event_seat, 'Còn ${widget.trip.availableSeats} chỗ'),
                            _infoTag(Icons.schedule, '${widget.trip.departureTime.hour}:${widget.trip.departureTime.minute.toString().padLeft(2, '0')}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currency(widget.trip.price.toInt()),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 18),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingChip(String rating) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 2),
      duration: const Duration(seconds: 8),
      curve: Curves.linear,
      builder: (context, t, _) {
        // Create a smooth continuous color cycle
        final normalizedT = t % 1.0;
        final colors = [
          const Color(0xFFFFD166), // Yellow
          const Color(0xFF64DFDF), // Cyan  
          const Color(0xFF9D4EDD), // Purple
          const Color(0xFFFFD166), // Back to yellow
        ];
        
        // Calculate position in color cycle
        final segmentLength = 1.0 / (colors.length - 1);
        final segment = (normalizedT / segmentLength).floor();
        final segmentT = (normalizedT % segmentLength) / segmentLength;
        
        final c1 = Color.lerp(colors[segment.clamp(0, colors.length - 1)], 
                               colors[(segment + 1).clamp(0, colors.length - 1)], segmentT);
        final c2 = Color.lerp(colors[(segment + 1).clamp(0, colors.length - 1)], 
                               colors[(segment + 2).clamp(0, colors.length - 1)], segmentT);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c1 ?? colors[0], c2 ?? colors[1]],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.pill,
            boxShadow: [
              BoxShadow(
                color: (c1 ?? colors[0]).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, _) => Transform.scale(
                  scale: 0.7 + (value * 0.3),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: Colors.blueGrey.shade700), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FilterChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.pill,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: primaryColor), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
