import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/daily_models.dart';
import '../services/api_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<TodoItem> _todos = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTodos();
      setState(() {
        _todos = data.map((e) => TodoItem.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Error loading todos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTodo() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    _taskController.clear();

    try {
      final res = await _api.createTodo(title);
      setState(() {
        _todos.insert(0, TodoItem.fromJson(res));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xatolik yuz berdi')));
    }
  }

  Future<void> _toggleTodo(TodoItem item, bool val) async {
    final index = _todos.indexWhere((e) => e.id == item.id);
    if (index == -1) return;

    setState(() {
      _todos[index] = TodoItem(id: item.id, title: item.title, description: item.description, isCompleted: val);
    });

    try {
      await _api.updateTodo(item.id, val);
    } catch (e) {
      // Revert if error
      setState(() {
        _todos[index] = item;
      });
    }
  }

  Future<void> _deleteTodo(String id) async {
    final prev = List<TodoItem>.from(_todos);
    setState(() {
      _todos.removeWhere((e) => e.id == id);
    });
    try {
      await _api.deleteTodo(id);
    } catch (e) {
      setState(() => _todos = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Rejalarim',
      body: Column(
        children: [
          _buildInputArea(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todos.isEmpty
                    ? const Center(child: Text("Hozircha rejalar yo'q"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final item = _todos[index];
                          return _buildTodoCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Yangi vazifa...',
                  hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: GlassTokens.primaryText(context)),
                onSubmitted: (_) => _addTodo(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: Colors.blue),
              onPressed: _addTodo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(TodoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (val) {
            if (val != null) _toggleTodo(item, val);
          },
          activeColor: Colors.blue,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: GlassTokens.primaryText(context),
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
          onPressed: () => _deleteTodo(item.id),
        ),
      ),
    );
  }
}
