import 'package:flutter/material.dart';
import '../models/payment_card.dart';

class CardItemWidget extends StatelessWidget {
  final PaymentCard card;

  const CardItemWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUzcard = card.cardType == 'uzcard';
    
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUzcard
              ? [const Color(0xFF00A8E1), const Color(0xFF0077B5)]
              : [const Color(0xFF00C853), const Color(0xFF69F0AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(card.cardType.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
                if (card.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ASOSIY',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(card.maskedNumber,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Karta egasi',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    Text(card.cardHolder,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Muddati',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    Text(card.expiryDate,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
