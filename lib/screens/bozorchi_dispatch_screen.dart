import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/master_worker.dart';
import '../models/daily_models.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';

class BozorchiDispatchScreen extends StatefulWidget {
  final Master bozorchi;
  final ShoppingListModel? shoppingList;

  const BozorchiDispatchScreen({
    super.key,
    required this.bozorchi,
    this.shoppingList,
  });

  @override
  State<BozorchiDispatchScreen> createState() => _BozorchiDispatchScreenState();
}

class _BozorchiDispatchScreenState extends State<BozorchiDispatchScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _sendDispatch() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, manzilingizni kiriting')),
      );
      return;
    }

    setState(() => _isSending = true);

    // Xuddi kuryerdagidek haqiqiy jo'natish mantig'ini bu yerda API orqali qilamiz
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isSending = false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Jo\'natildi!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.shoppingList != null 
                    ? '${widget.bozorchi.name} ro\'yxatingizni oldi. U siz bilan bog\'lanadi va bozorlikni boshlaydi.'
                    : '${widget.bozorchi.name} tez orada siz bilan aloqaga chiqadi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(ctx); // Profilga qaytish
                    if (widget.shoppingList != null) {
                      Navigator.pop(ctx); // Shopping listga qaytish
                    }
                  },
                  child: const Text('Yopish'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      showBackButton: true,
      title: 'Bozorchini jo\'natish',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Shopper summary
          GlassSurface(
            padding: const EdgeInsets.all(16),
            borderRadius: GlassTokens.radiusLg,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withOpacity(0.1),
                  child: const Icon(LucideIcons.user, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bozorchi.name,
                        style: TextStyle(
                          color: GlassTokens.primaryText(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tekshirilgan',
                            style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (widget.shoppingList != null) ...[
            Text(
              'Xarid qilinadigan narsalar:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GlassTokens.glassBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.clipboardList, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.shoppingList!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...widget.shoppingList!.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Text('•', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(color: GlassTokens.primaryText(context)),
                          ),
                        ),
                        Text(
                          '${item.qty} ${item.unit}',
                          style: TextStyle(color: GlassTokens.secondaryText(context)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Yetkazib berish manzili',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Toshkent sh., Yunusobod tumani...',
              hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
              prefixIcon: Icon(LucideIcons.mapPin, color: accent),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: GlassTokens.primaryText(context)),
          ),
          const SizedBox(height: 24),

          Text(
            'Bozorchiga izoh (ixtiyoriy)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Sifatli go'sht tanlashni unutmang...",
              hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: GlassTokens.primaryText(context)),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isSending ? null : _sendDispatch,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSending
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Jo'natish", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Eslatma: Narxlar kelishuv asosida bozorchi bilan belgilanishi mumkin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 12),
          )
        ],
      ),
    );
  }
}
