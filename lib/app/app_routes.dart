import 'package:flutter/material.dart';
import 'package:versin/modules/login/views/login_page.dart';
import 'package:versin/modules/dashboard/views/dashboard_page.dart';

class AppRoutes {
  // Deixamos apenas as strings que serão chamadas via Navigator.pushNamed
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    // 🚨 Sem a rota '/' aqui dentro! O 'home: const AuthWrapper()' no my_app.dart já cuida disso.
    login: (context) => const LoginPage(), 
    dashboard: (context) => const DashboardPage(),
  };
}