import 'package:flutter/material.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import '../widgets/glass/glass_scaffold.dart';

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
      embeddedInShell: true,
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
    );
  }
}
