import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/payment_card.dart';
import '../models/service_order.dart';

class AppProvider extends ChangeNotifier {
  UserProfile _user = UserProfile.demo;
  final List<PaymentCard> _cards = [...PaymentCard.demoCards];
  bool _isDarkMode = false;

  /// Foydalanuvchi buyurtmalari (eng yangi — yuqorida).
  final List<ServiceOrder> _orders = [
    ...ServiceOrder.demoOrders.reversed,
  ];

  UserProfile get user => _user;
  List<PaymentCard> get cards => _cards;
  bool get isDarkMode => _isDarkMode;
  double get balance => _user.balance;
  double get cashback => _user.cashback;

  List<ServiceOrder> get orders => List.unmodifiable(_orders);

  List<ServiceOrder> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
      .toList();

  List<ServiceOrder> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void addCard(PaymentCard card) {
    _cards.add(card);
    notifyListeners();
  }

  void removeCard(String cardId) {
    _cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  /// Balansni mutlaq qiymatga o'rnatish (demo).
  void setBalance(double value) {
    _user = _user.copyWith(balance: value < 0 ? 0 : value);
    notifyListeners();
  }

  void addCashback(double amount) {
    if (amount <= 0) return;
    _user = _user.copyWith(cashback: _user.cashback + amount);
    notifyListeners();
  }

  /// Hisob balansini to'ldirish (demo).
  void topUpBalance(double amount) {
    if (amount <= 0) return;
    _user = _user.copyWith(balance: _user.balance + amount);
    notifyListeners();
  }

  /// Yangi buyurtma qo'shish — demo `pending` holatda boshlanadi.
  void addOrder(ServiceOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void cancelOrder(String id) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i == -1) return;
    _orders[i] = _orders[i].copyWith(status: OrderStatus.cancelled);
    notifyListeners();
  }
}
