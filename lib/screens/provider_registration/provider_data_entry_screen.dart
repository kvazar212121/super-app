import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'provider_success_screen.dart';

class ProviderDataEntryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int? categoryDbId; // Backend database ID

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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
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

  // Backend API
  static const _baseUrl = 'http://10.0.2.2:8000/api/v1';

  Future<void> _submitProvider() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.categoryDbId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xatolik: Kategoriya topilmadi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/providers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category_id': widget.categoryDbId,
          'name': _nameCtrl.text,
          'address': _addressCtrl.text,
          'phone': _phoneCtrl.text,
          'lat': 41.2995,
          'lng': 69.2401,
          'metadata_json': {
            'hours': _hoursCtrl.text,
            'price': _priceCtrl.text,
            'extra': _extraCtrl.text,
            'category_key': widget.categoryId,
          },
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderSuccessScreen(
              providerName: _nameCtrl.text,
              categoryName: widget.categoryName,
              categoryId: widget.categoryId,
            ),
          ),
          (route) => false,
        );
      } else {
        final error = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: ${error['detail'] ?? 'Noma\'lum xatolik'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarmoq xatosi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} sifatida ro\'yxatdan o\'tish'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Malumotlaringizni to\'ldiring',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

                    // Category specific fields
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
            ),
    );
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Iltimos, ushbu maydonni to\'ldiring';
        }
        return null;
      },
    );
  }
}
