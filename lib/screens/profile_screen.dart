import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = UserProfile.demo;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chiqish"),
        content: const Text("Haqiqatan ham chiqmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hisobdan chiqdingiz")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Chiqish", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hisobni o'chirish"),
        content: const Text("Bu amal qaytarib bo'lmaydi. Davom etasizmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hisob o'chirildi")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("O'chirish", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                child: user.avatarUrl != null
                    ? ClipOval(child: Image.network(user.avatarUrl!))
                    : const Icon(LucideIcons.user, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                "${user.name} ${user.surname}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(user.phone, style: Theme.of(context).textTheme.bodyMedium),
              if (user.telegramUsername != null) ...[
                const SizedBox(height: 4),
                Text(user.telegramUsername!,
                    style: const TextStyle(color: Colors.blue)),
              ],
              const SizedBox(height: 30),
              _buildMenuItem(
                icon: LucideIcons.user,
                title: "Profilni tahrirlash",
                onTap: () {},
              ),
              _buildMenuItem(
                icon: LucideIcons.bell,
                title: "Bildirishnomalar",
                onTap: () {},
              ),
              _buildMenuItem(
                icon: LucideIcons.settings,
                title: "Sozlamalar",
                onTap: () {},
              ),
              _buildMenuItem(
                icon: LucideIcons.helpCircle,
                title: "Yordam",
                onTap: () {},
              ),
              const Divider(height: 30),
              _buildMenuItem(
                icon: LucideIcons.logOut,
                title: "Chiqish",
                onTap: _showLogoutDialog,
                isDestructive: true,
              ),
              _buildMenuItem(
                icon: LucideIcons.trash2,
                title: "Hisobni o'chirish",
                onTap: _showDeleteAccountDialog,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey),
      onTap: onTap,
    );
  }
}
