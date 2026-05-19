import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'auth_wrapper.dart'; // Importa o wrapper

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      
      // Agora o app SEMPRE começa pelo Wrapper, e ele decide o resto!
      home: const AuthWrapper(), 
      
      routes: AppRoutes.routes,
    );
  }
}