import 'package:flutter/material.dart';
import '../models/service_order.dart';
import 'auth_guard.dart';

/// Barcha booking ekranlari uchun yagona buyurtma yuborish.
Future<bool> submitBooking(
  BuildContext context,
  ServiceOrder order, {
  String? successMessage,
}) async {
  final placed = await placeOrder(context, order);
  if (!placed || !context.mounted) return false;

  if (successMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return true;
}
