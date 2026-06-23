import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../screens/calls/call_screen.dart';

class CallHelper {
  static Future<void> startCallWithPurposeCheck(
    BuildContext context,
    int targetId,
    String targetName, {
    String? categoryKey,
  }) async {
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

    CallService().startCall(targetId, targetName, categoryKey: categoryKey);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(isIncoming: false, isBookingCall: isBooking),
      ),
    );
  }
}
