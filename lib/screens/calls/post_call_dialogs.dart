import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../services/api_service.dart';

/// Zakaz qo'ng'irog'i tugagach — IKKI TOMONLAMA "kelishuv" oqimi.
///
/// Mantiq:
///   1. Har ikki tomonga "Kelishdingizmi?" savoli chiqadi (Kelishdik/Kelishmadik).
///   2. Javob backendga (CallDeal) yoziladi. Backend ikki javobni bir `callId`
///      ostida yig'ib, keyingi harakatni (`next_action`) qaytaradi.
///   3. Nizo bo'lsa (bir "ha", bir "yo'q") — maxsus dialog ko'rsatiladi:
///        • provider "ha", mijoz "yo'q" → mijozdan QAYTA so'raladi (bypassga qarshi).
///        • provider "yo'q", mijoz "ha" → mijozga "qayta urinib ko'ring" xabari.
///   4. Ikkalasi "kelishdik" bo'lsa → bron bosqichi (provider vaqtni belgilaydi).
///
/// `next_action` qiymatlari (backend `_next_action`dan):
///   agreed | declined | await_other | need_response | client_recheck |
///   inform_client_declined
class PostCallDialogs {
  /// Zakaz qo'ng'irog'idan keyin chaqiriladi (faqat order + suhbat bo'lgan holatda).
  ///
  /// 30 SONIYA QOIDASI: savolga 30s ichida javob berilmasa dialog o'zi yopiladi
  /// va kelishuv AVTOMATIK RAD etiladi (backend ham o'z tomonidan 30s da rad
  /// qiladi — shuning uchun bir tomon "Kelishdik" bosib, ikkinchisi jim tursa,
  /// ikkalasiga ham "rad" bo'ladi).
  static Future<void> showDealFlow(
    BuildContext context, {
    required String callId,
    required int otherUserId,
    required String otherName,
    required String? categoryKey,
    required bool iAmProvider,
  }) async {
    final res = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DealQuestionDialog(
        otherName: otherName,
        iAmProvider: iAmProvider,
      ),
    );
    if (!context.mounted) return;

