import 'package:flutter/material.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import 'all_categories_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'Buyurtmalarim',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OrdersFilterWidget(
              currentFilter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: OrdersListWidget(filter: _filter)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AllCategoriesScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yangi buyurtma'),
        ),
      ),
    );
  }
}
