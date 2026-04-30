import 'package:flutter/material.dart';

class CashbackCardWidget extends StatelessWidget {
  final double balance;
  final double cashback;
  final bool isPremium;

  const CashbackCardWidget({
    super.key,
    required this.balance,
    required this.cashback,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
            : [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hisob', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('PREMIUM', 
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${balance.toStringAsFixed(0)} so\'m',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keshbek', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  Text('+${cashback.toStringAsFixed(0)} so\'m',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                ],
              ),
              Icon(Icons.card_giftcard, color: Colors.white, size: 32),
            ],
          ),
        ],
      ),
    );
  }
}
