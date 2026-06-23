import sys

with open('lib/screens/calls/post_call_dialogs.dart', 'r') as f:
    content = f.read()

# Add addressController to _showProviderQuickForm
old_vars = """    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String serviceName = 'Xizmat';
    double price = 50000;
    int? selectedStaffId;"""

new_vars = """    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String serviceName = 'Xizmat';
    double price = 50000;
    int? selectedStaffId;
    TextEditingController addressController = TextEditingController();"""

content = content.replace(old_vars, new_vars)

# Add TextField to UI
old_textfield = """                  TextField(
                    decoration: const InputDecoration(labelText: 'Xizmat narxi (so\\'m)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      price = double.tryParse(val) ?? 50000;
                    },
                  ),"""

new_textfield = """                  TextField(
                    decoration: const InputDecoration(labelText: 'Xizmat narxi (so\\'m)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      price = double.tryParse(val) ?? 50000;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Manzil / Izoh (ixtiyoriy)',
                      hintText: 'Mijoz uyi, mo\\'ljal...',
                    ),
                    maxLines: 2,
                  ),"""

content = content.replace(old_textfield, new_textfield)

# Update submit call
old_submit_call = """                  _submitManualOrder(context, app, clientId, dt, serviceName, price, selectedStaffId);"""
new_submit_call = """                  _submitManualOrder(context, app, clientId, dt, serviceName, price, selectedStaffId, addressController.text);"""

content = content.replace(old_submit_call, new_submit_call)

# Update _submitManualOrder definition
old_submit_def = """  static Future<void> _submitManualOrder(
    BuildContext context, AppProvider app, int userId, DateTime date, String serviceName, double price, int? staffProviderId
  ) async {"""
new_submit_def = """  static Future<void> _submitManualOrder(
    BuildContext context, AppProvider app, int userId, DateTime date, String serviceName, double price, int? staffProviderId, String address
  ) async {"""

content = content.replace(old_submit_def, new_submit_def)

# Update API call
old_api = """      await app.api.createManualOrderAfterCall(
        userId: userId,
        serviceName: serviceName,
        date: date.toIso8601String(),
        price: price,
        staffProviderId: staffProviderId,
      );"""

new_api = """      await app.api.createManualOrderAfterCall(
        userId: userId,
        serviceName: serviceName,
        date: date.toIso8601String(),
        price: price,
        staffProviderId: staffProviderId,
        address: address,
      );"""

content = content.replace(old_api, new_api)

with open('lib/screens/calls/post_call_dialogs.dart', 'w') as f:
    f.write(content)

print("Quick form patched with address")
