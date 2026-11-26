import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/restaurant_provider.dart';
import 'screens/admin_shell_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RestauranteMesaApp());
}

class RestauranteMesaApp extends StatelessWidget {
  final RestaurantProvider? provider;

  const RestauranteMesaApp({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RestaurantProvider>(
      create: (_) {
        final instance = provider ?? RestaurantProvider();
        instance.initialize();
        return instance;
      },
      child: MaterialApp(
        title: 'Restaurante Mesa — Gestão & Cardápio Digital',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();

    if (!provider.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return provider.isAuthenticated
        ? const AdminShellScreen()
        : const LoginScreen();
  }
}
