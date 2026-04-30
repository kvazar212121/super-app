import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/payment_card.dart';

class AppProvider extends ChangeNotifier {
  UserProfile _user = UserProfile.demo;
  List<PaymentCard> _cards = [...PaymentCard.demoCards];
  bool _isDarkMode = false;

  UserProfile get user => _user;
  List<PaymentCard> get cards => _cards;
  bool get isDarkMode => _isDarkMode;
  double get balance => _user.balance;
  double get cashback => _user.cashback;

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

  void updateBalance(double amount) {
    notifyListeners();
  }

  void addCashback(double amount) {
    notifyListeners();
  }
}
