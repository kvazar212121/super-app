enum OrderStatus { pending, accepted, inProgress, completed, cancelled }

class ServiceOrder {
  final String id;
  final String serviceName;
  final String providerName;
  final String serviceIcon;
  final DateTime date;
  final double price;
  final OrderStatus status;

  ServiceOrder({
    required this.id,
    required this.serviceName,
    this.providerName = "Usta",
    required this.serviceIcon,
    required this.date,
    required this.price,
    required this.status,
  });

  static List<ServiceOrder> demoOrders = [
    ServiceOrder(
      id: "1",
      serviceName: "Sartarosh xizmati",
      providerName: "Barber Pro",
      serviceIcon: "scissors",
      date: DateTime.now().subtract(const Duration(days: 1)),
      price: 50000,
      status: OrderStatus.completed,
    ),
    ServiceOrder(
      id: "2",
      serviceName: "Elektrik xizmati",
      providerName: "Elektrik servis",
      serviceIcon: "zap",
      date: DateTime.now(),
      price: 120000,
      status: OrderStatus.inProgress,
    ),
    ServiceOrder(
      id: "3",
      serviceName: "Santexnik xizmati",
      providerName: "Suv oqimi",
      serviceIcon: "droplet",
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
