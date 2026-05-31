import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_profile.dart';
import '../models/payment_card.dart';
import '../models/service_order.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Timer? _notificationTimer;

  UserProfile _user = UserProfile(name: '', surname: '', phone: '');
  final List<PaymentCard> _cards = [];
  bool _isDarkMode = false;
  final List<ServiceOrder> _orders = [];
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

  void applyAuthUser(Map<String, dynamic> data) {
    _user = UserProfile.fromJson(data);
    notifyListeners();
  }

  Future<void> _loadCategoryMap() async {
    if (_categoryIds.isNotEmpty) return;
    try {
      final cats = await _api.getCategories();
      for (final c in cats) {
        final key = c['key'] as String?;
        final id = c['id'] as int?;
        if (key != null && id != null) {
          _categoryIds[key] = id;
        }
      }
    } catch (e) {
      debugPrint('Category map load error: $e');
    }
  }

  final Map<String, int> _categoryIds = {};

  Future<void> fetchInitialData() async {
    if (!_api.hasToken) return;
    try {
      await _loadCategoryMap();

      final userData = await _api.getMe();
      _user = UserProfile.fromJson(userData);

      final cardsData = await _api.getCards();
      _cards.clear();
      _cards.addAll(cardsData.map((c) => PaymentCard.fromJson(c)));

      final ordersResponse = await _api.getMyOrders();
      final items = ordersResponse['items'] as List<dynamic>? ?? [];
      _orders.clear();
      _orders.addAll(items.map((o) => ServiceOrder.fromJson(o)));

      await fetchNotifications();
      startNotificationPolling();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
    }
  }

  Future<void> addCard(PaymentCard card) async {
    try {
      final payload = card.toJson();
      final newCardData = await _api.addCard(payload);
      _cards.add(PaymentCard.fromJson(newCardData));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding card: $e');
      rethrow;
    }
  }

  Future<void> removeCard(String cardId) async {
    try {
      final id = int.tryParse(cardId);
      if (id != null) {
        await _api.removeCard(id);
        _cards.removeWhere((c) => c.id == cardId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing card: $e');
      rethrow;
    }
  }

  Future<void> topUpBalance(double amount) async {
    if (amount <= 0) return;
    try {
      final response = await _api.topUpBalance(amount);
      _user = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error topping up balance: $e');
      rethrow;
    }
  }

  Future<void> addOrder(ServiceOrder order) async {
    try {
      await _loadCategoryMap();
      final categoryKey = order.category.name;
      final categoryId =
          _categoryIds[categoryKey] ?? order.category.index + 1;

      int providerId = 1;
      try {
        final providersRes =
            await _api.getProviders(categoryKey: categoryKey, perPage: 1);
        final List<dynamic> providers = providersRes['items'] ?? [];
        if (providers.isNotEmpty) {
          providerId = providers.first['id'] as int;
        }
      } catch (e) {
        debugPrint('Error fetching provider for order: $e');
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

      final profile = await _api.getMe();
      _user = UserProfile.fromJson(profile);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding order: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      final orderId = int.tryParse(id);
      if (orderId != null) {
        await _api.updateOrderStatus(orderId, 'cancelled');
        final i = _orders.indexWhere((o) => o.id == id);
        if (i != -1) {
          _orders[i] = _orders[i].copyWith(status: OrderStatus.cancelled);
        }
        final profile = await _api.getMe();
        _user = UserProfile.fromJson(profile);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }

  Future<void> fetchNotifications() async {
    if (!_api.hasToken) return;
    try {
      final notifData = await _api.getNotifications();
      _notifications = notifData['notifications'] ?? [];

      final prevUnreadCount = _unreadCount;
      _unreadCount = await _api.getUnreadCount();

      if (_unreadCount > prevUnreadCount) {
        final ordersResponse = await _api.getMyOrders();
        final items = ordersResponse['items'] as List<dynamic>? ?? [];
        _orders.clear();
        _orders.addAll(items.map((o) => ServiceOrder.fromJson(o)));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

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
      debugPrint('Error marking notification read: $e');
    }
  }

  void startNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await fetchNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
