import 'service_hub_kind.dart';

enum OrderStatus {
  pending,
  accepted,
  onTheWay,
  arrived,
  preparing,
  inProgress,
  delivered,
  completed,
  awaitingConfirmation,
  cancelled,
  noShow,
  disputed,
}

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
  final int? providerId;
  /// 'fixed' = aniq vaqt, 'flexible' = tezkor navbat (oldinga surilishi mumkin)
  final String bookingMode;

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
    this.providerId,
    this.bookingMode = 'fixed',
  }) : createdAt = createdAt ?? DateTime.now();

  /// Eski kod `serviceIcon` (string) ishlatardi — `category.icon` mos keladi.
  /// Lekin moslashish uchun string nomi ham qaytaramiz.
  String get serviceIconKey => switch (category) {
        ServiceHubKind.sartarosh => 'scissors',
        ServiceHubKind.elektrik => 'zap',
        ServiceHubKind.santexnik => 'droplet',
        _ => category.name,
      };

  ServiceOrder copyWith({OrderStatus? status, String? bookingMode}) => ServiceOrder(
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
        providerId: providerId,
        bookingMode: bookingMode ?? this.bookingMode,
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
      case 'on_the_way':
        status = OrderStatus.onTheWay;
        break;
      case 'arrived':
        status = OrderStatus.arrived;
        break;
      case 'preparing':
        status = OrderStatus.preparing;
        break;
      case 'in_progress':
        status = OrderStatus.inProgress;
        break;
      case 'delivered':
        status = OrderStatus.delivered;
        break;
      case 'completed':
        status = OrderStatus.completed;
        break;
      case 'awaiting_confirmation':
        status = OrderStatus.awaitingConfirmation;
        break;
      case 'cancelled':
        status = OrderStatus.cancelled;
        break;
      case 'no_show':
        status = OrderStatus.noShow;
        break;
      case 'disputed':
        status = OrderStatus.disputed;
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
      providerId: json['provider_id'] as int?,
      bookingMode: json['booking_mode'] as String? ?? 'fixed',
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
      case OrderStatus.onTheWay:
        statusStr = 'on_the_way';
        break;
      case OrderStatus.arrived:
        statusStr = 'arrived';
        break;
      case OrderStatus.preparing:
        statusStr = 'preparing';
        break;
      case OrderStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case OrderStatus.delivered:
        statusStr = 'delivered';
        break;
      case OrderStatus.completed:
        statusStr = 'completed';
        break;
      case OrderStatus.awaitingConfirmation:
        statusStr = 'awaiting_confirmation';
        break;
      case OrderStatus.cancelled:
        statusStr = 'cancelled';
        break;
      case OrderStatus.noShow:
        statusStr = 'no_show';
        break;
      case OrderStatus.disputed:
        statusStr = 'disputed';
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
      'booking_mode': bookingMode,
    };
  }


  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return "Kutilmoqda";
      case OrderStatus.accepted:
        return "Qabul qilindi";
      case OrderStatus.onTheWay:
        return "Yo'lda";
      case OrderStatus.arrived:
        return "Yetib keldi";
      case OrderStatus.preparing:
        return "Tayyorlanmoqda";
      case OrderStatus.inProgress:
        return "Jarayonda";
      case OrderStatus.delivered:
        return "Yetkazildi";
      case OrderStatus.completed:
        return "Yakunlandi";
      case OrderStatus.awaitingConfirmation:
        return "Tasdiq kutilmoqda";
      case OrderStatus.cancelled:
        return "Bekor qilindi";
      case OrderStatus.noShow:
        return "Kelmadi";
      case OrderStatus.disputed:
        return "Nizoli";
    }
  }
}
