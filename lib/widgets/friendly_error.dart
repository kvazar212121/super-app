import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

/// Xato turlari — texnik xato kodini foydalanuvchi tushunadigan ma'noga
/// aylantiramiz. Kod hech qanday joyda 500/404 raqamini ko'rsatmaydi.
enum FriendlyErrorKind {
  noInternet,       // Internet yo'q (SocketException, connectivity)
  timeout,          // Vaqt tugadi (Dio timeout)
  serverError,      // Backend 5xx
  notFound,         // 404 (ba'zi joyda "hozircha ma'lumot yo'q" ma'nosida)
  unauthorized,     // 401 — qayta kirish kerak
  rateLimited,      // 429 — juda ko'p so'rov
  badRequest,       // 400 — foydalanuvchi kiritmasi noto'g'ri
  unknown,          // Boshqa
}

/// Foydalanuvchiga tushunarli xato ma'lumoti.
class FriendlyError {
  final FriendlyErrorKind kind;
  final String title;    // Qisqa sarlavha: "Internet yo'q"
  final String message;  // Nima qilish kerakligi: "Wi-Fi yoki mobil aloqani tekshiring"
  final IconData icon;
  final Color color;
  final bool showRetry;

  const FriendlyError({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.showRetry = true,
  });

  /// Har qanday exception'ni tushunarli xatoga aylantiradi.
  ///
  /// Kod ichida `500`, `429` kabi raqamlar yo'q — foydalanuvchi
  /// hech qachon "Xato 500" ko'rmaydi.
  factory FriendlyError.fromException(Object err) {
    // 1) Internet uzilgan bo'lsa (haqiqiy tarmoq xatosi)
    if (err is SocketException || err is HandshakeException) {
      return const FriendlyError(
        kind: FriendlyErrorKind.noInternet,
        title: 'Internet yo\'q',
        message: 'Wi-Fi yoki mobil aloqani tekshirib qayta urinib ko\'ring.',
        icon: LucideIcons.wifiOff,
        color: Color(0xFFEF4444),
      );
    }
    // 2) Timeout — sekin internet
    if (err is TimeoutException) {
      return const FriendlyError(
        kind: FriendlyErrorKind.timeout,
        title: 'Sekin internet',
        message: 'Server juda uzoq javob bermayapti. Qayta urinib ko\'ring.',
        icon: LucideIcons.clock,
        color: Color(0xFFF59E0B),
      );
    }
    // 3) Dio xato — status code'ga qarab
    if (err is DioException) {
      // Ulanish xatolari (internet uzilgan, DNS ishlamaydi va h.k.)
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout) {
        return const FriendlyError(
          kind: FriendlyErrorKind.timeout,
          title: 'Sekin internet',
          message:
              'Server javob berishga ulgurmadi. Aloqa yaxshilangach qayta urining.',
          icon: LucideIcons.clock,
          color: Color(0xFFF59E0B),
        );
      }
      if (err.type == DioExceptionType.connectionError ||
          err.error is SocketException) {
        return const FriendlyError(
          kind: FriendlyErrorKind.noInternet,
          title: 'Internet yo\'q',
          message:
              'Ilova serverga ulana olmadi. Aloqani tekshirib qayta urining.',
          icon: LucideIcons.wifiOff,
          color: Color(0xFFEF4444),
        );
      }
      final code = err.response?.statusCode;
      if (code != null) {
        if (code == 401 || code == 403) {
          return const FriendlyError(
            kind: FriendlyErrorKind.unauthorized,
            title: 'Kirish kerak',
            message: 'Sessiya tugadi. Qayta kiring.',
            icon: LucideIcons.keyRound,
            color: Color(0xFFC9A227),
            showRetry: false,
          );
        }
        if (code == 404) {
          return const FriendlyError(
            kind: FriendlyErrorKind.notFound,
            title: 'Topilmadi',
            message: 'So\'ralgan ma\'lumot topilmadi.',
            icon: LucideIcons.searchX,
            color: Color(0xFF6B6B68),
            showRetry: false,
          );
        }
        if (code == 429) {
          return const FriendlyError(
            kind: FriendlyErrorKind.rateLimited,
            title: 'Biroz kuting',
            message: 'Juda ko\'p so\'rov yuborildi. Bir daqiqadan so\'ng urining.',
            icon: LucideIcons.hourglass,
            color: Color(0xFFF59E0B),
          );
        }
        if (code >= 500 && code < 600) {
          return const FriendlyError(
            kind: FriendlyErrorKind.serverError,
            title: 'Xizmat vaqtincha ishlamayapti',
            message:
                '1-2 daqiqadan keyin qayta urinib ko\'ring. Muammo bizda.',
            icon: LucideIcons.serverCrash,
            color: Color(0xFFEF4444),
          );
        }
        if (code >= 400 && code < 500) {
          // Server foydalanuvchi kiritmasidan norozi
          String? detail;
          final data = err.response?.data;
          if (data is Map && data['detail'] is String) {
            detail = data['detail'] as String;
          }
          return FriendlyError(
            kind: FriendlyErrorKind.badRequest,
            title: 'So\'rovda muammo',
            message: detail ?? 'Kiritilgan ma\'lumotni tekshirib qayta urining.',
            icon: LucideIcons.triangleAlert,
            color: const Color(0xFFF59E0B),
            showRetry: false,
          );
        }
      }
    }
    // 4) Umumiy xato
    return const FriendlyError(
      kind: FriendlyErrorKind.unknown,
      title: 'Kutilmagan xatolik',
      message: 'Qayta urinib ko\'ring. Muammo davom etsa yordam so\'rang.',
      icon: LucideIcons.circleAlert,
      color: Color(0xFF6B6B68),
    );
  }

  /// Tarjima: interfeys tili uz/ru bo'lsa mos matn qaytariladi.
  ///
  /// `.tr` allaqachon uz/ru ni qo'llab-quvvatlaydi, shuning uchun bu yerda
  /// oddiy `.tr` chaqiruvi kifoya.
  String get localizedTitle => title.tr;
  String get localizedMessage => message.tr;
}

/// SnackBar shaklida xatoni ko'rsatish (tez, ekran ustidan).
///
/// [onRetry] berilsa "Qayta" tugmasi chiqadi.
void showFriendlyErrorSnack(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  final fe = error is FriendlyError
      ? error
      : FriendlyError.fromException(error);
  // Titrash — foydalanuvchi darhol e'tibor beradi.
  HapticFeedback.mediumImpact();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: fe.color.withValues(alpha: 0.95),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: Row(
        children: [
          Icon(fe.icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fe.localizedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fe.localizedMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      action: (fe.showRetry && onRetry != null)
          ? SnackBarAction(
              label: 'Qayta'.tr,
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

/// Sahifa markazida katta xato ekrani (masalan ro'yxat yuklanmasa).
///
/// [onRetry] berilsa katta tugma bilan chiqadi.
class FriendlyErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  const FriendlyErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final fe = error is FriendlyError
        ? error as FriendlyError
        : FriendlyError.fromException(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Katta rangli aylana — vizual jozibali, foydalanuvchi qo'rqmasin.
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: fe.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(fe.icon, size: 44, color: fe.color),
          ),
          const SizedBox(height: 20),
          Text(
            fe.localizedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : LuxTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fe.localizedMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: isDark ? Colors.white70 : LuxTokens.textMuted,
            ),
          ),
          if (fe.showRetry && onRetry != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetry!();
              },
              style: FilledButton.styleFrom(
                backgroundColor: fe.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text('Qayta urinish'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
