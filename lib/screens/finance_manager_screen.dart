import 'package:flutter/material.dart';

class FinanceManagerScreen extends StatelessWidget {
  const FinanceManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening moliyam'),
      ),
      body: const Center(
        child: Text('Moliyaviy menejer tez orada ishga tushadi...'),
      ),
    );
  }
}
