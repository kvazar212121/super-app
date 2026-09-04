import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';
import '../widgets/top_providers_section.dart';
import '../widgets/campaign_banner.dart';
import '../theme/lux_tokens.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../screens/todo_screen.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/finance_manager_screen.dart';
import '../screens/all_categories_screen.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../screens/calorie/calorie_home_screen.dart';
import '../screens/fitness/fitness_home_screen.dart';
import '../screens/alarm/alarm_home_screen.dart';
import '../providers/auth_provider.dart';
import '../services/feature_service.dart';
import '../l10n/locale_controller.dart';
import 'premium/premium_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Oraliqlar bir maromda: bo'limlar orasi 24, ichkarisi 10-12.
    // Yon chekka 18 (oldin 20) — kartalar biroz kengroq nafas oladi.
    // Yagona yuqa ko'k-zangori orqa fon — sahifa bir xil ko'rinadi.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark rejimda fon LuxTokens.bg — MeshBackground bilan bir xil, shuning
    // uchun ekranlar orasida rang "sakramaydi".
    final bgColor = isDark ? LuxTokens.bg : const Color(0xFFF8F9FA);

    return ColoredBox(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeaderWidget(),
            const SizedBox(height: 18),
            // Karusel doim aylanadi (autoplay) — RepaintBoundary bilan bosh
            // sahifaning qolgan qismi qayta chizilmaydi.
            const RepaintBoundary(child: HomePromoSection()),
            const SizedBox(height: 18),
            const CampaignBanner(),
            _buildMainGrid(context),
            const SizedBox(height: 24),
            const ProviderPortalEntry(),
            const SizedBox(height: 28),
            // Sahifaning ENG PASTI — top reytingli provayderlar.
            // Soha bo'yicha filtrlanadi, "Yana" bilan pastga davom etadi.
            const TopProvidersSection(),
          ],
        ),
      ),
      ),
    );
  }

  /// Bo'lim yopiq bo'lsa "tez orada" ko'rsatadi, aks holda (kerak bo'lsa auth tekshirib) ochadi.
  Future<void> _openFeature(
    BuildContext context,
    String key,
    Widget Function() builder, {
    bool needAuth = true,
  }) async {
    if (!FeatureService().isEnabled(key)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Tez orada 🚧'.tr),
          content: Text(FeatureService().message(key)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tushunarli'.tr),
            ),
          ],
        ),
      );
      return;
    }
    final isPremiumFeature = FeatureService().isPremiumFeature(key);
    // Premium bo'lim yoki auth talab qilinsa — avval login shart
    if (isPremiumFeature || needAuth) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        );
        return;
      }
    }
    // Premium bo'lim — serverdan eng so'nggi holatni tekshirib, premium bo'lmasa obuna ekraniga
    if (isPremiumFeature) {
      await FeatureService().refreshPremium();
      if (!FeatureService().isUserPremium) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  Widget _buildMainGrid(BuildContext context) {
    // Tuzilma:
    //  • "Barcha xizmatlar" — butun enli asosiy tugma
    //  • 6 ta karta: 3 USTUN × 2 QATOR
    //     1-qator: Kaloriya · Fitnes · Rejalarim
    //     2-qator: Moliyam · Aqlli savdo · Budilnik
    //
    // NEGA GridView emas: bu ekran allaqachon SingleChildScrollView ichida.
    // Ichma-ich skroll murakkablik tug'diradi, Row esa oddiy va tez.
    // DIQQAT: quyidagi `stat`/`value`/`caption` qiymatlari hozircha
    // NAMUNA (dizaynni ko'rish uchun). Keyingi bosqichda har biri o'z
    // servisidan olinadi: kaloriya kunlik yig'indi, fitnes rejadagi mashq,
    // rejalar keyingi vaqti, moliya oylik xarajat, savdo ro'yxati qoldig'i,
    // budilnik keyingi signal vaqti.
    final kartalar = <Widget>[
      _DailyBtn(
        icon: LucideIcons.flame,
        label: 'Kaloriya'.tr,
        color: const Color(0xFFEF4444),
        bgImage: 'assets/images/calorie_counter_shaffof.png',
        stat: '68%',
        value: '1425',
        caption: '/ 2100 kcal',
        onTap: () =>
            _openFeature(context, 'calorie', () => const CalorieHomeScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.dumbbell,
        label: 'Fitnes'.tr,
        color: const Color(0xFF14B8A6),
        bgImage: 'assets/images/fitness_trainer_shaffof.png',
        stat: '2/5',
        value: 'Ko\'krak',
        caption: '5 mashq',
        onTap: () =>
            _openFeature(context, 'fitness', () => const FitnessHomeScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.calendarCheck,
        label: 'Rejalarim'.tr,
        color: const Color(0xFF3B82F6),
        bgImage: 'assets/images/my_plans_shaffof.png',
        stat: '1/5',
        value: '14:30',
        caption: 'keyingi',
        onTap: () => _openFeature(context, 'plans', () => const TodoScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.wallet,
        label: 'Moliyam'.tr,
        color: const Color(0xFF22C55E),
        bgImage: 'assets/images/my_finance_shaffof.png',
        stat: 'UZS',
        value: '1,105 ming',
        caption: 'xarajat',
        onTap: () => _openFeature(
          context,
          'finance',
          () => const FinanceManagerScreen(),
        ),
      ),
      _DailyBtn(
        icon: LucideIcons.shoppingBag,
        label: 'Aqlli savdo'.tr,
        color: const Color(0xFFF97316),
        bgImage: 'assets/images/smart_shopping_shaffof.png',
        stat: '2/5',
        value: '3 ta qoldi',
        caption: 'savdo ro\'yxati',
        onTap: () =>
            _openFeature(context, 'shopping', () => const ShoppingListScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.alarmClock,
        label: 'Budilnik'.tr,
        color: const Color(0xFF6366F1),
        bgImage: 'assets/images/majburolovchi_shaffof.png',
        stat: 'Faol',
        statAccent: true,
        value: '06:30',
        caption: 'uyg\'onish',
        onTap: () =>
            _openFeature(context, 'alarm', () => const AlarmHomeScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark (premium) rejimda sarlavha 'Kundalik vositalar' bo'lib
        // ko'rsatiladi; light rejimda qisqa 'Kundalik' qoladi.
        _SectionTitle(title: 'Kundalik'.tr),
        const SizedBox(height: 12),
        // Har 3 tadan qatorga bo'lamiz. Kartalar soni o'zgarsa
        // (masalan 7 ta bo'lsa) oxirgi qator to'lmasdan qoladi va
        // kartalar cho'zilib ketmasligi uchun bo'sh joy qo'shiladi.
        for (int i = 0; i < kartalar.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int j = i; j < i + 3; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: j < kartalar.length
                      ? kartalar[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
        // "Barcha xizmatlar" kartalardan KEYIN (foydalanuvchi so'roviga ko'ra).
        // Mantiqan ham to'g'ri: avval tez-tez ishlatiladigan kundalik
        // bo'limlar, keyin "hammasini ko'rish" havolasi.
        const SizedBox(height: 18),
        _buildServicesButton(context),
      ],
    );
  }

  /// "Barcha xizmatlar" — ekranning ASOSIY harakati.
  /// Interaktiv: gradient jonli suriladi, o'q chizig'i ishora qiladi,
  /// bosilganda karta bosilib qaytadi (`_ServicesButton` ga qarang).
  Widget _buildServicesButton(BuildContext context) {
    // RepaintBoundary: animatsiya (gradient/strelka) shu tugma ichida qoladi,
    // butun sahifa qayta chizilmaydi. FPS ni saqlaydi.
    return RepaintBoundary(
      child: _ServicesButton(
        onTap: () => _openFeature(
          context,
          'services',
          () => const AllCategoriesScreen(showBackButton: true),
          needAuth: false,
        ),
      ),
    );
  }
}

/// "Barcha xizmatlar" tugmasi — JONLI (interaktiv).
///
/// Uch xil harakat bir vaqtda ishlaydi:
///  1. **Gradient suriladi** — ranglar chapdan o'ngga sekin oqadi (6s).
///     Tugma "tirik" ko'rinadi, lekin ko'zni charchatmaydi.
///  2. **O'q chizig'i** — o'ngdagi strelka doimo chapga-o'ngga ishora
///     qiladi (1.4s), ya'ni "bu yerni bosing" degan ishora.
///  3. **Bosish javobi** — barmoq tekkanda tugma 4% kichrayadi va
///     soyasi susayadi, qo'yib yuborilganda joyiga qaytadi. Bu
///     foydalanuvchiga bosish HISOBGA OLINGANINI darhol bildiradi.
///
/// Animatsiyalar `dispose` da to'g'ri to'xtatiladi (xotira oqmasligi uchun).
class _ServicesButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ServicesButton({required this.onTap});

  @override
  State<_ServicesButton> createState() => _ServicesButtonState();
}

class _ServicesButtonState extends State<_ServicesButton>
    with TickerProviderStateMixin {
  late final AnimationController _oqim; // gradient oqimi
  late final AnimationController _ishora; // strelka ishorasi
  bool _bosilgan = false;

  @override
  void initState() {
    super.initState();
    _oqim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _ishora = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oqim.dispose();
    _ishora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return _buildLux(context);
    return _buildLight(context);
  }

  /// PREMIUM: gradient o'rniga tinch qora karta + oltin ikon + "40+" chipi.
  /// Rangli gradient qora-oltin palitrada begona ko'rinadi, shuning uchun
  /// urg'u faqat ikon va chip orqali beriladi.
  Widget _buildLux(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _bosilgan = true),
      onTapUp: (_) => setState(() => _bosilgan = false),
      onTapCancel: () => setState(() => _bosilgan = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _bosilgan ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: LuxTokens.surface,
            borderRadius: BorderRadius.circular(LuxTokens.radiusMd),
            border: Border.all(color: LuxTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: LuxTokens.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LuxTokens.gold.withValues(alpha: 0.32),
                  ),
                ),
                child: const Icon(
                  LucideIcons.layoutGrid,
                  color: LuxTokens.goldSoft,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Barcha xizmatlar'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: LuxTokens.display,
                              color: LuxTokens.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: LuxTokens.chip(accent: true),
                          child: Text(
                            '40+',
                            // Raqamli chip — `value` uslubi (tekis raqamlar).
                            style: LuxTokens.value(size: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _ishora,
                builder: (context, ikon) => Transform.translate(
                  offset: Offset(
                    Curves.easeInOut.transform(_ishora.value) * 4,
                    0,
                  ),
                  child: ikon,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: LuxTokens.goldBoxDecoration(isCircle: true),
                  child: const Icon(
                    LucideIcons.chevronRight,
                    color: Color(0xFF140D02),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLight(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _bosilgan = true),
      onTapUp: (_) => setState(() => _bosilgan = false),
      onTapCancel: () => setState(() => _bosilgan = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        // Bosilganda 4% kichrayadi — sezilarli, lekin bezovta qilmaydi.
        scale: _bosilgan ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _oqim,
          builder: (context, child) {
            // Gradient boshlanish nuqtasi doira bo'ylab suriladi.
            final t = _oqim.value * 2 * math.pi;
            return Container(
              height: 66,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                    Color(0xFF2563EB),
                    Color(0xFF4F46E5),
                  ],
                  begin: Alignment(math.cos(t), math.sin(t)),
                  end: Alignment(-math.cos(t), -math.sin(t)),
                ),
                boxShadow: [
                  // Bosilganda soya susayadi — tugma "pastga bosilgandek".
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(
                      alpha: _bosilgan ? 0.22 : 0.42,
                    ),
                    blurRadius: _bosilgan ? 12 : 22,
                    offset: Offset(0, _bosilgan ? 4 : 10),
                  ),
                ],
              ),
              child: child,
            );
          },
          // child — animatsiyada O'ZGARMAYDIGAN qism. Bir marta quriladi
          // va har kadrda qayta ishlatiladi (tejamkorlik uchun muhim).
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.layoutGrid,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcha xizmatlar'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Foydalanuvchiga tugma ortida NIMA borligini aytadi.
                      'Usta, tozalash, salon va boshqalar'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Strelka o'ngga-chapga ishora qiladi
              AnimatedBuilder(
                animation: _ishora,
                builder: (context, ikon) => Transform.translate(
                  offset: Offset(
                    Curves.easeInOut.transform(_ishora.value) * 5,
                    0,
                  ),
                  child: ikon,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi — chapda rangli vertikal chiziq + qalin yozuv.
/// Ekranni mantiqiy bo'laklarga ajratadi, ko'z osongina topadi.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // PREMIUM: oltin chiziq + katta harfli, keng oraliqli sarlavha.
      //
      // "KUNDALIK | VOSITALAR" ikki xil uslubdagi bo'lak edi va ikkita
      // alohida yorliqdek o'qilardi. Endi BITTA GAP, bitta shriftda va
      // bitta rangda — bo'lim nomi aniq va yaxlit.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: LuxTokens.goldGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kundalik vositalar'.tr.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxTokens.sectionTitle,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

/// Kundalik bo'lim kartasi.
///
/// DIZAYN QARORI: rasm butun kartani to'ldiradi, yozuv esa pastdagi
/// TO'Q RANGLI TASMA ustida turadi. Nega gradient emas:
///   • Bo'lim rasmlari OQ fonli (3D render). Shaffof qora gradient
///     oq fon ustida iflos kulrang dog' bo'lib ko'rinardi.
///   • To'q tasma esa qat'iy chegara beradi — toza va bir xil chiqadi,
///     rasm qanday bo'lishidan qat'i nazar.
///
/// Tasma rangi bo'limning o'z rangidan olinadi (to'qlashtirilgan), shuning
/// uchun har karta o'z shaxsiyatini saqlaydi, lekin yaxlit ko'rinadi.
class _DailyBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? bgImage;

  /// PREMIUM ko'rinish uchun qo'shimcha ma'lumot (dark rejimda ishlatiladi).
  /// [stat] — o'ng-yuqoridagi kichik yorliq (masalan "68%", "2/5").
  /// [value] — kartaning markazidagi ASOSIY son (oltin rangda).
  /// [caption] — [value] ostidagi izoh (masalan "/ 2100 KCAL").
  /// Berilmasa, o'sha element chizilmaydi — karta baribir to'g'ri ko'rinadi.
  final String? stat;
  final String? value;
  final String? caption;
  final bool statAccent;

  const _DailyBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.bgImage,
    this.stat,
    this.value,
    this.caption,
    this.statAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return _buildLux(context);
    return _buildLight(context);
  }

  /// PREMIUM karta: rasm YO'Q, faqat tipografiya va bitta ikon.
  ///
  /// NEGA rasmsiz: 3D render rasmlar rangli va "o'yinchoqdek" ko'rinadi,
  /// qora+oltin qat'iy uslubga zid. Bu yerda ma'lumot (son) asosiy —
  /// foydalanuvchi bir qarashda holatini ko'radi, keyin bosadi.
  Widget _buildLux(BuildContext context) {
    return Material(
      color: LuxTokens.surface,
      borderRadius: BorderRadius.circular(LuxTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuxTokens.radiusMd),
        child: Container(
          height: 138,
          decoration: BoxDecoration(
            color: LuxTokens.surface,
            borderRadius: BorderRadius.circular(LuxTokens.radiusMd),
            border: Border.all(color: LuxTokens.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bgImage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
                  child: Image.asset(
                    bgImage!,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                )
              else
                Center(
                  child: Icon(icon, color: LuxTokens.gold, size: 36),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    border: Border(
                      top: BorderSide(color: Color(0xFFC9A227), width: 1.2),
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(LuxTokens.radiusMd - 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: LuxTokens.body,
                            color: Color(0xFF000000),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 15,
                        color: Color(0xFF000000),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLight(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LuxTokens.gold.withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: LuxTokens.gold.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bgImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 30),
                child: Image.asset(
                  bgImage!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              )
            else
              Container(
                color: LuxTokens.gold.withValues(alpha: 0.12),
                child: Center(child: Icon(icon, color: LuxTokens.gold, size: 32)),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                decoration: const BoxDecoration(
                  gradient: LuxTokens.goldGradient,
                  border: Border(
                    top: BorderSide(color: Color(0xFFC9A227), width: 1.2),
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(17),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: LuxTokens.body,
                          color: Color(0xFF000000),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: Color(0xFF000000),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
