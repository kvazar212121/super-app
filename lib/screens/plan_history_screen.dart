import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/daily_models.dart';
import '../services/api_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

class PlanHistoryScreen extends StatefulWidget {
  const PlanHistoryScreen({super.key});

  @override
  State<PlanHistoryScreen> createState() => _PlanHistoryScreenState();
}

class _PlanHistoryScreenState extends State<PlanHistoryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<PlanItem> _pastPlans = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getPlans(); // Fetches all plans
      final allPlans = data.map((e) => PlanItem.fromJson(e)).toList();
      
      // Filter for past plans (due date before today)
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      
      _pastPlans = allPlans.where((p) {
        final planDate = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
        return planDate.isBefore(startOfToday);
      }).toList();

      // Sort by newest first
      _pastPlans.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } catch (e) {
      debugPrint("Error loading plan history: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePlan(int id) async {
    final prev = List<PlanItem>.from(_pastPlans);
    setState(() {
      _pastPlans.removeWhere((e) => e.id == id);
    });
    try {
      await _api.deletePlan(id);
    } catch (e) {
      if (mounted) {
        setState(() => _pastPlans = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("O'chirishda xatolik yuz berdi")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Tarix',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pastPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.history, 
                        size: 48, 
                        color: GlassTokens.secondaryText(context)
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tarix bo'sh",
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _pastPlans.length,
                  itemBuilder: (context, index) {
                    final item = _pastPlans[index];
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.dueDate);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.isCompleted 
                                ? Colors.green
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isCompleted ? LucideIcons.check : LucideIcons.x,
                            color: item.isCompleted ? Colors.green : Colors.redAccent,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: GlassTokens.primaryText(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              color: GlassTokens.secondaryText(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                          onPressed: () => _deletePlan(item.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
