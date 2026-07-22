part of '../service_hub_screen.dart';

class _ActionList extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;
  final HubScreenData data;
  // Xizmat turi (subkategoriya) — hub bo'limlarining Filtr modaliga uzatiladi
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const _ActionList({
    required this.kind,
    required this.accentColor,
    required this.data,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (kind == ServiceHubKind.sartarosh)
          BarberHubSection(shops: data.barberShops, accentColor: accentColor, categories: categories, selectedCategory: selectedCategory, onCategorySelected: onCategorySelected,),
        if (kind == ServiceHubKind.salon)
          SalonHubSection(salons: data.salons, accentColor: accentColor, categories: categories, selectedCategory: selectedCategory, onCategorySelected: onCategorySelected,),
        if (kind == ServiceHubKind.futbol)
          FootballHubSection(
            fields: data.footballFields,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.tozalash)
          CleaningHubSection(
            cleaners: data.masters,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.usta)
          MasterDispatchHubSection(
            masters: data.masters,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.elektrik)
          ElectricianHubSection(
            electricians: data.masters,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.santexnik)
          PlumberHubSection(
            plumbers: data.masters,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.konditsioner)
          AcHubSection(
            technicians: data.masters,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.enaga)
          NannyHubSection(
            nannies: data.nannies,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.kuryerlik)
          CourierHubSection(
            couriers: data.couriers,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.avtoYordam)
          AutoHelpHubSection(
            units: data.autoMobile,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.avtoYordam)
          AutoWorkshopHubSection(
            workshops: data.workshops,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.repetitor) ...[
          TutorHubSection(
            tutors: data.tutors,
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin o'quv markazlari".tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: data.educationCenters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  EducationCenterSmallCard(center: data.educationCenters[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (kind == ServiceHubKind.ishchi)
          _buildSection(
            context,
            "Yaqin ishchilar",
            data.workers.map((w) => WorkerSmallCard(worker: w)).toList(),
          ),
        if (kind == ServiceHubKind.dezinfeksiya)
          _buildSection(
            context,
            "Dezinfeksiya xizmatlari",
            data.disinfection
                .map((s) => DisinfectionSmallCard(service: s))
                .toList(),
          ),
        if (kind == ServiceHubKind.texnikaUstasi)
          _buildSection(
            context,
            "Texnika ustalari",
            data.appliance.map((s) => ApplianceSmallCard(service: s)).toList(),
          ),
        if (kind == ServiceHubKind.massajHijoma)
          MassageCenterHubSection(
            centers: data.massage.where((m) => m.supportsAtCenter).toList(),
            accentColor: accentColor,
            categories: categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        if (kind == ServiceHubKind.hamshira)
          _buildSection(
            context,
            "Hamshira xizmatlari",
            data.nurses.map((s) => NurseSmallCard(service: s)).toList(),
          ),
        if (kind == ServiceHubKind.stomatologiya)
          _buildSection(
            context,
            "Stomatologiya klinikalari",
            data.dentalClinics.map((c) => DentalSmallCard(clinic: c)).toList(),
          ),
        if (kind == ServiceHubKind.tadbirlar) ...[
          if (data.genericProviders.isNotEmpty)
            _buildSection(
              context,
              "Tadbir o'tkazish joylari",
              data.genericProviders
                  .map((f) => EventVenueSmallCard(venue: f))
                  .toList(),
            ),
          if (data.events.isNotEmpty)
            _buildSection(
              context,
              "Tashkilotchi va Brigadalar",
              data.events.map((s) => EventTeamSmallCard(team: s)).toList(),
              // Filtr faqat 1-bo'limда (joylar yo'q bo'lsa — shu yerда)
              withFilter: data.genericProviders.isEmpty,
            ),
        ],
        if (kind == ServiceHubKind.gameZona) ...[
          if (data.genericProviders.isNotEmpty)
            _buildSection(
              context,
              "PS5 va Kompyuter klublari",
              data.genericProviders
                  .map((f) => GameZoneSmallCard(zone: f))
                  .toList(),
            ),
        ],
        if (kind == ServiceHubKind.sportMaydon) ...[
          if (data.genericProviders.isNotEmpty)
            _buildSection(
              context,
              "Sport maydonchalari",
              data.genericProviders
                  .map((f) => SportFacilitySmallCard(facility: f))
                  .toList(),
            ),
        ],
        if (kind == ServiceHubKind.bozorchi)
          _buildSection(
            context,
            "Bozorchi va kuryerlar",
            data.masters.map((m) => MasterSmallCard(master: m)).toList(),
          ),
        if (kind == ServiceHubKind.oshxona)
          _buildSection(
            context,
            "Oshxona va Restoranlar",
            data.masters.map((m) => MasterSmallCard(master: m)).toList(),
          ),

        if (_catalogEntries(context).isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _CatalogButton(
              accentColor: accentColor,
              count: _catalogEntries(context).length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceCatalogScreen(
                    title: '${kind.title.tr} — ${'Umumiy katalog'.tr}',
                    accentColor: accentColor,
                    entries: _catalogEntries(context),
                  ),
                ),
              ),
            ),
          ),

        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _CompactActionTile(
                      title: actions[i].title,
                      icon: actions[i].icon,
                      accentColor: accentColor,
                      onTap: actions[i].onTap,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<Master> _filteredMasters() {
    if (kind == ServiceHubKind.usta) return data.masters;
    final specialty = switch (kind) {
      ServiceHubKind.elektrik => 'Elektrik',
      ServiceHubKind.santexnik => 'Santexnik',
      ServiceHubKind.tozalash => 'Tozalash',
      ServiceHubKind.konditsioner => 'Konditsioner',
      ServiceHubKind.enaga => 'Enaga',
      ServiceHubKind.repetitor => 'Repetitor',
      _ => null,
    };
    if (specialty != null) {
      return data.masters.where((m) => m.specialty == specialty).toList();
    }
    return data.masters;
  }

  double _minPrice(Map<String, double> prices, double fallback) {
    if (prices.values.isEmpty) return fallback;
    return prices.values.reduce((a, b) => a < b ? a : b);
  }

  CatalogEntry _masterEntry(
    Master m,
    IconData icon,
    ServiceHubKind category,
    double fallbackPrice,
    String defaultSubtitle,
  ) {
    final min = _minPrice(m.prices, fallbackPrice);
    return CatalogEntry(
      name: m.name,
      subtitle: m.serviceArea ?? defaultSubtitle,
      rating: m.rating,
      reviewCount: m.reviewCount,
      priceLabel: '${(min / 1000).round()}k+',
      icon: icon,
      latitude: m.latitude,
      longitude: m.longitude,
      rawJson: m.rawJson,
      onOpen: (ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => ProviderProfileScreen(master: m, category: category),
        ),
      ),
    );
  }

  /// Joriy xizmat turi uchun BARCHA provayderlarni katalog elementlariga
  /// o'giradi. Gorizontal kartalar bilan bir xil onTap/ma'lumot ishlatadi.
  List<CatalogEntry> _catalogEntries(BuildContext context) {
    switch (kind) {
      case ServiceHubKind.elektrik:
        return data.masters
            .map((e) => _masterEntry(
                e, LucideIcons.zap, ServiceHubKind.elektrik, 100000, 'Uyga xizmat'))
            .toList();
      case ServiceHubKind.santexnik:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.droplet,
                ServiceHubKind.santexnik, 100000, 'Uyga xizmat'))
            .toList();
      case ServiceHubKind.konditsioner:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.wind,
                ServiceHubKind.konditsioner, 180000, 'Uyga xizmat'))
            .toList();
      case ServiceHubKind.tozalash:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.sprayCan,
                ServiceHubKind.tozalash, 200000, 'Tozalash'))
            .toList();
      case ServiceHubKind.usta:
        return data.masters
            .map((e) => _masterEntry(
                e, LucideIcons.hammer, ServiceHubKind.usta, 100000, 'Usta'))
            .toList();
      case ServiceHubKind.sartarosh:
        return data.mobileBarbers
            .map((e) => _masterEntry(e, LucideIcons.scissors,
                ServiceHubKind.sartarosh, 35000, 'Uyga xizmat'))
            .toList();
      case ServiceHubKind.salon:
        return data.mobileStylists
            .map((e) => _masterEntry(e, LucideIcons.sparkles,
                ServiceHubKind.salon, 50000, 'Mutaxassis'))
            .toList();
      case ServiceHubKind.enaga:
        return data.nannies
            .map((n) => CatalogEntry(
                  name: n.name,
                  subtitle: '${n.experienceYears} yil • ${n.ageGroupsLabel}',
                  rating: n.rating,
                  reviewCount: n.reviewCount,
                  priceLabel:
                      '${(_minPrice(n.prices, 80000) / 1000).round()}k+',
                  icon: LucideIcons.baby,
                  latitude: n.latitude,
                  longitude: n.longitude,
                  rawJson: n.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => NannyProfileScreen(nanny: n),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.kuryerlik:
        return data.couriers
            .map((c) => CatalogEntry(
                  name: c.name,
                  subtitle: c.serviceArea ?? c.vehicleType.label,
                  rating: c.rating,
                  reviewCount: c.reviewCount,
                  priceLabel:
                      '${(_minPrice(c.prices, 25000) / 1000).round()}k+',
                  icon: LucideIcons.bike,
                  latitude: c.latitude,
                  longitude: c.longitude,
                  rawJson: c.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => CourierDispatchScreen(service: c),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.avtoYordam:
        return [
          ...data.autoMobile.map((u) => CatalogEntry(
                name: u.name,
                subtitle: u.serviceArea ?? u.vehicleType.label,
                rating: u.rating,
                reviewCount: u.reviewCount,
                priceLabel: '${(_minPrice(u.prices, 80000) / 1000).round()}k+',
                icon: u.vehicleType.icon,
                latitude: u.latitude,
                longitude: u.longitude,
                rawJson: u.rawJson,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => AutoMobileDispatchScreen(service: u),
                  ),
                ),
              )),
          ...data.workshops.map((w) => CatalogEntry(
                name: w.name,
                subtitle: w.specializations.take(2).join(', '),
                rating: w.rating,
                reviewCount: w.reviewCount,
                priceLabel: '${(_minPrice(w.prices, 80000) / 1000).round()}k+',
                icon: LucideIcons.house,
                latitude: w.latitude,
                longitude: w.longitude,
                rawJson: w.rawJson,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => AutoWorkshopDispatchScreen(workshop: w),
                  ),
                ),
              )),
        ];
      case ServiceHubKind.repetitor:
        return data.tutors
            .map((t) => CatalogEntry(
                  name: t.name,
                  subtitle: t.subjectsLabel,
                  rating: t.rating,
                  reviewCount: t.reviewCount,
                  priceLabel:
                      '${(_minPrice(t.prices, 100000) / 1000).round()}k+',
                  icon: LucideIcons.bookOpen,
                  latitude: t.latitude,
                  longitude: t.longitude,
                  rawJson: t.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => TutorProfileScreen(tutor: t),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.massajHijoma:
        return data.massage
            .map((s) => CatalogEntry(
                  name: s.name,
                  subtitle: s.serviceTypes.isNotEmpty
                      ? s.serviceTypes.first.label
                      : 'Mutaxassis',
                  rating: s.rating,
                  reviewCount: s.reviewCount,
                  priceLabel:
                      '${(_minPrice(s.prices, 50000) / 1000).round()}k+',
                  icon: LucideIcons.heartPulse,
                  latitude: s.latitude,
                  longitude: s.longitude,
                  rawJson: s.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: massageToMaster(s),
                        category: ServiceHubKind.massajHijoma,
                      ),
                    ),
                  ),
                ))
            .toList();
      default:
        return const [];
    }
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> items, {
    bool withFilter = true,
  }) {
    // Xarita OSTIDA — bo'lim sarlavhasining o'ng tarafida bitta "Filtr" tugmasi.
    final showFilter =
        withFilter && categories.isNotEmpty && onCategorySelected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              if (showFilter)
                HubFilterButton(
                  accent: accentColor,
                  showSort: false,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
            ],
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => items[i],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Ikki xil uslub (joyida + uyga borib) bo'lgan xizmatlar uchun "uyga
  /// boradiganlar" bo'limi. Yo'q bo'lsa (yoki bir uslub) null qaytadi.
  Widget? _mobileSection() {
    switch (kind) {
      case ServiceHubKind.sartarosh:
        if (data.mobileBarbers.isEmpty) return null;
        return MobileBarberHubSection(
            barbers: data.mobileBarbers, accentColor: accentColor);
      case ServiceHubKind.salon:
        if (data.mobileStylists.isEmpty) return null;
        return MobileSalonHubSection(
            stylists: data.mobileStylists, accentColor: accentColor);
      case ServiceHubKind.massajHijoma:
        final mobile =
            data.massage.where((m) => m.supportsHomeVisit).toList();
        if (mobile.isEmpty) return null;
        return MobileMassageHubSection(
            specialists: mobile, accentColor: accentColor);
      default:
        return null;
    }
  }

  /// "Uyga borib xizmat qiluvchilar" tugmasi bosilganда — kartalar modalда.
  void _openMobileSheet(BuildContext context) {
    final section = _mobileSection();
    if (section == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: section)),
            ],
          ),
        ),
      ),
    );
  }

  List<_HubActionSpec> _actions(BuildContext context) {
    void toast(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    void openEvent({OrganizerServiceType? organizer, EventType? eventType}) {
      if (data.events.isEmpty) {
        toast('Tadbir guruhlari tez orada qo\'shiladi.'.tr);
        return;
      }
      EventPlanning target = data.events.first;
      if (organizer != null) {
        target = data.events.firstWhere(
          (s) => s.organizerTypes.contains(organizer),
          orElse: () => data.events.first,
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventBookingScreen(
            service: target,
            initialOrganizerType: organizer,
            initialEventType: eventType,
          ),
        ),
      );
    }

    void openNurse(MedicalService? medical) {
      if (data.nurses.isEmpty) {
        toast('Hamshira xizmatlari tez orada qo\'shiladi.'.tr);
        return;
      }
      final target = medical == null
          ? data.nurses.first
          : data.nurses.firstWhere(
              (s) => s.medicalServices.contains(medical),
              orElse: () => data.nurses.first,
            );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NurseBookingScreen(
            service: target,
            initialMedicalService: medical,
          ),
        ),
      );
    }

    void openMobileBarbers() {
      if (data.mobileBarbers.isEmpty) {
        toast('Hozircha mobil sartaroshlar yo\'q. Tez orada qo\'shiladi.'.tr);
        return;
      }
      if (data.mobileBarbers.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.mobileBarbers.first,
              category: ServiceHubKind.sartarosh,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mobil sartarosh tanlang'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...data.mobileBarbers.map(
                (b) => ListTile(
                  leading: const Icon(LucideIcons.scissors),
                  title: Text(b.name),
                  subtitle: Text(b.serviceArea ?? 'Uyga xizmat'.tr),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderProfileScreen(
                          master: b,
                          category: ServiceHubKind.sartarosh,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    void openCleaningTeams() {
      final teams = data.masters.where((m) => m.isCleaningTeam).toList();
      if (teams.isEmpty) {
        if (data.masters.isEmpty) {
          toast('Hozircha tozalash xizmatlari yo\'q.'.tr);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.masters.first,
              category: ServiceHubKind.tozalash,
            ),
          ),
        );
        return;
      }
      if (teams.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: teams.first,
              category: ServiceHubKind.tozalash,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'General tozalash jamoasi'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...teams.map(
                (m) => ListTile(
                  leading: const Icon(LucideIcons.users),
                  title: Text(m.name),
                  subtitle: Text(
                    m.teamSize != null
                        ? '${m.teamSize} ${'kishilik jamoa'.tr}'
                        : 'Tozalash jamoasi'.tr,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderProfileScreen(
                          master: m,
                          category: ServiceHubKind.tozalash,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    void openMasterBrigades() {
      final brigades = data.masters.where((m) => m.isMasterBrigade).toList();
      if (brigades.isEmpty) {
        if (data.masters.isEmpty) {
          toast('Hozircha ustalar yo\'q.'.tr);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.masters.first,
              category: ServiceHubKind.usta,
            ),
          ),
        );
        return;
      }
      if (brigades.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: brigades.first,
              category: ServiceHubKind.usta,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ustalar brigadasi'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...brigades.map(
                (m) => ListTile(
                  leading: const Icon(LucideIcons.users),
                  title: Text(m.name),
                  subtitle: Text(
                    m.teamSize != null
                        ? '${m.teamSize} ${'kishilik brigada'.tr}'
                        : 'Ustalar brigadasi'.tr,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderProfileScreen(
                          master: m,
                          category: ServiceHubKind.usta,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    void openMobileStylists() {
      if (data.mobileStylists.isEmpty) {
        toast('Hozircha mobil kosmetologlar yo\'q. Tez orada qo\'shiladi.'.tr);
        return;
      }
      if (data.mobileStylists.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.mobileStylists.first,
              category: ServiceHubKind.salon,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mobil kosmetolog'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...data.mobileStylists.map(
                (s) => ListTile(
                  leading: const Icon(LucideIcons.sparkles),
                  title: Text(s.name),
                  subtitle: Text(s.serviceArea ?? 'Uyga xizmat'.tr),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderProfileScreen(
                          master: s,
                          category: ServiceHubKind.salon,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return switch (kind) {
          ServiceHubKind.sartarosh => <_HubActionSpec>[],
          ServiceHubKind.salon => <_HubActionSpec>[],
          ServiceHubKind.bozorchi => <_HubActionSpec>[],
          ServiceHubKind.oshxona => <_HubActionSpec>[],
          ServiceHubKind.futbol => <_HubActionSpec>[],
          ServiceHubKind.elektrik => <_HubActionSpec>[],
          ServiceHubKind.santexnik => <_HubActionSpec>[],
          ServiceHubKind.tozalash => <_HubActionSpec>[],
          ServiceHubKind.avtoYordam => <_HubActionSpec>[],
          ServiceHubKind.konditsioner => <_HubActionSpec>[],
          ServiceHubKind.enaga => <_HubActionSpec>[],
          ServiceHubKind.repetitor => <_HubActionSpec>[],
          ServiceHubKind.ishchi => <_HubActionSpec>[],
          ServiceHubKind.usta => <_HubActionSpec>[],
          // 6 ta YANGI:
          ServiceHubKind.dezinfeksiya => <_HubActionSpec>[],
          ServiceHubKind.texnikaUstasi => <_HubActionSpec>[],
          ServiceHubKind.kuryerlik => <_HubActionSpec>[],
          ServiceHubKind.massajHijoma => <_HubActionSpec>[],
          ServiceHubKind.hamshira => <_HubActionSpec>[],
          ServiceHubKind.stomatologiya => <_HubActionSpec>[],
          ServiceHubKind.tadbirlar => <_HubActionSpec>[],
          ServiceHubKind.gameZona ||
          ServiceHubKind.sportMaydon ||
          ServiceHubKind.bozorchi ||
          ServiceHubKind.oshxona ||
          ServiceHubKind.kompUsta ||
          ServiceHubKind.boshqa => <_HubActionSpec>[],
          _ => <_HubActionSpec>[],
        } +
        [
          if (_mobileSection() != null)
            _HubActionSpec(
              LucideIcons.house,
              'Uyga borib xizmat qiluvchilar'.tr,
              'Bosing — sizga keladigan ustalar'.tr,
              () => _openMobileSheet(context),
            ),
          _HubActionSpec(
            LucideIcons.bookmark,
            'Saqlangan joylar'.tr,
            'Saqlab qo‘yilgan joylar va ustalar'.tr,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedPlacesScreen(category: kind),
              ),
            ),
          ),
        ];
  }
}

class _HubActionSpec {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _HubActionSpec(this.icon, this.title, this.subtitle, this.onTap);
}

/// Ixcham amal tugmasi — yonma-yon joylashtirish uchun (icon + nom).
class _CompactActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _CompactActionTile({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Umumiy katalog" tugmasi — grid ko'rinishда barcha provayderlarni ochadi.
class _CatalogButton extends StatelessWidget {
  final Color accentColor;
  final int count;
  final VoidCallback onTap;

  const _CatalogButton({
    required this.accentColor,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accentColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(LucideIcons.layoutGrid, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Umumiy katalog'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
