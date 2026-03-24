import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class BusTicketApp extends StatelessWidget {
  const BusTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Ticket Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
