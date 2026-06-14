class FinanceRecord {
  final int id;
  final String type; // "income" or "expense"
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  FinanceRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  factory FinanceRecord.fromJson(Map<String, dynamic> json) {
    return FinanceRecord(
      id: json['id'] as int,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toUtc().toIso8601String(),
    };
  }
}

class FinanceCategoryStat {
  final String category;
  final double amount;
  final double percentage;

  FinanceCategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory FinanceCategoryStat.fromJson(Map<String, dynamic> json) {
    return FinanceCategoryStat(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class FinanceStats {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<FinanceCategoryStat> categoryStats;
  final String insight;

  FinanceStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryStats,
    required this.insight,
  });

  factory FinanceStats.fromJson(Map<String, dynamic> json) {
    var statsList = json['category_stats'] as List? ?? [];
    return FinanceStats(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      categoryStats: statsList.map((e) => FinanceCategoryStat.fromJson(e)).toList(),
      insight: json['insight'] as String? ?? '',
    );
  }
}

class PlannedPayment {
  final int id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final DateTime dueDate;
  final bool isRecurring;
  final bool isPaid;
  final bool isNotified;

  PlannedPayment({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.dueDate,
    required this.isRecurring,
    required this.isPaid,
    required this.isNotified,
  });

  factory PlannedPayment.fromJson(Map<String, dynamic> json) {
    return PlannedPayment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      isPaid: json['is_paid'] as bool? ?? false,
      isNotified: json['is_notified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'due_date': dueDate.toUtc().toIso8601String(),
      'is_recurring': isRecurring,
      'is_paid': isPaid,
      'is_notified': isNotified,
    };
  }
}
