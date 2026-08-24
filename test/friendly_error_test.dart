import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/widgets/friendly_error.dart';

void main() {
  group('FriendlyError xatolarni tushunarli qiladi', () {
    test('SocketException → Internet yo\'q', () {
      final fe = FriendlyError.fromException(
        const SocketException('failed'),
      );
      expect(fe.kind, FriendlyErrorKind.noInternet);
      expect(fe.title, 'Internet yo\'q');
      expect(fe.showRetry, true);
      // MUHIM: foydalanuvchi "500" yoki "SocketException" ko'rmasin
      expect(fe.message.contains('500'), false);
      expect(fe.message.toLowerCase().contains('exception'), false);
    });

    test('TimeoutException → Sekin internet', () {
      final fe = FriendlyError.fromException(TimeoutException('slow'));
      expect(fe.kind, FriendlyErrorKind.timeout);
      expect(fe.title, 'Sekin internet');
    });

    test('DioException 500 → Server error, retry ko\'rinadi', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.serverError);
      expect(fe.title, 'Xizmat vaqtincha ishlamayapti');
      expect(fe.showRetry, true);
      // Foydalanuvchi 500 raqamini KO'RMASIN
      expect(fe.title.contains('500'), false);
      expect(fe.message.contains('500'), false);
    });

    test('DioException 401 → Kirish kerak, retry yo\'q', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.unauthorized);
      expect(fe.showRetry, false);
    });

    test('DioException 429 → Rate limited', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.rateLimited);
      expect(fe.title, 'Biroz kuting');
    });

    test('DioException connectionError → Internet yo\'q', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.noInternet);
    });

    test('DioException receiveTimeout → Sekin internet', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.timeout);
    });

    test('DioException 400 + detail → detail matni ko\'rsatiladi', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {'detail': 'Balansingiz yetarli emas'},
        ),
        type: DioExceptionType.badResponse,
      );
      final fe = FriendlyError.fromException(err);
      expect(fe.kind, FriendlyErrorKind.badRequest);
      expect(fe.message, 'Balansingiz yetarli emas');
      expect(fe.showRetry, false);
    });

    test('Umumiy exception → unknown, lekin oshkora emas', () {
      final fe = FriendlyError.fromException(Exception('some internal thing'));
      expect(fe.kind, FriendlyErrorKind.unknown);
      // Foydalanuvchi "Exception: some internal thing" ni ko'rmasin
      expect(fe.message.contains('internal'), false);
      expect(fe.message.contains('Exception'), false);
    });
  });
}
