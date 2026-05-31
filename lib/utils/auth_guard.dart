import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_gate_screen.dart';

/// Buyurtma berishdan oldin kirish talab qilinadi.
Future<bool> ensureAuthenticated(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  if (auth.isAuthenticated) return true;

  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AuthGateScreen(),
    ),
  );

  if (ok == true && context.mounted) {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<AppProvider>().applyAuthUser(user);
      await context.read<AppProvider>().fetchInitialData();
    }
    return true;
  }
  return false;
}

/// Buyurtmani faqat autentifikatsiyadan keyin yaratadi.
Future<bool> placeOrder(BuildContext context, dynamic order) async {
  if (!await ensureAuthenticated(context)) return false;
  if (!context.mounted) return false;
  await context.read<AppProvider>().addOrder(order);
  return true;
}
