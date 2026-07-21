
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
    };
  }
}

class ProductCatalogItem {
  final String id;
  final String name;
  final String unit;
  final double averagePrice;

  ProductCatalogItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.averagePrice,
  });

  factory ProductCatalogItem.fromJson(Map<String, dynamic> json) {
    return ProductCatalogItem(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      averagePrice: (json['average_price'] as num).toDouble(),
    );
  }
}

class ShoppingListItem {
  final String name;
  final double qty;
  final String unit;
  final double unitPrice;
  final double estimatedPrice;
  final double? actualPrice;
  final bool isBought;

  ShoppingListItem({
    required this.name,
    this.qty = 1.0,
    this.unit = 'dona',
    this.unitPrice = 0.0,
    required this.estimatedPrice,
    this.actualPrice,
    this.isBought = false,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      name: json['name'] ?? '',
      qty:
          (json['qty'] as num?)?.toDouble() ??
          (json['quantity'] as num?)?.toDouble() ??
          1.0,
      unit: json['unit'] ?? 'dona',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
      actualPrice: (json['actual_price'] as num?)?.toDouble(),
      isBought: json['is_bought'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'unit': unit,
      'unit_price': unitPrice,
      'estimated_price': estimatedPrice,
      'actual_price': actualPrice,
      'is_bought': isBought,
    };
  }

  /// Display price: actual if set, else estimated
  double get displayPrice => actualPrice ?? estimatedPrice;
}

class ShoppingListModel {
  final int id;
  final String name;
  final List<ShoppingListItem> items;
  final double totalEstimatedPrice;
  final double totalActualPrice;
  final bool isCompleted;
  final DateTime createdAt;

  ShoppingListModel({
    required this.id,
    required this.name,
    required this.items,
    required this.totalEstimatedPrice,
    this.totalActualPrice = 0.0,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return ShoppingListModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Bozorlik',
      items: itemsList
          .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEstimatedPrice:
          (json['total_estimated_price'] as num?)?.toDouble() ?? 0.0,
      totalActualPrice: (json['total_actual_price'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }

  int get boughtCount => items.where((i) => i.isBought).length;
}

class PlanItem {
  final int id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}
