import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/payment_card.dart';
import '../models/service_order.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../services/notification_helper.dart';
import 'package:super_app/l10n/locale_controller.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  ApiService get api => _api;
  Timer? _notificationTimer;
  Timer? _orderPollTimer;

  UserProfile _user = UserProfile(name: '', surname: '', phone: '');
  final List<PaymentCard> _cards = [];
  bool _isDarkMode = true;
  final List<ServiceOrder> _orders = [];
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  final Map<String, OrderStatus> _knownOrderStatuses = {};
  String? _statusToastMessage;

  UserProfile get user => _user;
  List<PaymentCard> get cards => _cards;
  bool get isDarkMode => _isDarkMode;
  double get balance => _user.balance;
  double get cashback => _user.cashback;
  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Buyurtma holati o'zgarganda SnackBar uchun xabar (bir marta o'qiladi).
  String? consumeStatusToast() {
    final msg = _statusToastMessage;
    _statusToastMessage = null;
    return msg;
  }

  List<ServiceOrder> get orders => List.unmodifiable(_orders);

  List<ServiceOrder> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled,
      )
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
      _seedOrderStatuses();

      await fetchNotifications();
      startNotificationPolling();
      startOrderPolling();

      // Init WebRTC Signaling
      CallService().connectWebSocket();

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
      final categoryId = _categoryIds[categoryKey] ?? order.category.index + 1;

      int providerId = order.providerId ?? 0;
      if (providerId <= 0) {
        try {
          final providersRes = await _api.getProviders(
            categoryKey: categoryKey,
            perPage: 1,
          );
          final List<dynamic> providers = providersRes['items'] ?? [];
          if (providers.isNotEmpty) {
            providerId = providers.first['id'] as int;
          }
        } catch (e) {
          debugPrint('Error fetching provider for order: $e');
        }
      }
      if (providerId <= 0) providerId = 1;

      final payload = {
        'category_id': categoryId,
        'provider_id': providerId,
        'service_name': order.serviceName,
        'address': order.address.isEmpty ? 'Toshkent shahri' : order.address,
        'notes': order.notes,
        'date': order.date.toIso8601String(),
        'price': order.price,
        'booking_mode': order.bookingMode,
      };

      final newOrderData = await _api.createOrder(payload);
      final newOrder = ServiceOrder.fromJson(newOrderData);
      _orders.insert(0, newOrder);
      _knownOrderStatuses[newOrder.id] = newOrder.status;

      final profile = await _api.getMe();
      _user = UserProfile.fromJson(profile);
      notifyListeners();
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        errMsg = '${e.message}\n${e.response?.data}';
      }
      debugPrint('Error adding order: $errMsg');
      throw Exception(errMsg);
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
          _knownOrderStatuses[id] = OrderStatus.cancelled;
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

  Future<void> updateReminderOffset(int offset) async {
    try {
      final updatedData = await _api.updateMe({
        'reminder_offset_minutes': offset,
      });
      _user = UserProfile.fromJson(updatedData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating reminder offset: $e');
      rethrow;
    }
  }

  Future<void> fetchOrders({bool detectChanges = true}) async {
    if (!_api.hasToken) return;
    try {
      final ordersResponse = await _api.getMyOrders();
      final items = ordersResponse['items'] as List<dynamic>? ?? [];
      final fresh = items.map((o) => ServiceOrder.fromJson(o)).toList();

      if (detectChanges) {
        for (final order in fresh) {
          final prev = _knownOrderStatuses[order.id];
          if (prev != null && prev != order.status) {
            _statusToastMessage = '${order.serviceName}: ${order.statusText}';
          }
          _knownOrderStatuses[order.id] = order.status;
        }
      } else {
        _seedOrderStatusesFrom(fresh);
      }

      _orders
        ..clear()
        ..addAll(fresh);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  void _seedOrderStatuses() => _seedOrderStatusesFrom(_orders);

  void _seedOrderStatusesFrom(List<ServiceOrder> orders) {
    _knownOrderStatuses.clear();
    for (final o in orders) {
      _knownOrderStatuses[o.id] = o.status;
    }
  }

  Future<void> fetchNotifications() async {
    if (!_api.hasToken) return;
    try {
      final notifData = await _api.getNotifications();
      _notifications = notifData['notifications'] ?? [];

      final prevUnreadCount = _unreadCount;
      _unreadCount = await _api.getUnreadCount();

      // Show status bar notifications for new unread messages
      final prefs = await SharedPreferences.getInstance();
      final alertedIds = prefs.getStringList('alerted_notification_ids') ?? [];
      final List<String> newAlertedIds = List.from(alertedIds);

      for (var notif in _notifications) {
        final notifId = notif['id'].toString();
        final isRead = notif['is_read'] ?? false;

        if (!isRead && !alertedIds.contains(notifId)) {
          final title = notif['title'] ?? 'Eslatma';
          final message = notif['message'] ?? '';
          final int notificationId = int.tryParse(notifId) ?? notifId.hashCode;

          await NotificationHelper().showNotification(
            notificationId,
            title,
            message,
          );
          newAlertedIds.add(notifId);
        }
      }

      if (newAlertedIds.length > alertedIds.length) {
        await prefs.setStringList('alerted_notification_ids', newAlertedIds);
      }

      if (_unreadCount > prevUnreadCount) {
        await fetchOrders();
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

  void startOrderPolling() {
    _orderPollTimer?.cancel();
    _orderPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await fetchOrders();
    });
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
    _orderPollTimer?.cancel();
    super.dispose();
  }
}
