import sys
import glob

files_to_patch = [
    'lib/screens/provider_side/widgets/provider_master_settings_widget.dart',
    'lib/screens/provider_side/widgets/provider_electrician_settings_widget.dart',
    'lib/screens/provider_side/widgets/provider_plumber_settings_widget.dart',
    'lib/screens/provider_side/widgets/provider_ac_settings_widget.dart',
]

for file in files_to_patch:
    with open(file, 'r') as f:
        content = f.read()
    
    if "final _serviceAreaCtrl" not in content:
        # Add controller definition
        old_load = "  bool _loading = true;"
        new_load = "  final _serviceAreaCtrl = TextEditingController();\n  bool _loading = true;"
        content = content.replace(old_load, new_load)
        
        # Add controller dispose
        old_dispose = "    super.dispose();\n  }"
        new_dispose = "    _serviceAreaCtrl.dispose();\n    super.dispose();\n  }"
        content = content.replace(old_dispose, new_dispose)
        
        # Add loading service area
        old_apply = "void _applyMeta(Map<String, dynamic> meta) {"
        new_apply = "void _applyMeta(Map<String, dynamic> meta) {\n    _serviceAreaCtrl.text = meta['service_area']?.toString() ?? '';"
        content = content.replace(old_apply, new_apply)
        
        # Add saving service area
        old_save = "..['time_slots'] = _timeSlots;"
        new_save = "..['time_slots'] = _timeSlots\n        ..['service_area'] = _serviceAreaCtrl.text.trim();"
        content = content.replace(old_save, new_save)
        
        # Add UI element
        old_ui = "        Text(\n          'Ish vaqtlari',"
        new_ui = """        const Text('Xizmat ko\\'rsatish hududi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _serviceAreaCtrl,
          decoration: const InputDecoration(
            hintText: 'Masalan: Toshkent shahri, Chilonzor tumani',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ish vaqtlari',"""
        content = content.replace(old_ui, new_ui)
        
        with open(file, 'w') as f:
            f.write(content)
        print(f"Patched {file}")

