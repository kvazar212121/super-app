import sys

with open('lib/services/api_service.dart', 'r') as f:
    content = f.read()

# 1. Update createManualOrderAfterCall
old_create = """  Future<void> createManualOrderAfterCall({
    required int userId,
    required String serviceName,
    required String date,
    required double price,
  }) async {"""

new_create = """  Future<void> createManualOrderAfterCall({
    required int userId,
    required String serviceName,
    required String date,
    required double price,
    int? staffProviderId,
  }) async {"""

content = content.replace(old_create, new_create)

old_data = """    final response = await _dio.post('/provider/orders/manual_after_call', data: {
      'user_id': userId,
      'service_name': serviceName,
      'date': date,
      'price': price,
      'notes': 'Telefon orqali kelishildi'
    });"""

new_data = """    final response = await _dio.post('/provider/orders/manual_after_call', data: {
      'user_id': userId,
      'service_name': serviceName,
      'date': date,
      'price': price,
      'notes': 'Telefon orqali kelishildi',
      if (staffProviderId != null) 'staff_provider_id': staffProviderId,
    });"""

content = content.replace(old_data, new_data)

# 2. Add getMyStaff
new_staff_method = """
  Future<List<Map<String, dynamic>>> getMyStaff() async {
    final response = await _dio.get('/provider/my-staff');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null && data['staff'] != null) {
        return List<Map<String, dynamic>>.from(data['staff']);
      }
    }
    return [];
  }
"""

if "getMyStaff" not in content:
    idx = content.rfind('}')
    content = content[:idx] + new_staff_method + content[idx:]

with open('lib/services/api_service.dart', 'w') as f:
    f.write(content)

print("api_service.dart patched for staff selection")
