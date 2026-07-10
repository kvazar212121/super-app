import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import 'package:super_app/l10n/locale_controller.dart';

class PostCallDialogs {
  /// Asosiy kirish nuqtasi: Qo'ng'iroq tugagandan so'ng chaqiriladi.
  static void showPostCallDialog(
    BuildContext context,
    bool isProvider,
    int? remoteUserId,
    String remoteUserName,
    AppProvider appProvider, {
    required bool isBookingCall,
    required String categoryKey,
  }) {
    // Dismiss any active call screens
    Navigator.of(context).pop();

    if (isProvider) {
      _showUniversalProviderDialog(
        context,
        remoteUserId ?? 0,
        remoteUserName,
        appProvider,
      );
    } else {
      if (isBookingCall || true) {
        // Universal client dialog for ALL booking calls
        _showUniversalClientDialog(context, remoteUserId ?? 0, remoteUserName);
      }
    }
  }

  static void _showUniversalClientDialog(
    BuildContext context,
    int providerId,
    String providerName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Kelisha oldingizmi?'.tr),
        content: Text(
          '$providerName bilan narx va vaqt masalasida kelisha oldingizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yo\'q, kelishmadik'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showUniversalDateForm(
                context,
                providerId,
                providerName,
                isClient: true,
              );
            },
            child: Text('Ha, kelishdik'.tr),
          ),
        ],
      ),
    );
  }

  static void _showUniversalProviderDialog(
    BuildContext context,
    int clientId,
    String clientName,
    AppProvider appProvider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Buyurtma olindimi?'.tr),
        content: Text(
          '$clientName bilan xizmat ko\'rsatish bo\'yicha kelishuvga erishdingizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showUniversalDateForm(
                context,
                clientId,
                clientName,
                isClient: false,
              );
            },
            child: Text('Ha, kelishdik'.tr),
          ),
        ],
      ),
    );
  }

  static void _showUniversalDateForm(
    BuildContext context,
    int otherId,
    String otherName, {
    required bool isClient,
  }) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Qachonga kelishdingiz?'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Sana'.tr),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                ),
                ListTile(
                  title: Text('Vaqt'.tr),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (t != null) setState(() => selectedTime = t);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Bekor qilish'.tr),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  final msg = isClient
                      ? 'Ajoyib! ${DateFormat('yyyy-MM-dd').format(selectedDate)} soat ${selectedTime.format(context)} ga band qilindi.'
                      : 'Ajoyib! $otherName uchun ${DateFormat('yyyy-MM-dd').format(selectedDate)} soat ${selectedTime.format(context)} ga bron qildingiz.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                },
                child: Text('Saqlash'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}
