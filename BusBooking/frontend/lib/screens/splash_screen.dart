import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.08), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: Theme.of(context).primaryGradient),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: Theme.of(context).accentGradient),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: glassSurface(borderRadius: AppRadius.large),
                  child: const SizedBox(
                    width: 180,
                    height: 180,
                    child: Icon(Icons.directions_bus, size: 120, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 18),
                Text("BusGo", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 6),
                Text("Đi an tâm, chọn ghế nhanh", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