    if (res == 'agreed' || res == 'declined') {
      _submit(
        context,
        callId: callId,
        otherUserId: otherUserId,
        otherName: otherName,
        categoryKey: categoryKey,
        iAmProvider: iAmProvider,
        response: res!,
      );
    } else {
      // 30s ichida bosilmadi — avtomatik rad (backend ham shunday qiladi).
      _info(context, 'Vaqt tugadi — kelishuv avtomatik rad etildi.'.tr);
    }
  }

  /// Javobni backendga yuboradi va natijaga qarab keyingi qadamni ochadi.
  static Future<void> _submit(
    BuildContext context, {
    required String callId,
    required int otherUserId,
    required String otherName,
    required String? categoryKey,
    required bool iAmProvider,
    required String response,
    bool reconfirm = false,
  }) async {
    Map<String, dynamic> res;
    try {
      res = await ApiService().respondCallDeal(
        callId: callId,
        otherUserId: otherUserId,
        categoryKey: categoryKey,
        iAmProvider: iAmProvider,
        response: response,
        reconfirm: reconfirm,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kelishuvni saqlab bo\'lmadi: $e')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    _handleNextAction(
      context,
      nextAction: res['next_action']?.toString() ?? 'await_other',
      callId: callId,
      otherUserId: otherUserId,
      otherName: otherName,
      categoryKey: categoryKey,
      iAmProvider: iAmProvider,
    );
  }

  /// `next_action`ga qarab tegishli dialogni ko'rsatadi.
  static void _handleNextAction(
    BuildContext context, {
    required String nextAction,
    required String callId,
    required int otherUserId,
    required String otherName,
    required String? categoryKey,
    required bool iAmProvider,
  }) {
    switch (nextAction) {
      case 'agreed':
        _onAgreed(
          context,
          callId: callId,
          otherName: otherName,
          iAmProvider: iAmProvider,
        );
        break;

      case 'declined':
        _info(context, 'Kelishuv bo\'lmadi.'.tr);
        break;

      case 'inform_client_declined':
        // Provider "yo'q" dedi, mijoz "ha" degandi — mijozga tushuntiramiz.
        _info(
          context,
          '$otherName kelishuv bo\'lmadi dedi. Qayta qo\'ng\'iroq qiling yoki boshqa usta tanlang.',
        );
        break;

      case 'client_recheck':
        // Provider "kelishdik" dedi, biz (mijoz) "yo'q" degandik — qayta so'raymiz.
        _clientRecheck(
          context,
          callId: callId,
          otherUserId: otherUserId,
          otherName: otherName,
          categoryKey: categoryKey,
        );
        break;

      case 'await_other':
      case 'need_response':
      default:
        // Ikkinchi tomon hali javob bermagan — kutamiz va holatni pollingda kuzatamiz.
        _showWaiting(
          context,
          callId: callId,
          otherUserId: otherUserId,
          otherName: otherName,
          categoryKey: categoryKey,
          iAmProvider: iAmProvider,
        );
        break;
    }
  }

  /// Kelishuv tasdiqlandi. Provider vaqtni belgilaydi (bron), mijozga esa xabar.
  static void _onAgreed(
    BuildContext context, {
    required String callId,
    required String otherName,
    required bool iAmProvider,
  }) {
    if (iAmProvider) {
      // Provider kelishilgan sana/vaqtni kiritadi → server BRON (Order) yaratadi.
      _showDateForm(context, callId: callId, otherName: otherName);
    } else {
      _info(
        context,
        'Kelishuv tasdiqlandi! $otherName siz uchun vaqtni belgilaydi va bron qiladi.',
      );
    }
  }

  /// Nizo: mijozdan qayta so'rash — "Rostan fikringizdan qaytdingizmi?"
  static void _clientRecheck(
    BuildContext context, {
    required String callId,
    required int otherUserId,
    required String otherName,
    required String? categoryKey,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Tasdiqlang'.tr),
        content: Text(
          '$otherName "kelishdik" dedi. Siz rostan ham fikringizdan qaytdingizmi?',
        ),
        actions: [
          // "Yo'q, aslida kelishgandik" → aslida kelishuv bor → agreed (reconfirm).
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submit(
                context,
                callId: callId,
                otherUserId: otherUserId,
                otherName: otherName,
                categoryKey: categoryKey,
                iAmProvider: false,
                response: 'agreed',
                reconfirm: true,
              );
            },
            child: Text('Yo\'q, kelishgandik'.tr),
          ),
          // "Ha, qaytdim" → kelishuv yo'q → declined (reconfirm).
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submit(
                context,
                callId: callId,
                otherUserId: otherUserId,
                otherName: otherName,
                categoryKey: categoryKey,
                iAmProvider: false,
                response: 'declined',
                reconfirm: true,
              );
            },
            child: Text('Ha, qaytdim'.tr),
          ),
        ],
      ),
    );
  }

  /// Ikkinchi tomon javobini kutish + polling (holat o'zgarishini kuzatish).
  static void _showWaiting(
    BuildContext context, {
    required String callId,
    required int otherUserId,
    required String otherName,
    required String? categoryKey,
    required bool iAmProvider,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DealWaitingDialog(
        callId: callId,
        onResolved: (nextAction) {
          Navigator.pop(ctx); // kutish dialogini yopamiz
          _handleNextAction(
            context,
            nextAction: nextAction,
            callId: callId,
            otherUserId: otherUserId,
            otherName: otherName,
            categoryKey: categoryKey,
            iAmProvider: iAmProvider,
          );
        },
        onTimeout: () {
          Navigator.pop(ctx);
          _info(
            context,
            'Ikkinchi tomon javob bermadi — kelishuv avtomatik rad etildi.'.tr,
          );
        },
      ),
    );
  }

  // ---- Yordamchi dialoglar ----

  static void _info(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'.tr),
          ),
        ],
      ),
    );
  }

  /// Provider kelishilgan sana/vaqtni tanlaydi → server BRON (Order) yaratadi.
  static void _showDateForm(
    BuildContext context, {
    required String callId,
    required String otherName,
  }) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool saving = false;

    showDialog<void>(
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
                  onTap: saving
                      ? null
                      : () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 60)),
                          );
                          if (d != null) setState(() => selectedDate = d);
                        },
                ),
                ListTile(
                  title: Text('Vaqt'.tr),
                  subtitle: Text(selectedTime.format(ctx)),
                  trailing: const Icon(Icons.access_time),
                  onTap: saving
                      ? null
                      : () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (t != null) setState(() => selectedTime = t);
                        },
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        // Sana + vaqtni bitta DateTime'ga birlashtiramiz.
                        final when = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        try {
                          final res = await ApiService().createDealBooking(
                            callId: callId,
                            date: when,
                          );
                          final bothAgreed = res['both_agreed'] == true;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!context.mounted) return;
                          _info(
                            context,
                            bothAgreed
                                ? '$otherName uchun '
                                    '${DateFormat('yyyy-MM-dd HH:mm').format(when)} '
                                    'ga bron tasdiqlandi.'
                                : '$otherName uchun '
                                    '${DateFormat('yyyy-MM-dd HH:mm').format(when)} '
                                    'ga vaqt belgilandi. Mijoz tasdiqlashini kutmoqda.',
                          );
                        } catch (e) {
                          if (ctx.mounted) setState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bron qilib bo\'lmadi: $e')),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Saqlash'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ikkinchi tomon javobini kutuvchi dialog — davriy polling qiladi.
