import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/payment_card.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';

class CardItemWidget extends StatelessWidget {
  final PaymentCard card;

  const CardItemWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isUzcard = card.cardType == 'uzcard';

    return ClipRRect(
      borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUzcard
                  ? [const Color(0xFF00A8E1), const Color(0xFF0077B5)]
                  : [const Color(0xFF00C853), const Color(0xFF069668)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
            border: Border.all(color: Colors.white),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.cardType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (card.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: LuxTokens.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ASOSIY',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                card.maskedNumber,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Karta egasi',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        card.cardHolder,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Muddati',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        card.expiryDate,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
