import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/payment_card.dart';
import '../theme/glass_tokens.dart';

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
                  ? [
                      const Color(0xFF00A8E1).withValues(alpha: 0.85),
                      const Color(0xFF0077B5).withValues(alpha: 0.75),
                    ]
                  : [
                      const Color(0xFF00C853).withValues(alpha: 0.85),
                      const Color(0xFF069668).withValues(alpha: 0.75),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
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
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                      ),
                      Text(card.cardHolder, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Muddati',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                      ),
                      Text(card.expiryDate, style: const TextStyle(color: Colors.white)),
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
