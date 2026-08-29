import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';

/// Provayder hisob (balans) kartasi.
/// Balans — provayder lead-fee (mijoz topish komissiyasi) hamyoni.
/// (Keshbek tizimi olib tashlandi — biz to'lov tizimi emasmiz.)
class AccountBalanceCard extends StatelessWidget {
  final double balance;
  final bool isPremium;

  const AccountBalanceCard({
    super.key,
    required this.balance,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: LuxTokens.goldBoxDecoration(radius: GlassTokens.radiusLg),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hisob',
                    style: LuxTokens.goldEngravedTextStyle.copyWith(fontSize: 15),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140D02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PREMIUM',
                        style: LuxTokens.goldEngravedTextStyle.copyWith(
                          color: LuxTokens.gold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${balance.toStringAsFixed(0)} so\'m',
                style: LuxTokens.goldEngravedTextStyle.copyWith(
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF140D02),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Xizmat hisobingiz',
                    style: TextStyle(
                      color: Color(0xFF332205),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
