import sys

with open('lib/screens/calls/post_call_dialogs.dart', 'r') as f:
    content = f.read()

# Modify _showProviderDialog to fetch staff first
old_show = """  static void _showProviderDialog(BuildContext context, int clientId, String clientName, AppProvider app) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog("""

new_show = """  static void _showProviderDialog(BuildContext context, int clientId, String clientName, AppProvider app) async {
    // Check if we have staff (e.g. salon)
    List<Map<String, dynamic>> staffList = [];
    try {
      staffList = await app.api.getMyStaff();
    } catch (e) {
      debugPrint('Error fetching staff: $e');
    }
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog("""

content = content.replace(old_show, new_show)

# Pass staffList to _showProviderQuickForm
old_btn = """          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showProviderQuickForm(context, clientId, clientName, app);
            },"""

new_btn = """          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showProviderQuickForm(context, clientId, clientName, app, staffList);
            },"""

content = content.replace(old_btn, new_btn)

old_form_def = """  static void _showProviderQuickForm(BuildContext context, int clientId, String clientName, AppProvider app) {"""
new_form_def = """  static void _showProviderQuickForm(BuildContext context, int clientId, String clientName, AppProvider app, List<Map<String, dynamic>> staffList) {"""

content = content.replace(old_form_def, new_form_def)

# Add dropdown and selectedStaffId to _showProviderQuickForm
old_vars = """    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String serviceName = 'Xizmat';
    double price = 50000;"""

new_vars = """    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String serviceName = 'Xizmat';
    double price = 50000;
    int? selectedStaffId;
    if (staffList.isNotEmpty) {
      selectedStaffId = staffList.first['id'] as int?;
    }"""

content = content.replace(old_vars, new_vars)

old_column = """                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile("""

new_column = """                mainAxisSize: MainAxisSize.min,
                children: [
                  if (staffList.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedStaffId,
                      decoration: const InputDecoration(labelText: 'Mutaxassis (Usta)'),
                      items: staffList.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'] as int?,
                          child: Text(s['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedStaffId = v),
                    ),
                  ListTile("""

content = content.replace(old_column, new_column)

# Update _submitManualOrder call
old_submit = """                  Navigator.pop(ctx);
                  _submitManualOrder(context, app, clientId, dt, serviceName, price);"""

new_submit = """                  Navigator.pop(ctx);
                  _submitManualOrder(context, app, clientId, dt, serviceName, price, selectedStaffId);"""

content = content.replace(old_submit, new_submit)

old_submit_def = """  static Future<void> _submitManualOrder(
    BuildContext context, AppProvider app, int userId, DateTime date, String serviceName, double price
  ) async {"""

new_submit_def = """  static Future<void> _submitManualOrder(
    BuildContext context, AppProvider app, int userId, DateTime date, String serviceName, double price, int? staffProviderId
  ) async {"""

content = content.replace(old_submit_def, new_submit_def)

old_api_call = """      await app.api.createManualOrderAfterCall(
        userId: userId,
        serviceName: serviceName,
        date: date.toIso8601String(),
        price: price,
      );"""

new_api_call = """      await app.api.createManualOrderAfterCall(
        userId: userId,
        serviceName: serviceName,
        date: date.toIso8601String(),
        price: price,
        staffProviderId: staffProviderId,
      );"""

content = content.replace(old_api_call, new_api_call)

with open('lib/screens/calls/post_call_dialogs.dart', 'w') as f:
    f.write(content)

print("post_call_dialogs.dart patched for staff dropdown")
