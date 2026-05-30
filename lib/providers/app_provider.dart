import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_profile.dart';
import '../models/payment_card.dart';
import '../models/service_order.dart';
import '../models/service_hub_kind.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Timer? _notificationTimer;

  UserProfile _user = UserProfile.demo;
  final List<PaymentCard> _cards = [...PaymentCard.demoCards];
  bool _isDarkMode = false;
  final List<ServiceOrder> _orders = [
    ...ServiceOrder.demoOrders.reversed,
  ];
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  UserProfile get user => _user;
  List<PaymentCard> get cards => _cards;
  bool get isDarkMode => _isDarkMode;
  double get balance => _user.balance;
  double get cashback => _user.cashback;
  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;

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

  /// API orqali dastlabki ma'lumotlarni yuklash
  Future<void> fetchInitialData() async {
    if (!_api.hasToken) return;
    try {
      // 1. Profilni yuklash
      final userData = await _api.getMe();
      _user = UserProfile.fromJson(userData);
      
      // 2. Kartalarni yuklash
      final cardsData = await _api.getCards();
      _cards.clear();
      _cards.addAll(cardsData.map((c) => PaymentCard.fromJson(c)));

      // 3. Buyurtmalarni yuklash
      final ordersResponse = await _api.getMyOrders();
      final items = ordersResponse['items'] as List<dynamic>? ?? [];
      _orders.clear();
      _orders.addAll(items.map((o) => ServiceOrder.fromJson(o)));

      // 4. Bildirishnomalarni yuklash
      await fetchNotifications();

      // 5. Pollingni boshlash
      startNotificationPolling();

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching initial data: $e");
    }
  }

  /// Yangi karta qo'shish (API)
  Future<void> addCard(PaymentCard card) async {
    try {
      final payload = card.toJson();
      final newCardData = await _api.addCard(payload);
      _cards.add(PaymentCard.fromJson(newCardData));
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding card: $e");
      rethrow;
    }
  }

  /// Kartani o'chirish (API)
  Future<void> removeCard(String cardId) async {
    try {
      final id = int.tryParse(cardId);
      if (id != null) {
        await _api.removeCard(id);
        _cards.removeWhere((c) => c.id == cardId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error removing card: $e");
      rethrow;
    }
  }

  /// Balansni to'ldirish (API)
  Future<void> topUpBalance(double amount) async {
    if (amount <= 0) return;
    try {
      final response = await _api.topUpBalance(amount);
      _user = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint("Error topping up balance: $e");
      rethrow;
    }
  }

  /// Yangi buyurtma yaratish va profilni yangilash (API)
  Future<void> addOrder(ServiceOrder order) async {
    try {
      final categoryId = order.category.index + 1;
      
      // Kategoriya uchun provayderni olish (baza seed qilingan)
      int providerId = 1;
      try {
        final providersRes = await _api.getProviders(categoryId: categoryId);
        final List<dynamic> providers = providersRes['items'] ?? [];
        if (providers.isNotEmpty) {
          providerId = providers.first['id'] as int;
        }
      } catch (e) {
        debugPrint("Error fetching provider for order: $e");
      }

      final payload = {
        'category_id': categoryId,
        'provider_id': providerId,
        'service_name': order.serviceName,
        'address': order.address.isEmpty ? 'Toshkent shahri' : order.address,
        'notes': order.notes,
        'date': order.date.toIso8601String(),
        'price': order.price,
      };

      final newOrderData = await _api.createOrder(payload);
      final newOrder = ServiceOrder.fromJson(newOrderData);
      _orders.insert(0, newOrder);
      
      // Balans/cashback yangilanishi uchun profilni qayta yuklash
      final profile = await _api.getMe();
      _user = UserProfile.fromJson(profile);

      notifyListeners();
    } catch (e) {
      debugPrint("Error adding order: $e");
      rethrow;
    }
  }

  /// Buyurtmani bekor qilish (API)
  Future<void> cancelOrder(String id) async {
    try {
      final orderId = int.tryParse(id);
      if (orderId != null) {
        await _api.updateOrderStatus(orderId, 'cancelled');
        final i = _orders.indexWhere((o) => o.id == id);
        if (i != -1) {
          _orders[i] = _orders[i].copyWith(status: OrderStatus.cancelled);
        }
        
        // Hisob balansiga pul qaytishi mumkin bo'lgani uchun profilni yangilash
        final profile = await _api.getMe();
        _user = UserProfile.fromJson(profile);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error cancelling order: $e");
      rethrow;
    }
  }

  /// Bildirishnomalarni API orqali yangilash
  Future<void> fetchNotifications() async {
    if (!_api.hasToken) return;
    try {
      final notifData = await _api.getNotifications();
      _notifications = notifData['notifications'] ?? [];
      
      final prevUnreadCount = _unreadCount;
      _unreadCount = await _api.getUnreadCount();

      // Agar o'qilmagan xabarlar ko'paygan bo'lsa, demak yangi xabar kelgan (masalan, buyurtma holati o'zgargan)
      // Shunda buyurtmalar ro'yxatini ham yangilaymiz!
      if (_unreadCount > prevUnreadCount) {
        final ordersResponse = await _api.getMyOrders();
        final items = ordersResponse['items'] as List<dynamic>? ?? [];
        _orders.clear();
        _orders.addAll(items.map((o) => ServiceOrder.fromJson(o)));
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  /// Bildirishnomani o'qilgan deb belgilash
  Future<void> markNotificationRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
      }
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }

  /// Real-time sinxronizatsiya uchun pollingni boshlash (har 10 soniyada)
  void startNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await fetchNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
