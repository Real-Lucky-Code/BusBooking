import 'package:flutter/material.dart';

/// Custom page route transitions for the entire app
class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;
  final String routeName;
  
  SmoothPageRoute({
    required this.page,
    required this.routeName,
  }) : super(
    settings: RouteSettings(name: routeName),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1, 0);
      const end = Offset.zero;
      const curve = Curves.easeOutQuart;
      
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 600),
  );
}

/// Fade + Scale transition
class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;
  final String routeName;
  
  FadeScaleRoute({
    required this.page,
    required this.routeName,
  }) : super(
    settings: RouteSettings(name: routeName),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      );
      
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

/// Slide up + Fade transition for bottom sheets
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  final String routeName;
  
  SlideUpRoute({
    required this.page,
    required this.routeName,
  }) : super(
    settings: RouteSettings(name: routeName),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0, 1);
      const end = Offset.zero;
      
      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOutQuart),
      );
      
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

/// Bounce in transition
class BounceRoute extends PageRouteBuilder {
  final Widget page;
  final String routeName;
  
  BounceRoute({
    required this.page,
    required this.routeName,
  }) : super(
    settings: RouteSettings(name: routeName),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.elasticOut),
      );
      
      return ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 700),
  );
}