/// Holat `await_other`dan boshqasiga o'zgarsa `onResolved`ni chaqiradi.
class _DealWaitingDialog extends StatefulWidget {
  final String callId;
  final void Function(String nextAction) onResolved;
  final VoidCallback onTimeout;

  const _DealWaitingDialog({
    required this.callId,
    required this.onResolved,
    required this.onTimeout,
  });

  @override
  State<_DealWaitingDialog> createState() => _DealWaitingDialogState();
}

class _DealWaitingDialogState extends State<_DealWaitingDialog> {
  static const _interval = Duration(seconds: 3);
  // ~36 soniya: backend 30s da avtomatik rad qiladi — polling o'sha holatni
  // ('declined') ushlaydi; bu limit faqat zaxira (tarmoq uzilsa) uchun.
  static const _maxAttempts = 12;
  int _attempts = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    while (mounted && !_done && _attempts < _maxAttempts) {
      await Future.delayed(_interval);
      if (!mounted || _done) return;
      _attempts++;
      try {
        final res = await ApiService().getCallDeal(widget.callId);
        final next = res['next_action']?.toString() ?? 'await_other';
        // Faqat "kutish"dan chiqadigan holat kelganda hal qilamiz.
        if (next != 'await_other' && next != 'need_response') {
          _done = true;
          if (mounted) widget.onResolved(next);
          return;
        }
      } catch (_) {
        // Vaqtinchalik tarmoq xatosi — keyingi urinishda davom etamiz.
      }
    }
    if (mounted && !_done) {
      _done = true;
      widget.onTimeout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Ikkinchi tomon javobi kutilmoqda...'.tr),
          ),
        ],
      ),
    );
  }
}

/// "Kelishuvga erishdingizmi?" savoli — 30 soniyalik hisoblagich bilan.
/// Muddat tugasa dialog o'zi yopiladi (natija: null → avtomatik rad).
/// Tugmalar: 'agreed' (Kelishdik) / 'declined' (Kelishmadik) qiymatini qaytaradi.
class _DealQuestionDialog extends StatefulWidget {
  final String otherName;
  final bool iAmProvider;

  const _DealQuestionDialog({
    required this.otherName,
    required this.iAmProvider,
  });

  @override
  State<_DealQuestionDialog> createState() => _DealQuestionDialogState();
}

class _DealQuestionDialogState extends State<_DealQuestionDialog> {
  static const int _totalSeconds = 30;
  int _remaining = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        // Muddat tugadi — javobsiz yopamiz (avtomatik rad).
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Kelishuvga erishdingizmi?'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.iAmProvider
                ? '${widget.otherName} bilan xizmat bo\'yicha kelishuvga erishdingizmi?'
                : '${widget.otherName} bilan narx va vaqt bo\'yicha kelisha oldingizmi?',
          ),
          const SizedBox(height: 14),
          // Qolgan vaqt — foydalanuvchi shoshilishi kerakligini ko'rsin.
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                '$_remaining soniya qoldi',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('declined'),
          child: Text('Kelishmadik'.tr),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('agreed'),
          child: Text('Kelishdik'.tr),
        ),
      ],
    );
  }
}
