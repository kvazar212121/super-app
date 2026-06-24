import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';
import '../screens/calls/call_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../screens/auth/auth_gate_screen.dart';

class CallHelper {
  static Future<void> startCallWithPurposeCheck(
    BuildContext context,
    int targetId,
    String targetName, {
    String? categoryKey,
  }) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AuthGateScreen(),
        ),
      );
      if (ok == true && context.mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.user != null) {
          context.read<AppProvider>().applyAuthUser(auth.user!);
          await context.read<AppProvider>().fetchInitialData();
        }
      }
      
    if (!context.mounted || !context.read<AuthProvider>().isAuthenticated) return;
    }

    final currentUserId = int.tryParse(auth.user?['id']?.toString() ?? '');
    if (currentUserId != null && currentUserId == targetId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O'zingizga qo'ng'iroq qila olmaysiz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (targetId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kechirasiz, ushbu foydalanuvchining hisobi hali to'liq faollashtirilmagan."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show a bottom sheet or dialog to ask purpose
    bool? isBooking = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Qo'ng'iroq maqsadi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Yangi bandlov (bron) qilish'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: const Text('Boshqa masala / Savol'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    // If user dismissed without choosing, don't call
    if (isBooking == null) return;

    if (!context.mounted) return;

    bool started = await CallService().startCall(targetId, targetName, categoryKey: categoryKey);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Allaqachon qo'ng'iroqdamiz")),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(isIncoming: false, isBookingCall: isBooking),
      ),
    );
  }

  static Future<void> makeDirectCall(
    BuildContext context,
    int targetId,
    String targetName,
  ) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AuthGateScreen(),
        ),
      );
      if (ok == true && context.mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.user != null) {
          context.read<AppProvider>().applyAuthUser(auth.user!);
          await context.read<AppProvider>().fetchInitialData();
        }
      }
      
      if (!context.mounted || !context.read<AuthProvider>().isAuthenticated) return;
    }

    final currentUserId = int.tryParse(auth.user?['id']?.toString() ?? '');
    if (currentUserId != null && currentUserId == targetId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O'zingizga qo'ng'iroq qila olmaysiz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (targetId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kechirasiz, ushbu foydalanuvchining hisobi hali to'liq faollashtirilmagan."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool started = await CallService().startCall(targetId, targetName);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Allaqachon qo'ng'iroqdamiz")),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CallScreen(isIncoming: false),
      ),
    );
  }
}
