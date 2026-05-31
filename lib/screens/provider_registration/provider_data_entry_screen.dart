import 'package:flutter/material.dart';
import '../provider_side/provider_theme.dart';
import 'provider_success_screen.dart';

class ProviderDataEntryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int? categoryDbId; // Backend database ID (offline rejimda ishlatilmaydi)

  const ProviderDataEntryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryDbId,
  });

  @override
  State<ProviderDataEntryScreen> createState() => _ProviderDataEntryScreenState();
}

class _ProviderDataEntryScreenState extends State<ProviderDataEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _priceCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  void _submitProvider() {
    // Demo rejimi: maydonlar ixtiyoriy, to'ldirmasdan ham davom etish mumkin.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderSuccessScreen(
          providerName: _nameCtrl.text.trim(),
          categoryName: widget.categoryName,
          categoryId: widget.categoryId,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(child: Builder(builder: (context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} sifatida ro\'yxatdan o\'tish'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Malumotlaringizni to\'ldiring',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Maydonlar ixtiyoriy — keyinroq to\'ldirsangiz ham bo\'ladi.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameCtrl, 'Ish joyi nomi / Ismingiz', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_addressCtrl, 'Manzil', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField(_phoneCtrl, 'Telefon raqam', Icons.phone, type: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_hoursCtrl, 'Ish vaqti (Masalan: 09:00 - 18:00)', Icons.access_time),
            const SizedBox(height: 16),
            if (widget.categoryId == 'barber' || widget.categoryId == 'salon')
              _buildTextField(_priceCtrl, 'Xizmat narxi (min)', Icons.payments_outlined, type: TextInputType.number),
            if (widget.categoryId == 'tutor')
              _buildTextField(_extraCtrl, 'Fan nomi', Icons.book_outlined),
            if (widget.categoryId == 'futbol')
              _buildTextField(_extraCtrl, 'Maydonlar soni', Icons.sports_soccer, type: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitProvider,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Ro\'yxatdan o\'tish'),
              ),
            ),
          ],
        ),
      ),
    );
    }));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
