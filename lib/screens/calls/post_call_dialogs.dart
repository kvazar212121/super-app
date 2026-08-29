import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../theme/lux_tokens.dart';

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
      // MIJOZ: provider vaqtni belgilashini kutamiz va belgilangach bron
      // sanasini KATTA tasdiqlash modalida ko'rsatamiz (qachonga bron bo'ldi).
      _waitForBooking(context, callId: callId, otherName: otherName);
    }
  }

  /// Mijoz tomoni: provider bron vaqtini kiritishini kutish (polling).
  /// Vaqt belgilangach — katta ko'k tasdiqlash modali (sana/vaqt bilan).
  static void _waitForBooking(
    BuildContext context, {
    required String callId,
    required String otherName,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BookingWaitDialog(
        callId: callId,
        otherName: otherName,
        onBooked: (when) {
          Navigator.pop(ctx);
          _showSuccessModal(
            context,
            title: 'Bitim tasdiqlandi!',
            subtitle: '$otherName siz uchun bron qildi',
            when: when,
          );
        },
        onTimeout: () {
          Navigator.pop(ctx);
          _info(
            context,
            '$otherName hali vaqtni belgilamadi. Belgilanganda sizga bildirishnoma keladi.',
          );
        },
      ),
    );
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

  /// KATTA tasdiqlash modali — ko'k gradient doira ichida oq check belgisi,
  /// pastida kelishilgan SANA va VAQT (katta, ko'k kartada). Oddiy AlertDialog
  /// o'rniga bitim tasdiqlanганда shu ko'rsatiladi (ikkala tomonda ham).
  static void _showSuccessModal(
    BuildContext context, {
    required String title,
    String? subtitle,
    DateTime? when,
  }) {
    if (!context.mounted) return;
    const blue = Color(0xFFC9A227);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: LuxTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ko'k gradient doira + katta oq check
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE3C766), Color(0xFFB8921F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: LuxTokens.textMuted),
                ),
              ],
              if (when != null) ...[
                const SizedBox(height: 20),
                // Kelishilgan sana/vaqt — ko'k kartada, katta va aniq
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy-MM-dd').format(when),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: blue,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(when),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                          _showSuccessModal(
                            context,
                            title: bothAgreed
                                ? 'Bitim tasdiqlandi!'
                                : 'Vaqt belgilandi',
                            subtitle: bothAgreed
                                ? '$otherName uchun bron yaratildi'
                                : 'Mijoz tasdiqlashini kutmoqda',
                            when: when,
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

/// Mijoz tomonида: provider bron vaqtini kiritishini kutuvchi dialog.
/// Har 3 soniyada kelishuv holatini so'raydi — `booking.date` paydo bo'lishi
/// bilan [onBooked] chaqiriladi (katta tasdiqlash modali ko'rsatiladi).
/// ~2 daqiqada belgilanmasa (yoki foydalanuvchi yopsa) — [onTimeout].
class _BookingWaitDialog extends StatefulWidget {
  final String callId;
  final String otherName;
  final void Function(DateTime when) onBooked;
  final VoidCallback onTimeout;

  const _BookingWaitDialog({
    required this.callId,
    required this.otherName,
    required this.onBooked,
    required this.onTimeout,
  });

  @override
  State<_BookingWaitDialog> createState() => _BookingWaitDialogState();
}

class _BookingWaitDialogState extends State<_BookingWaitDialog> {
  static const _interval = Duration(seconds: 3);
  static const _maxAttempts = 40; // ~2 daqiqa
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
        final booking = res['booking'];
        if (booking is Map && booking['date'] != null) {
          final when = DateTime.tryParse(booking['date'].toString());
          if (when != null) {
            _done = true;
            if (mounted) widget.onBooked(when);
            return;
          }
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
            child: Text('${widget.otherName} vaqtni belgilamoqda...'),
          ),
        ],
      ),
      actions: [
        // Foydalanuvchini qamab qo'ymaymiz — yopsa, bildirishnoma orqali biladi.
        TextButton(
          onPressed: () {
            if (_done) return;
            _done = true;
            widget.onTimeout();
          },
          child: Text('Yopish'.tr),
        ),
      ],
    );
  }
}
