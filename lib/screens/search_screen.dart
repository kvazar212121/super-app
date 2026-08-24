import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/search_input_widget.dart';
import '../widgets/recent_searches_widget.dart';
import '../widgets/search_results_widget.dart';
import '../widgets/glass/glass_scaffold.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final List<String> _recentSearches = [];

  // Debounce: har harfda emas, foydalanuvchi to'xtaganda qidiramiz.
  // Bu ilova sekin internetda ham silliq ishlashi uchun juda muhim.
  Timer? _debounce;
  String _debouncedQuery = '';

  void _onChanged() {
    // Bo'sh matn — darhol yangilaymiz (recent'ni ko'rsatish uchun).
    if (_controller.text.isEmpty) {
      _debounce?.cancel();
      setState(() => _debouncedQuery = '');
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      embeddedInShell: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        child: Column(
          children: [
            SearchInputWidget(
              controller: _controller,
              onChanged: _onChanged,
              onClear: () {
                _controller.clear();
                _debounce?.cancel();
                setState(() => _debouncedQuery = '');
              },
            ),
            const SizedBox(height: 20),
            if (_debouncedQuery.isEmpty) ...[
              RecentSearchesWidget(
                searches: _recentSearches,
                onClear: () => setState(() => _recentSearches.clear()),
                onRemove: (s) => setState(() => _recentSearches.remove(s)),
              ),
              const SizedBox(height: 20),
              const Expanded(child: SearchResultsWidget(query: '')),
            ] else
              Expanded(child: SearchResultsWidget(query: _debouncedQuery)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
