import 'package:flutter/material.dart';

import '../../models/alarm.dart';
import '../../services/api_service.dart';
import '../../services/notification_helper.dart';
import 'alarm_edit_screen.dart';
import 'alarm_ring_screen.dart';

/// Majburlovchi budilnik — budilniklar ro'yxati.
class AlarmHomeScreen extends StatefulWidget {
  const AlarmHomeScreen({super.key});

  @override
  State<AlarmHomeScreen> createState() => _AlarmHomeScreenState();
}

class _AlarmHomeScreenState extends State<AlarmHomeScreen> {
  final _api = ApiService();
  List<Alarm> _alarms = [];
  bool _loading = true;
  String? _error;

  static const List<String> _weekdayLabels = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const Map<String, String> _missionLabels = {
    'math': 'Misol yechish',
    'photo': 'Rasmga olish',
    'speech': 'Matnni o\'qish',
  };
  static const Map<String, IconData> _missionIcons = {
    'math': Icons.calculate,
    'photo': Icons.camera_alt,
    'speech': Icons.mic,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getAlarms();
      final alarms = data.map((e) => Alarm.fromJson(e as Map<String, dynamic>)).toList();
      // Serverdagi budilniklarni lokal ravishda qayta rejalashtiramiz
      for (final a in alarms) {
        await NotificationHelper().scheduleAlarm(a);
      }
      setState(() {
        _alarms = alarms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Yuklashda xatolik. Internetni tekshiring.';
        _loading = false;
      });
    }
  }

  Future<void> _addOrEdit([Alarm? existing]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AlarmEditScreen(existing: existing)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggle(Alarm alarm) async {
    try {
      final res = await _api.toggleAlarm(alarm.id);
      final updated = Alarm.fromJson(res);
      if (updated.isEnabled) {
        await NotificationHelper().scheduleAlarm(updated);
      } else {
        await NotificationHelper().cancelAlarm(updated.id);
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O\'zgartirishda xatolik')),
        );
      }
    }
  }

  Future<void> _delete(Alarm alarm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('O\'chirish'),
        content: Text('"${alarm.label}" budilnigini o\'chirasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yo\'q')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ha')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteAlarm(alarm.id);
      await NotificationHelper().cancelAlarm(alarm.id);
      _load();
    } catch (_) {}
  }

  void _preview(Alarm alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AlarmRingScreen(alarm: alarm)),
    );
  }

  String _subtitle(Alarm alarm) {
    final days = alarm.isOneTime
        ? 'Bir martalik'
        : (alarm.repeatDayList..sort()).map((d) => _weekdayLabels[d - 1]).join(', ');
    final mission = _missionLabels[alarm.missionType] ?? alarm.missionType;
    return '$days • $mission';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Majburlovchi budilnik')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Yangi'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_error!)),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(onPressed: _load, child: const Text('Qayta urinish')),
          ),
        ],
      );
    }
    if (_alarms.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 140),
          Icon(Icons.alarm_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('Hali budilnik yo\'q.\n"Yangi" tugmasi orqali qo\'shing.', textAlign: TextAlign.center)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: _alarms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = _alarms[i];
        return Card(
          child: ListTile(
            onTap: () => _addOrEdit(a),
            leading: Icon(_missionIcons[a.missionType] ?? Icons.alarm, color: Colors.tealAccent),
            title: Row(
              children: [
                Text(
                  a.timeLabel,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: a.isEnabled ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(a.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
            subtitle: Text(_subtitle(a)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  tooltip: 'Sinab ko\'rish',
                  onPressed: () => _preview(a),
                ),
                Switch(value: a.isEnabled, onChanged: (_) => _toggle(a)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(a),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
