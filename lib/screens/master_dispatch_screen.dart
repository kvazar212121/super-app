import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class MasterDispatchScreen extends StatefulWidget {
  final Master master;

  const MasterDispatchScreen({super.key, required this.master});

  @override
  State<MasterDispatchScreen> createState() => _MasterDispatchScreenState();
}

class _MasterDispatchScreenState extends State<MasterDispatchScreen> {
  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 0));
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00"
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMasterHeader(),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmat turi"),
                  const SizedBox(height: 12),
                  _buildServicesList(currencyFormat),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    accentColor: const Color(0xFF0F172A),
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    daysCount: 14,
                    startDaysOffset: 1,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Vaqt"),
                  const SizedBox(height: 12),
                  TimeSlotGrid(
                    timeSlots: _timeSlots,
                    selectedTimeSlot: _selectedTimeSlot,
                    accentColor: const Color(0xFF0F172A),
                    onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                    crossAxisCount: 5,
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF334155)],
            ),
          ),
          child: Center(
            child: Icon(
              LucideIcons.wrench,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasterHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.blue[50],
          child: const Icon(LucideIcons.user, size: 30, color: Color(0xFF0F172A)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.master.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.master.specialty,
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    "${widget.master.rating} (${widget.master.reviewCount} ta fikr)",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(NumberFormat format) {
    return Column(
      children: widget.master.services.map((service) {
        final isSelected = _selectedService == service;
        return GestureDetector(
          onTap: () => setState(() => _selectedService = service),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(service, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  format.format(widget.master.prices[service]),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    final bool canCall = _selectedService != null && _selectedTimeSlot != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canCall ? _confirmDispatch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Ustani chaqirish", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${widget.master.phoneNumber} raqamiga bog'lanilmoqda...")),
              );
            },
            icon: const Icon(LucideIcons.phone),
            label: const Text("To'g'ridan-to'g'ri bog'lanish"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFF0F172A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chaqiruvni tasdiqlang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DetailRow(label: "Usta", value: widget.master.name),
            DetailRow(label: "Sohasi", value: widget.master.specialty),
            DetailRow(label: "Xizmat", value: _selectedService!),
            DetailRow(label: "Vaqt", value: "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 9;
                  final minute = int.tryParse(_selectedTimeSlot!.split(':')[1]) ?? 0;
                  final dateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                    minute,
                  );

                  ServiceHubKind category = ServiceHubKind.usta;
                  final specialty = widget.master.specialty.toLowerCase();
                  if (specialty.contains('elek')) {
                    category = ServiceHubKind.elektrik;
                  } else if (specialty.contains('sant')) {
                    category = ServiceHubKind.santexnik;
                  } else if (specialty.contains('toza')) {
                    category = ServiceHubKind.tozalash;
                  } else if (specialty.contains('avto')) {
                    category = ServiceHubKind.avtoYordam;
                  } else if (specialty.contains('kond')) {
                    category = ServiceHubKind.konditsioner;
                  } else if (specialty.contains('enag')) {
                    category = ServiceHubKind.enaga;
                  } else if (specialty.contains('repa') || specialty.contains('repet')) {
                    category = ServiceHubKind.repetitor;
                  }

                  final price = widget.master.prices[_selectedService] ?? 50000.0;

                  final order = ServiceOrder(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    category: category,
                    serviceName: '${widget.master.name} — $_selectedService',
                    providerName: widget.master.name,
                    variant: _selectedService!,
                    address: 'Mijoz manzili',
                    notes: 'Mutaxassis: ${widget.master.name} (${widget.master.specialty})',
                    date: dateTime,
                    price: price,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Go back to hub
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Usta chaqirildi! Tez orada bog'lanadi."), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Tasdiqlash va Chaqirish", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
