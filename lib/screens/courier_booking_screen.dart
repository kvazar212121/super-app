import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/courier_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/booking_common_widgets.dart';

class CourierBookingScreen extends StatefulWidget {
  final CourierService service;

  const CourierBookingScreen({super.key, required this.service});

  @override
  State<CourierBookingScreen> createState() => _CourierBookingScreenState();
}

class _CourierBookingScreenState extends State<CourierBookingScreen> {
  DeliveryType? _selectedDeliveryType;
  String? _selectedPriceOption;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isExpress = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF6366F1);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(accentColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceHeader(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Yetkazish turi"),
                  const SizedBox(height: 12),
                  _buildDeliveryTypeGrid(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Qayerdan"),
                  const SizedBox(height: 12),
                  _buildAddressInput(_fromController, "Manzilni kiriting...", LucideIcons.mapPin),
                  const SizedBox(height: 16),
                  const SectionTitle("Qayerga"),
                  const SizedBox(height: 12),
                  _buildAddressInput(_toController, "Yetkazish manzili...", LucideIcons.navigation),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmat turi"),
                  const SizedBox(height: 12),
                  _buildPriceOptionsList(currencyFormat, accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Vazni (kg)"),
                  const SizedBox(height: 12),
                  _buildWeightInput(),
                  const SizedBox(height: 24),
                  _buildExpressToggle(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Vaqt"),
                  const SizedBox(height: 12),
                  TimeSlotGrid(
                    selectedTimeSlot: _selectedTimeSlot,
                    timeSlots: _timeSlots,
                    onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(accentColor, currencyFormat),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color color) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
          child: Center(
            child: Icon(
              LucideIcons.package,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.service.name,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.star, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    widget.service.rating.toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.phone, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              widget.service.phoneNumber,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        if (widget.service.isExpress) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.zap, size: 14, color: const Color(0xFF6366F1)),
                const SizedBox(width: 4),
                Text(
                  "Express xizmat mavjud",
                  style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }



  Widget _buildDeliveryTypeGrid(Color color) {
    final availableTypes = widget.service.deliveryTypes;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: availableTypes.length,
      itemBuilder: (context, index) {
        final type = availableTypes[index];
        final isSelected = _selectedDeliveryType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedDeliveryType = type),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon,
                    color: isSelected ? color : Colors.grey[500], size: 20),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressInput(TextEditingController controller, String hint,
      IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Widget _buildPriceOptionsList(NumberFormat format, Color color) {
    final options = widget.service.prices.keys.toList();
    return Column(
      children: options.map((option) {
        final isSelected = _selectedPriceOption == option;
        return GestureDetector(
          onTap: () => setState(() => _selectedPriceOption = option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(option,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  format.format(widget.service.prices[option]),
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeightInput() {
    return TextField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: "Yuk vaznini kiriting",
        prefixIcon: Icon(LucideIcons.scale, color: Colors.grey[400]),
        suffixText: "kg",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Widget _buildExpressToggle(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isExpress ? color.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpress ? color : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.zap,
              color: _isExpress ? color : Colors.grey[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Express yetkazish",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "Tezkor yetkazib berish (+50% narx)",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _isExpress,
            onChanged: (value) => setState(() => _isExpress = value),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }



  Widget _buildActionButtons(Color color, NumberFormat currencyFormat) {
    final bool canBook = _selectedDeliveryType != null &&
        _fromController.text.isNotEmpty &&
        _toController.text.isNotEmpty &&
        _selectedTimeSlot != null;

    double? totalPrice = 0;
    if (_selectedPriceOption != null) {
      totalPrice = widget.service.prices[_selectedPriceOption];
      if (_isExpress) {
        final expressPrice = widget.service.prices['Express (+50%)'];
        if (expressPrice != null) {
          totalPrice = totalPrice! + expressPrice;
        }
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canBook ? () => _confirmBooking(currencyFormat, totalPrice) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[200],
            ),
            child: Text(
              canBook
                  ? "Buyurtma berish — ${currencyFormat.format(totalPrice)}"
                  : "Buyurtma berish",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "${widget.service.phoneNumber} raqamiga bog'lanilmoqda...")),
              );
            },
            icon: const Icon(LucideIcons.phone),
            label: const Text("Kuryer bilan bog'lanish"),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking(NumberFormat currencyFormat, double? totalPrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Buyurtmani tasdiqlang",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DetailRow(label: "Kuryer", value: widget.service.name),
            DetailRow(label: "Yetkazish turi", value: _selectedDeliveryType!.label),
            DetailRow(label: "Manzil", value: _fromController.text),
            DetailRow(label: "Yetkazish", value: _toController.text),
            DetailRow(label: "Turi", value: _selectedPriceOption!),
            if (_weightController.text.isNotEmpty)
              DetailRow(label: "Vazn", value: "${_weightController.text} kg"),
            if (_isExpress)
              DetailRow(label: "Express", value: "Ha"),
            DetailRow(
                label: "Vaqt",
                value: "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot"),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Narxi:",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(totalPrice),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1)),
                ),
              ],
            ),
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

                  final order = ServiceOrder(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    category: ServiceHubKind.kuryerlik,
                    serviceName: '${widget.service.name} — ${_selectedDeliveryType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: 'Kimdan: ${_fromController.text.trim()} -> Kimga: ${_toController.text.trim()}',
                    notes: 'Vazn: ${_weightController.text.trim()} kg, Tezkor: ${_isExpress ? "Ha" : "Yo‘q"}',
                    date: dateTime,
                    price: totalPrice ?? 15000.0,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Muvaffaqiyatli buyurtma berildi!"),
                        backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Tasdiqlash",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }


}
