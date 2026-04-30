import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/card_item_widget.dart';
import '../widgets/cashback_card_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(provider.isDarkMode 
              ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => provider.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(user, theme),
            const SizedBox(height: 20),
            CashbackCardWidget(
              balance: user.balance,
              cashback: user.cashback,
              isPremium: user.isPremium,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Mening kartalarim', theme),
            ...provider.cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardItemWidget(card: card),
            )),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Karta qo\'shish'),
              onTap: () => _showAddCardDialog(context, provider),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Chiqish'),
              onTap: () => _showLogoutDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Hisobni o\'chirish'),
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: user.avatarUrl != null
            ? ClipOval(child: Image.network(user.avatarUrl!))
            : Text(user.name[0], style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.name} ${user.surname}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(user.phone, style: theme.textTheme.bodyMedium),
              if (user.telegramUsername != null)
                Text(user.telegramUsername!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  void _showAddCardDialog(BuildContext context, AppProvider provider) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Karta qo\'shish'),
      content: const Text('Karta ma\'lumotlarini kiriting'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish')),
        ElevatedButton(onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Karta qo\'shildi')));
        }, child: const Text('Qo\'shish')),
      ],
    ));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Chiqish'),
      content: const Text('Haqiqatan chiqasizmi?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Yo\'q')),
        ElevatedButton(onPressed: () => Navigator.pop(context),
          child: const Text('Ha')),
      ],
    ));
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Hisobni o\'chirish'),
      content: const Text('Bu amal qaytarilmaydi! Davom etasizmi?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context),
          child: const Text('O\'chirish')),
      ],
    ));
  }
}
