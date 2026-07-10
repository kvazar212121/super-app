import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallLog {
  final String id;
  final int userId;
  final String userName;
  final bool isIncoming;
  final DateTime timestamp;
  final String duration;
  final String status; // 'connected', 'missed', 'declined', 'cancelled'

  CallLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.isIncoming,
    required this.timestamp,
    required this.duration,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'isIncoming': isIncoming,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration,
    'status': status,
  };

  factory CallLog.fromJson(Map<String, dynamic> json) => CallLog(
    id: json['id'] ?? '',
    userId: json['userId'] ?? 0,
    userName: json['userName'] ?? '',
    isIncoming: json['isIncoming'] ?? false,
    timestamp: DateTime.parse(
      json['timestamp'] ?? DateTime.now().toIso8601String(),
    ),
    duration: json['duration'] ?? '',
    status: json['status'] ?? 'missed',
  );
}

class BlockedUser {
  final int userId;
  final String userName;
  final DateTime blockedAt;

  BlockedUser({
    required this.userId,
    required this.userName,
    required this.blockedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'blockedAt': blockedAt.toIso8601String(),
  };

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    userId: json['userId'] ?? 0,
    userName: json['userName'] ?? '',
    blockedAt: DateTime.parse(
      json['blockedAt'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

class CallHistoryService extends ChangeNotifier {
  static final CallHistoryService _instance = CallHistoryService._internal();
  factory CallHistoryService() => _instance;
  CallHistoryService._internal();

  static const String _historyKey = 'webrtc_call_history';
  static const String _blockedKey = 'webrtc_blocked_users';

  List<CallLog> _history = [];
  List<BlockedUser> _blocked = [];

  List<CallLog> get history => _history;
  List<BlockedUser> get blocked => _blocked;

  Future<void> init() async {
    await loadHistory();
    await loadBlockedUsers();
  }

  /// Qo'ng'iroqlar tarixi shu kundan eski bo'lsa saqlanmaydi (1 oy — faqat lokal).
  static const int _retentionDays = 30;

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString(_historyKey);
      if (historyStr != null) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        _history = decoded.map((e) => CallLog.fromJson(e)).toList();
        // 1 oydan eski yozuvlarni tozalaymiz (limitli lokal saqlash)
        final purged = _purgeOld();
        // Saralash (eng yangilari birinchi)
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (purged) await saveHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Call history yuklashda xatolik: $e');
    }
  }

  /// 30 kundan eski yozuvlarni o'chiradi. O'chirilgan bo'lsa true qaytaradi.
  bool _purgeOld() {
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    final before = _history.length;
    _history.removeWhere((e) => e.timestamp.isBefore(cutoff));
    return _history.length != before;
  }

  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyStr);
    } catch (e) {
      debugPrint('Call history saqlashda xatolik: $e');
    }
  }

  Future<void> addCallLog(CallLog log) async {
    _history.insert(0, log);
    notifyListeners();
    await saveHistory();
  }

  /// Bitta qo'ng'iroq yozuvini o'chirish.
  Future<void> deleteCallLog(String logId) async {
    _history.removeWhere((e) => e.id == logId);
    notifyListeners();
    await saveHistory();
  }

  /// Bitta kontaktning barcha qo'ng'iroq yozuvlarini o'chirish.
  Future<void> deleteByUser(int userId) async {
    _history.removeWhere((e) => e.userId == userId);
    notifyListeners();
    await saveHistory();
  }

  Future<void> updateCallLog(
    String logId, {
    String? duration,
    String? status,
  }) async {
    final idx = _history.indexWhere((e) => e.id == logId);
    if (idx != -1) {
      final oldLog = _history[idx];
      _history[idx] = CallLog(
        id: oldLog.id,
        userId: oldLog.userId,
        userName: oldLog.userName,
        isIncoming: oldLog.isIncoming,
        timestamp: oldLog.timestamp,
        duration: duration ?? oldLog.duration,
        status: status ?? oldLog.status,
      );
      notifyListeners();
      await saveHistory();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // --- Blocked Users ---

  Future<void> loadBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedStr = prefs.getString(_blockedKey);
      if (blockedStr != null) {
        final List<dynamic> decoded = jsonDecode(blockedStr);
        _blocked = decoded.map((e) => BlockedUser.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Blocked users yuklashda xatolik: $e');
    }
  }

  Future<void> saveBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedStr = jsonEncode(_blocked.map((e) => e.toJson()).toList());
      await prefs.setString(_blockedKey, blockedStr);
    } catch (e) {
      debugPrint('Blocked users saqlashda xatolik: $e');
    }
  }

  Future<void> blockUser(int userId, String userName) async {
    if (isUserBlocked(userId)) return;
    _blocked.add(
      BlockedUser(
        userId: userId,
        userName: userName,
        blockedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    await saveBlockedUsers();
  }

  Future<void> unblockUser(int userId) async {
    _blocked.removeWhere((e) => e.userId == userId);
    notifyListeners();
    await saveBlockedUsers();
  }

  bool isUserBlocked(int userId) {
    return _blocked.any((e) => e.userId == userId);
  }
}
