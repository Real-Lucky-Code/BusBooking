import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Professional animation utilities for consistent, polished UI transitions
class AnimationUtils {
  // Timing curves for different animation purposes
  static const Curve snappyEntry = Curves.easeOutBack;
  static const Curve smoothExit = Curves.easeInCubic;
  static const Curve liquidSwipe = Curves.easeInOutCubic;
  static const Curve elasticBounce = Curves.elasticOut;
  static const Curve softEntry = Curves.easeOutQuart;

  // Standard durations
  static const Duration quickFeedback = Duration(milliseconds: 140);
  static const Duration normalEntry = Duration(milliseconds: 400);
  static const Duration staggerEntry = Duration(milliseconds: 500);
  static const Duration parallaxEffect = Duration(milliseconds: 3200);
  static const Duration loopAnimation = Duration(seconds: 6);
  static const Duration pageTransition = Duration(milliseconds: 600);

  /// Creates a staggered list animation builder
  static Widget staggeredListBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    bool shrinkWrap = true,
    double verticalOffset = 50,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        return ScaleAnimation(
          duration: normalEntry,
          curve: snappyEntry,
          scale: 0.92,
          child: SlideAnimation(
            verticalOffset: verticalOffset,
            duration: normalEntry,
            curve: softEntry,
            child: FadeInAnimation(
              duration: Duration(milliseconds: 300),
              child: itemBuilder(context, index),
            ),
          ),
        );
      },
    );
  }

  /// Creates a smooth page transition with fade + scale
  static Route<T> createPageRoute<T>({
    required WidgetBuilder builder,
    required String routeName,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(tween);

        var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  /// Creates a smooth bottom sheet animation
  static Future<T?> showAnimatedBottomSheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    Color barrierColor = Colors.black54,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      barrierColor: barrierColor,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context).userGestureInProgressNotifier as TickerProvider,
        duration: pageTransition,
      ),
    );
  }
}

/// Professional card reveal animation
class ProfessionalCardReveal extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const ProfessionalCardReveal({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Smooth form field focus animation
class AnimatedFormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AnimatedFormField({
    super.key,
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<AnimatedFormField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.blue.shade50,
    ).animate(_controller);

    _elevationAnimation = Tween<double>(begin: 0, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus(bool focused) {
    if (focused) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          elevation: _elevationAnimation.value,
          borderRadius: BorderRadius.circular(12),
          color: _colorAnimation.value,
          child: Focus(
            onFocusChange: _handleFocus,
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              decoration: InputDecoration(
                label: Text(widget.label),
                prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _colorAnimation.value ?? Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated button with press feedback
class ProfessionalButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const ProfessionalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
  });

  @override
  State<ProfessionalButton> createState() => _ProfessionalButtonState();
}

class _ProfessionalButtonState extends State<ProfessionalButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.94).animate(_controller),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade400.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button with pulse animation
class PulseFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const PulseFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color = Colors.blue,
  });

  @override
  State<PulseFloatingActionButton> createState() => _PulseFloatingActionButtonState();
}

class _PulseFloatingActionButtonState extends State<PulseFloatingActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.5).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Opacity(
            opacity: (1 - _controller.value),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.3),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: widget.color,
          elevation: 6,
          child: Icon(widget.icon, color: Colors.white),
        ),
      ],
    );
  }
}
