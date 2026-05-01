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
