import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import '../models/daily_models.dart';
import '../services/api_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<ShoppingListModel> _lists = [];
  
  final List<ShoppingListItem> _currentItems = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  Timer? _debounce;
  double _currentTotal = 0;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getShoppingLists();
      setState(() {
        _lists = data.map((e) => ShoppingListModel.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Error loading shopping lists: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateItemPrice() async {
    if (_itemController.text.trim().isEmpty) return;
    
    setState(() => _isCalculating = true);
    try {
      final qty = double.tryParse(_qtyController.text) ?? 1.0;
      final tempItem = {'name': _itemController.text.trim(), 'quantity': qty};
      
      final res = await _api.calculateShoppingPrice([tempItem]);
      final calcItems = res['items'] as List;
      if (calcItems.isNotEmpty) {
        final estPrice = (calcItems[0]['estimated_price'] as num).toDouble();
        setState(() {
          _currentItems.add(ShoppingListItem(
            name: _itemController.text.trim(),
            quantity: qty,
            estimatedPrice: estPrice,
          ));
          _currentTotal += estPrice;
          _itemController.clear();
          _qtyController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xatolik yuz berdi')));
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _saveList() async {
    if (_currentItems.isEmpty) return;
    try {
      final itemsMap = _currentItems.map((e) => e.toJson()).toList();
      final res = await _api.createShoppingList('Mening bozorligim ${DateTime.now().day}', itemsMap, _currentTotal);
      setState(() {
        _lists.insert(0, ShoppingListModel.fromJson(res));
        _currentItems.clear();
        _currentTotal = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ro\'yxat saqlandi!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlashda xatolik')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Aqlli Savdo',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: GlassTokens.secondaryText(context),
              tabs: const [
                Tab(text: 'Yangi ro\'yxat'),
                Tab(text: 'Saqlanganlar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNewListTab(),
                  _buildSavedListsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewListTab() {
    return Column(
      children: [
        _buildInputArea(),
        Expanded(
          child: _currentItems.isEmpty
              ? const Center(child: Text("Mahsulotlar qo'shing"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _currentItems.length,
                  itemBuilder: (context, index) {
                    final item = _currentItems[index];
                    return ListTile(
                      title: Text(item.name, style: TextStyle(color: GlassTokens.primaryText(context))),
                      subtitle: Text('${item.quantity} miqdor', style: TextStyle(color: GlassTokens.secondaryText(context))),
                      trailing: Text('${item.estimatedPrice} so\'m', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        if (_currentItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black45,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Taxminiy jami:', style: TextStyle(color: GlassTokens.secondaryText(context))),
                    Text('$_currentTotal so\'m', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _saveList,
                  child: const Text('Saqlash'),
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _itemController,
              decoration: InputDecoration(
                hintText: 'Mahsulot nomi...',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: GlassTokens.primaryText(context)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Soni/Kg',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: GlassTokens.primaryText(context)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: _isCalculating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(LucideIcons.plus, color: Colors.white),
              onPressed: _isCalculating ? null : _calculateItemPrice,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSavedListsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lists.isEmpty) return const Center(child: Text("Saqlangan ro'yxatlar yo'q"));
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _lists.length,
      itemBuilder: (context, index) {
        final list = _lists[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(list.title, style: TextStyle(color: GlassTokens.primaryText(context))),
            subtitle: Text('${list.totalEstimatedPrice} so\'m', style: const TextStyle(color: Colors.orange)),
            children: list.items.map((i) => ListTile(
              title: Text(i.name, style: TextStyle(color: GlassTokens.primaryText(context), fontSize: 14)),
              trailing: Text('${i.quantity} | ${i.estimatedPrice} so\'m', style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 12)),
            )).toList(),
          ),
        );
      },
    );
  }
}
