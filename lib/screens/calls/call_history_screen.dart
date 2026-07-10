import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/locale_controller.dart';
import '../../services/call_history_service.dart';
import '../../services/call_service.dart';
import '../../utils/call_helper.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/guest_blocker_widget.dart';
import 'call_screen.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return GlassScaffold(
      showBackButton: true,
      title: "Qo'ng'iroqlar tarixi".tr,
      body: auth.isAuthenticated
          ? ListenableBuilder(
              listenable: CallHistoryService(),
              builder: (context, _) {
                final logs = CallHistoryService().history;
                if (logs.isEmpty) {
                  return Center(
                    child: GlassSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      opacity: 0.5,
                      child: Text(
                        'Qo\'ng\'iroqlar tarixi bo\'sh'.tr,
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    final timeStr = DateFormat(
                      'dd.MM.yyyy HH:mm',
                    ).format(log.timestamp);
                    IconData iconData;
                    Color iconColor;
                    if (log.status == 'connected') {
                      iconData = log.isIncoming
                          ? Icons.call_received
                          : Icons.call_made;
                      iconColor = Colors.green;
                    } else {
                      iconData = log.isIncoming
                          ? Icons.call_received_outlined
                          : Icons.call_made_outlined;
                      iconColor = Colors.red;
                    }
                    return GlassSurface(
                      padding: const EdgeInsets.all(8),
                      opacity: 0.55,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: Icon(iconData, color: iconColor),
                        title: Text(
                          log.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        subtitle: Text(
                          '${log.isIncoming ? "Kiruvchi".tr : "Chiquvchi".tr} • $timeStr\n${'Davomiyligi'.tr}: ${log.duration}',
                          style: TextStyle(
                            color: GlassTokens.secondaryText(context),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            CallHelper.makeDirectCall(
                              context,
                              log.userId,
                              log.userName,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : GuestBlockerWidget(
              title: 'Qo\'ng\'iroqlar tarixini ko\'rish uchun'.tr,
              subtitle: 'Ro\'yxatdan o\'ting yoki tizimga kiring'.tr,
              icon: Icons.history,
            ),
    );
  }
}
