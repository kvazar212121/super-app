import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import '../models/daily_models.dart';
import '../models/service_hub_kind.dart';
import '../services/hub_data_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import '../services/api_service.dart';
import '../l10n/locale_controller.dart';
import 'bozorchi_profile_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ShoppingListModel> _lists = [];

  // New list builder state
  final List<ShoppingListItem> _currentItems = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();
  String _selectedUnit = 'kg';
  double _currentTotal = 0;
  bool _isCalculating = false;

  static const List<String> _units = ['kg', 'dona', 'litr', 'bog\'', 'qadoq'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemController.dispose();
    _qtyController.dispose();
    _listNameController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getShoppingLists();
      setState(() {
        _lists = data
            .map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading shopping lists: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCalculating = true);
    try {
      final qty = double.tryParse(_qtyController.text) ?? 1.0;
      final res = await _api.calculateShoppingPrice([
        {'name': name, 'qty': qty, 'unit': _selectedUnit},
      ]);
      final calcItems = res['items'] as List;
      if (calcItems.isNotEmpty) {
        final item = calcItems[0] as Map<String, dynamic>;
        setState(() {
          _currentItems.add(ShoppingListItem.fromJson(item));
          _currentTotal += (item['estimated_price'] as num).toDouble();
          _itemController.clear();
          _qtyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Narx hisoblashda xatolik'.tr),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  void _removeItem(int index) {
    setState(() {
      _currentTotal -= _currentItems[index].estimatedPrice;
      _currentItems.removeAt(index);
    });
  }

  Future<void> _saveList() async {
    if (_currentItems.isEmpty) return;
    final name = _listNameController.text.trim().isNotEmpty
        ? _listNameController.text.trim()
        : 'Bozorlik ${DateTime.now().day}.${DateTime.now().month}';
    try {
      final itemsMap = _currentItems.map((e) => e.toJson()).toList();
      final res = await _api.createShoppingList(name, itemsMap);
      setState(() {
        _lists.insert(0, ShoppingListModel.fromJson(res));
        _currentItems.clear();
        _currentTotal = 0;
        _listNameController.clear();
      });
      _tabController.animateTo(1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ro\'yxat saqlandi! ✅'.tr),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saqlashda xatolik'.tr),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _toggleBought(int listIndex, int itemIndex) async {
    final list = _lists[listIndex];
    final item = list.items[itemIndex];
    try {
      final updated = await _api.updateShoppingItem(
        list.id,
        itemIndex,
        isBought: !item.isBought,
      );
      setState(() {
        _lists[listIndex] = ShoppingListModel.fromJson(updated);
      });
    } catch (e) {
      debugPrint("Error toggling item: $e");
    }
  }

  Future<void> _setActualPrice(int listIndex, int itemIndex) async {
    final list = _lists[listIndex];
    final item = list.items[itemIndex];

    final controller = TextEditingController(
      text:
          item.actualPrice?.toStringAsFixed(0) ??
          item.estimatedPrice.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTokens.glassFill(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Haqiqiy narx'.tr,
          style: TextStyle(color: GlassTokens.primaryText(ctx)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.name} (${item.qty} ${item.unit.tr})',
              style: TextStyle(color: GlassTokens.secondaryText(ctx)),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    suffixText: 'so\'m'.tr,
                    suffixStyle: TextStyle(
                      color: GlassTokens.secondaryText(ctx),
                    ),
                    hintText: 'Narxni kiriting'.tr,
                    hintStyle: TextStyle(color: GlassTokens.secondaryText(ctx)),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: GlassTokens.primaryText(ctx),
                    fontSize: 18,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Bekor'.tr,
              style: TextStyle(color: GlassTokens.secondaryText(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final v = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(ctx, v);
            },
            child: Text('Saqlash'.tr),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updated = await _api.updateShoppingItem(
          list.id,
          itemIndex,
          actualPrice: result,
          isBought: true,
        );
        setState(() {
          _lists[listIndex] = ShoppingListModel.fromJson(updated);
        });
      } catch (e) {
        debugPrint("Error updating price: $e");
      }
    }
  }

  Future<void> _deleteList(int index) async {
    final list = _lists[index];
    try {
      await _api.deleteShoppingList(list.id);
      setState(() => _lists.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('O\'chirildi'.tr),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting list: $e");
    }
  }

  String _formatPrice(double price) {
    if (price == 0) return '—';
    final p = price.toInt();
    final s = p.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} ${'so\'m'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: '🛒 Aqlli Savdo'.tr,
      resizeToAvoidBottomInset:
          false, // Prevent keyboard from causing bottom overflow
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelColor: Colors.orange,
          unselectedLabelColor: GlassTokens.secondaryText(context),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: '+ Yangi ro\'yxat'.tr),
            Tab(text: '📋 Saqlanganlar'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNewListTab(), _buildSavedListsTab()],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: New List Builder
  // ══════════════════════════════════════════════════════════

  Widget _buildNewListTab() {
    return Column(
      children: [
        _buildListNameInput(),
        _buildInputArea(),
        Expanded(
          child: _currentItems.isEmpty
              ? _buildEmptyNewList()
              : _buildCurrentItemsList(),
        ),
        if (_currentItems.isNotEmpty) _buildTotalBar(),
      ],
    );
  }

  Widget _buildListNameInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _listNameController,
        decoration: InputDecoration(
          hintText: 'Ro\'yxat nomi (masalan: "Haftalik bozorlik")'.tr,
          hintStyle: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 13,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          prefixIcon: Icon(
            LucideIcons.tag,
            color: Colors.orange.shade300,
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        style: TextStyle(color: GlassTokens.primaryText(context), fontSize: 14),
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _itemController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Mahsulot nomi...'.tr,
                    hintStyle: TextStyle(
                      color: GlassTokens.secondaryText(context),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.03),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: GlassTokens.secondaryText(context),
                      size: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  style: TextStyle(color: GlassTokens.primaryText(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Soni'.tr,
                    hintStyle: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.03),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  style: TextStyle(color: GlassTokens.primaryText(context)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontSize: 14,
                    ),
                    icon: Icon(
                      LucideIcons.chevronDown,
                      color: GlassTokens.secondaryText(context),
                      size: 16,
                    ),
                    items: _units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u.tr,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v ?? 'kg'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isCalculating ? null : _addItem,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isCalculating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              LucideIcons.plus,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shoppingBasket, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Mahsulotlar qo\'shing'.tr,
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI narxlarni taxmin qiladi'.tr,
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentItemsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _currentItems.length,
      itemBuilder: (context, index) {
        final item = _currentItems[index];
        return Dismissible(
          key: ValueKey('new_item_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade800,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(LucideIcons.trash2, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTokens.glassBorder(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _getItemEmoji(item.name),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: GlassTokens.primaryText(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${item.qty} ${item.unit.tr}${item.unitPrice > 0 ? ' × ${_formatPrice(item.unitPrice)}' : ''}',
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatPrice(item.estimatedPrice),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black],
        ),
        border: Border(top: BorderSide(color: Colors.white)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taxminiy jami:'.tr,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(_currentTotal),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_currentItems.length} ${'mahsulot'.tr}',
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _saveList,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.save,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saqlash'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: Saved Lists
  // ══════════════════════════════════════════════════════════

  Widget _buildSavedListsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    if (_lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Saqlangan ro\'yxatlar yo\'q'.tr,
              style: TextStyle(
                color: GlassTokens.secondaryText(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _lists.length,
      itemBuilder: (context, index) => _buildSavedListCard(index),
    );
  }

  Widget _buildSavedListCard(int listIndex) {
    final list = _lists[listIndex];
    final progress = list.items.isEmpty
        ? 0.0
        : list.boughtCount / list.items.length;
    final isDone = list.isCompleted;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(
          color: isDone ? Colors.green : GlassTokens.glassBorder(context),
        ),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDone
                    ? [Colors.green, Colors.teal]
                    : [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isDone ? '✅' : '🛒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          title: Text(
            list.name,
            style: TextStyle(
              color: GlassTokens.primaryText(context),
              fontWeight: FontWeight.w700,
              fontSize: 15,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${'Taxminiy:'.tr} ${_formatPrice(list.totalEstimatedPrice)}',
                style: TextStyle(
                  color: GlassTokens.secondaryText(context),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (list.totalActualPrice > 0)
                Text(
                  '${'Haqiqiy:'.tr} ${_formatPrice(list.totalActualPrice)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation(
                          isDone ? Colors.green : Colors.orange,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list.boughtCount}/${list.items.length}',
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              LucideIcons.trash2,
              color: Colors.red.shade400,
              size: 18,
            ),
            onPressed: () => _confirmDelete(listIndex),
          ),
          children: [
            ...list.items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              return _buildSavedItemRow(listIndex, itemIndex, item);
            }),
            if (!isDone)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _hireBozorchi(list),
                    icon: Icon(LucideIcons.shoppingBag),
                    label: Text('Bozorchi yollash'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedItemRow(
    int listIndex,
    int itemIndex,
    ShoppingListItem item,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: () => _setActualPrice(listIndex, itemIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.isBought
              ? Colors.green.withOpacity(0.15)
              : (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isBought
                ? Colors.green.withOpacity(0.3)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => _toggleBought(listIndex, itemIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isBought ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isBought
                        ? Colors.green
                        : GlassTokens.secondaryText(context),
                    width: 2,
                  ),
                ),
                child: item.isBought
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Emoji
            Text(
              _getItemEmoji(item.name),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: item.isBought
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    '${item.qty} ${item.unit.tr}',
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.actualPrice != null) ...[
                  Text(
                    _formatPrice(item.actualPrice!),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _formatPrice(item.estimatedPrice),
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ] else
                  Text(
                    _formatPrice(item.estimatedPrice),
                    style: TextStyle(
                      color: item.estimatedPrice > 0
                          ? Colors.orange
                          : GlassTokens.secondaryText(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTokens.glassFill(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'O\'chirish'.tr,
          style: TextStyle(color: GlassTokens.primaryText(ctx)),
        ),
        content: Text(
          'Bu ro\'yxatni o\'chirmoqchimisiz?'.tr,
          style: TextStyle(color: GlassTokens.secondaryText(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Yo\'q'.tr,
              style: TextStyle(color: GlassTokens.secondaryText(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteList(index);
            },
            child: Text('Ha, o\'chirish'.tr),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════

  String _getItemEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('olma')) return '🍎';
    if (n.contains('banan')) return '🍌';
    if (n.contains('anor')) return '🍎';
    if (n.contains('uzum')) return '🍇';
    if (n.contains('pomidor')) return '🍅';
    if (n.contains('bodring')) return '🥒';
    if (n.contains('kartoshka')) return '🥔';
    if (n.contains('piyoz')) return '🧅';
    if (n.contains('sarimsoq')) return '🧄';
    if (n.contains('sabzi')) return '🥕';
    if (n.contains('karam')) return '🥬';
    if (n.contains('go\'sht') || n.contains('gosht')) return '🥩';
    if (n.contains('tovuq')) return '🍗';
    if (n.contains('baliq')) return '🐟';
    if (n.contains('sut')) return '🥛';
    if (n.contains('tuxum')) return '🥚';
    if (n.contains('non')) return '🍞';
    if (n.contains('guruch')) return '🍚';
    if (n.contains('moy')) return '🫒';
    if (n.contains('shakar')) return '🍬';
    if (n.contains('choy')) return '🍵';
    if (n.contains('kofe')) return '☕';
    if (n.contains('suv')) return '💧';
    if (n.contains('tarvuz')) return '🍉';
    if (n.contains('qovun')) return '🍈';
    if (n.contains('limon')) return '🍋';
    if (n.contains('nok')) return '🍐';
    if (n.contains('gilos')) return '🍒';
    if (n.contains('makaron')) return '🍝';
    if (n.contains('un')) return '🌾';
    if (n.contains('pishloq')) return '🧀';
    if (n.contains('kolbasa') || n.contains('sosiska')) return '🌭';
    return '🛍️';
  }

  void _hireBozorchi(ShoppingListModel list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BozorchiSelectionSheet(list: list),
    );
  }
}

class _BozorchiSelectionSheet extends StatefulWidget {
  final ShoppingListModel list;
  const _BozorchiSelectionSheet({required this.list});

  @override
  State<_BozorchiSelectionSheet> createState() =>
      _BozorchiSelectionSheetState();
}

class _BozorchiSelectionSheetState extends State<_BozorchiSelectionSheet> {
  final HubDataService _hubDataService = HubDataService();
  bool _isLoading = true;
  List<dynamic> _bozorchilar = [];

  @override
  void initState() {
    super.initState();
    _loadBozorchilar();
  }

  Future<void> _loadBozorchilar() async {
    try {
      final providers = await _hubDataService.fetchProviders(
        ServiceHubKind.bozorchi,
      );
      if (mounted) {
        setState(() {
          _bozorchilar = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bozorchilar: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shoppingBag,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bo\'sh bozorchilar'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ro\'yxatni topshirish uchun tanlang'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : _bozorchilar.isEmpty
                ? Center(child: Text('Hozircha bo\'sh bozorchilar yo\'q'.tr))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _bozorchilar.length,
                    itemBuilder: (context, index) {
                      final b = _bozorchilar[index];
                      return Card(
                        elevation: 0,
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                child: const Icon(
                                  LucideIcons.user,
                                  color: Colors.orange,
                                ),
                              ),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ),
                          title: Text(
                            b.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text('${b.rating} • ${'Shahar bo\'ylab'.tr}'),
                            ],
                          ),
                          trailing: FilledButton(
                            onPressed: () {
                              Navigator.pop(context); // Close sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BozorchiProfileScreen(
                                    bozorchi: b,
                                    initialList: widget.list,
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Tanlash'.tr),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
