import 'service_hub_kind.dart';

enum OrderStatus { pending, accepted, inProgress, completed, cancelled }

class ServiceOrder {
  final String id;
  final ServiceHubKind category;
  final String serviceName;
  final String providerName;
  final String variant;
  final String address;
  final String notes;
  final DateTime date;
  final double price;
  final OrderStatus status;
  final DateTime createdAt;

  ServiceOrder({
    required this.id,
    required this.category,
    required this.serviceName,
    this.providerName = "Usta",
    this.variant = '',
    this.address = '',
    this.notes = '',
    required this.date,
    required this.price,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Eski kod `serviceIcon` (string) ishlatardi — `category.icon` mos keladi.
  /// Lekin moslashish uchun string nomi ham qaytaramiz.
  String get serviceIconKey => switch (category) {
        ServiceHubKind.sartarosh => 'scissors',
        ServiceHubKind.elektrik => 'zap',
        ServiceHubKind.santexnik => 'droplet',
        _ => category.name,
      };

  ServiceOrder copyWith({OrderStatus? status}) => ServiceOrder(
        id: id,
        category: category,
        serviceName: serviceName,
        providerName: providerName,
        variant: variant,
        address: address,
        notes: notes,
        date: date,
        price: price,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    OrderStatus status = OrderStatus.pending;
    switch (json['status']) {
      case 'pending':
        status = OrderStatus.pending;
        break;
      case 'confirmed':
        status = OrderStatus.accepted;
        break;
      case 'in_progress':
        status = OrderStatus.inProgress;
        break;
      case 'completed':
        status = OrderStatus.completed;
        break;
      case 'cancelled':
        status = OrderStatus.cancelled;
        break;
    }

    final categoryKey = json['category_key'] ?? '';
    final category = ServiceHubKind.values.firstWhere(
      (e) => e.name == categoryKey,
      orElse: () {
        final catId = json['category_id'] as int?;
        if (catId != null && catId > 0 && catId <= ServiceHubKind.values.length) {
          return ServiceHubKind.values[catId - 1];
        }
        return ServiceHubKind.yana;
      },
    );

    return ServiceOrder(
      id: json['id']?.toString() ?? '',
      category: category,
      serviceName: json['service_name'] ?? '',
      providerName: json['provider_name'] ?? 'Usta',
      variant: json['variant_label'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: status,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr = 'pending';
    switch (status) {
      case OrderStatus.pending:
        statusStr = 'pending';
        break;
      case OrderStatus.accepted:
        statusStr = 'confirmed';
        break;
      case OrderStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case OrderStatus.completed:
        statusStr = 'completed';
        break;
      case OrderStatus.cancelled:
        statusStr = 'cancelled';
        break;
    }
    return {
      'id': id,
      'category_key': category.name,
      'service_name': serviceName,
      'provider_name': providerName,
      'address': address,
      'notes': notes,
      'date': date.toIso8601String(),
      'price': price,
      'status': statusStr,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<ServiceOrder> demoOrders = [
    ServiceOrder(
      id: "1",
      category: ServiceHubKind.sartarosh,
      serviceName: "Sartarosh xizmati",
      providerName: "Barber Pro",
      variant: 'Erkaklar kesimi',
      address: 'Toshkent, Amir Temur ko‘chasi 15',
      date: DateTime.now().subtract(const Duration(days: 1)),
      price: 50000,
      status: OrderStatus.completed,
    ),
    ServiceOrder(
      id: "2",
      category: ServiceHubKind.elektrik,
      serviceName: "Elektrik xizmati",
      providerName: "Elektrik servis",
      variant: 'Rozetka/lyustra montaj',
      address: 'Toshkent, Chilonzor 5-mavze',
      date: DateTime.now(),
      price: 120000,
      status: OrderStatus.inProgress,
    ),
    ServiceOrder(
      id: "3",
      category: ServiceHubKind.santexnik,
      serviceName: "Santexnik xizmati",
      providerName: "Suv oqimi",
      variant: 'Smesitel almashtirish',
      address: 'Toshkent, Yunusobod 14',
      date: DateTime.now().add(const Duration(days: 2)),
      price: 80000,
      status: OrderStatus.pending,
    ),
  ];

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return "Kutilmoqda";
      case OrderStatus.accepted:
        return "Qabul qilindi";
      case OrderStatus.inProgress:
        return "Jarayonda";
      case OrderStatus.completed:
        return "Yakunlandi";
      case OrderStatus.cancelled:
        return "Bekor qilindi";
    }
  }
}
