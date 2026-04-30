import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = ["Sartarosh", "Elektrik", "Usta"];

  final List<Map<String, dynamic>> _services = [
    {"name": "Sartarosh", "icon": LucideIcons.scissors, "color": Colors.blue},
    {"name": "Salon", "icon": LucideIcons.sparkles, "color": Colors.pink},
    {"name": "Futbol", "icon": LucideIcons.trophy, "color": Colors.green},
    {"name": "Ishchi", "icon": LucideIcons.users, "color": Colors.orange},
    {"name": "Usta", "icon": LucideIcons.wrench, "color": Colors.teal},
    {"name": "Elektrik", "icon": LucideIcons.zap, "color": Colors.yellow},
    {"name": "Santexnik", "icon": LucideIcons.droplet, "color": Colors.lightBlue},
    {"name": "Oshpaz", "icon": LucideIcons.utensils, "color": Colors.brown},
    {"name": "Haydovchi", "icon": LucideIcons.car, "color": Colors.indigo},
    {"name": "Tarjimon", "icon": LucideIcons.languages, "color": Colors.purple},
  ];

  List<Map<String, dynamic>> get _filteredServices {
    if (_controller.text.isEmpty) return [];
    return _services
        .where((s) => s["name"]
            .toString()
            .toLowerCase()
            .contains(_controller.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qidiruv"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Xizmatlarni qidirish...",
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_controller.text.isEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("So'nggi qidiruvlar",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _recentSearches.clear()),
                    child: const Text("Tozalash"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map((s) => Chip(
                          label: Text(s),
                          deleteIcon: const Icon(LucideIcons.x, size: 18),
                          onDeleted: () =>
                              setState(() => _recentSearches.remove(s)),
                        ))
                    .toList(),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredServices.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _filteredServices[i]["color"].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_filteredServices[i]["icon"],
                          color: _filteredServices[i]["color"]),
                    ),
                    title: Text(_filteredServices[i]["name"]),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {},
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
