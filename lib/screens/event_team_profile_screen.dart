import 'package:flutter/material.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import '../widgets/event_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../utils/call_helper.dart';

class EventTeamProfileScreen extends StatefulWidget {
  final EventPlanning team;

  const EventTeamProfileScreen({super.key, required this.team});

  @override
  State<EventTeamProfileScreen> createState() => _EventTeamProfileScreenState();
}

class _EventTeamProfileScreenState extends State<EventTeamProfileScreen> {
  EventPlanning get team => widget.team;
  Color get _accent => ServiceHubKind.tadbirlar.accent;

  void _startCall() {
    CallHelper.startCallWithPurposeCheck(
      context,
      team.providerId > 0 ? team.providerId : 1, // Fallback for demo
      team.name,
      categoryKey: ServiceHubKind.tadbirlar.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(team.name),
          backgroundColor: Colors.transparent,
          foregroundColor: _accent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            EventTeamVisualWidget(team: team, accent: _accent),
            const SizedBox(height: 20),
            EventTeamInfoCard(team: team),
            const SizedBox(height: 20),
            const _SectionTitle('Xizmatlar va narxlar', Icons.monetization_on_outlined),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: team.prices.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                        Text(
                          '${(e.value / 1000).toStringAsFixed(0)} ming soʻm',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _startCall,
                icon: const Icon(Icons.phone_in_talk, size: 22),
                label: const Text(
                  'Jamoa bilan bog\'lanish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
