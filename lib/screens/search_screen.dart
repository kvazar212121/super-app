import 'package:flutter/material.dart';
import '../widgets/search_input_widget.dart';
import '../widgets/recent_searches_widget.dart';
import '../widgets/search_results_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final List<String> _recentSearches = ["Sartarosh", "Elektrik", "Usta"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Qidiruv"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchInputWidget(
              controller: _controller,
              onChanged: () => setState(() {}),
              onClear: () {
                _controller.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            if (_controller.text.isEmpty) ...[
              RecentSearchesWidget(
                searches: _recentSearches,
                onClear: () => setState(() => _recentSearches.clear()),
                onRemove: (s) => setState(() => _recentSearches.remove(s)),
              ),
              const SizedBox(height: 20),
              Expanded(child: SearchResultsWidget(query: "")),
            ] else
              Expanded(child: SearchResultsWidget(query: _controller.text)),
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
