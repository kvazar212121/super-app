import sys

with open('lib/services/api_service.dart', 'r') as f:
    content = f.read()

old_func_def = """  Future<void> createManualOrderAfterCall({
    required int userId,
    required String serviceName,
    required String date,
    required double price,
    int? staffProviderId,
  }) async {"""

new_func_def = """  Future<void> createManualOrderAfterCall({
    required int userId,
    required String serviceName,
    required String date,
    required double price,
    int? staffProviderId,
    String? address,
  }) async {"""

content = content.replace(old_func_def, new_func_def)

old_body = """      final data = {
        'user_id': userId,
        'service_name': serviceName,
        'date': date,
        'price': price,
        if (staffProviderId != null) 'staff_provider_id': staffProviderId,
      };"""

new_body = """      final data = {
        'user_id': userId,
        'service_name': serviceName,
        'date': date,
        'price': price,
        if (staffProviderId != null) 'staff_provider_id': staffProviderId,
        if (address != null && address.isNotEmpty) 'address': address,
      };"""

content = content.replace(old_body, new_body)

with open('lib/services/api_service.dart', 'w') as f:
    f.write(content)

print("api_service.dart patched with address")
