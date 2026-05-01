import 'package:flutter/material.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import 'all_categories_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = "all";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buyurtmalarim"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OrdersFilterWidget(
              currentFilter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),
          Expanded(child: OrdersListWidget(filter: _filter)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const AllCategoriesScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text("Yangi buyurtma"),
      ),
    );
  }
}
