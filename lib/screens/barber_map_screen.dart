import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/barber_shop.dart';

class BarberMapScreen extends StatelessWidget {
  final List<BarberShop> shops;

  const BarberMapScreen({super.key, required this.shops});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yaqin atrofdagi sartaroshlar"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(41.3115, 69.2495),
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.super_app',
          ),
          MarkerLayer(
            markers: shops.map((shop) {
              return Marker(
                width: 80,
                height: 80,
                point: LatLng(shop.latitude, shop.longitude),
                child: GestureDetector(
                  onTap: () => _showShopDetails(context, shop),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.cut,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shop.name,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showShopDetails(BuildContext context, BarberShop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.cut, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(" ${shop.rating} (${shop.reviewCount} ta sharh)"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.location_on, shop.address),
              const Divider(height: 32),
              const Text("Xizmatlar va narxlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...shop.services.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(service),
                    Text(
                      "${shop.prices[service]!.toStringAsFixed(0)} so'm",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _bookService(context, shop),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Band qilish"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  void _bookService(BuildContext context, BarberShop shop) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Xizmatni tanlang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...shop.services.map((service) => ListTile(
              title: Text(service),
              subtitle: Text("${shop.prices[service]!.toStringAsFixed(0)} so'm"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDateTime(context, shop, service),
            )),
          ],
        ),
      ),
    );
  }

  void _selectDateTime(BuildContext context, BarberShop shop, String service) {
    Navigator.pop(context);
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.now().replacing(hour: 10),
        ).then((time) {
          if (time != null) {
            final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            _confirmBooking(context, shop, service, dateTime);
          }
        });
      }
    });
  }

  void _confirmBooking(BuildContext context, BarberShop shop, String service, DateTime dateTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buyurtmani tasdiqlash"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sartarosh: ${shop.name}"),
            Text("Xizmat: $service"),
            Text("Narx: ${shop.prices[service]!.toStringAsFixed(0)} so'm"),
            Text("Sana: ${dateTime.day}.${dateTime.month}.${dateTime.year}"),
            Text("Vaqt: ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$service uchun band qilish muvaffaqiyatli amalga oshirildi!")),
              );
            },
            child: const Text("Tasdiqlash"),
          ),
        ],
      ),
    );
  }
}
