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
  final double quantity;
  final double estimatedPrice;

  ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.estimatedPrice,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
    };
  }
}

class ShoppingListModel {
  final String id;
  final String title;
  final List<ShoppingListItem> items;
  final double totalEstimatedPrice;

  ShoppingListModel({
    required this.id,
    required this.title,
    required this.items,
    required this.totalEstimatedPrice,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return ShoppingListModel(
      id: json['id'],
      title: json['title'],
      items: itemsList.map((e) => ShoppingListItem.fromJson(e)).toList(),
      totalEstimatedPrice: (json['total_estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
