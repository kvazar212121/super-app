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
    final catalog = _catalogEntries(context);

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
          _mixedRow(context, "Avto-yordam va ustaxonalar", catalog),
        if (kind == ServiceHubKind.repetitor)
          _mixedRow(context, "Repetitor va o'quv markazlari", catalog),

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
        if (kind == ServiceHubKind.tadbirlar)
          _mixedRow(context, "Tadbir joylari va tashkilotchilar", catalog),
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

        if (catalog.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _CatalogButton(
              accentColor: accentColor,
              count: catalog.length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceCatalogScreen(
                    title: '${kind.title.tr} — ${'Umumiy katalog'.tr}',
                    accentColor: accentColor,
                    entries: catalog,
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

  double _minPrice(Map<String, double> prices, double fallback) {
    if (prices.values.isEmpty) return fallback;
    return prices.values.reduce((a, b) => a < b ? a : b);
  }

  CatalogEntry _masterEntry(
    Master m,
    IconData icon,
    ServiceHubKind category,
    double fallbackPrice,
    String defaultSubtitle, {
    String idPrefix = 'master',
  }) {
    final min = _minPrice(m.prices, fallbackPrice);
    return CatalogEntry(
      id: '${idPrefix}_${m.id}',
      name: m.name,
      subtitle: m.serviceArea ?? defaultSubtitle,
      rating: m.rating,
      reviewCount: m.reviewCount,
      priceLabel: '${(min / 1000).round()}k+',
      icon: icon,
      latitude: m.latitude,
      longitude: m.longitude,
      rawJson: m.rawJson,
      // Usta/mutaxassis narx ro'yxatidagi xizmat nomlari — teg sifatida.
      tags: m.prices.keys.take(4).toList(),
      // Ish vaqti kiritilgan bo'lsa shunga qarab, aks holda 8:00–20:00.
      isOpen: isOpenAt(
        hours: workingHoursFrom(m.rawJson),
        defaultOpen: 8,
        defaultClose: 20,
      ),
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
  /// Tashqaridan (yangi dizayn ekrani) chaqirish uchun ochiq nom.
  List<CatalogEntry> catalogEntries(BuildContext context) =>
      _catalogEntries(context);

  List<CatalogEntry> _catalogEntries(BuildContext context) {
    // context parametri interfeys izchilligi uchun (ishlatilmaydi — onOpen
    // o'z BuildContext'ini oladi).
    switch (kind) {
      case ServiceHubKind.elektrik:
        return data.masters
            .map((e) => _masterEntry(
                e, LucideIcons.zap, ServiceHubKind.elektrik, 100000, 'Uyga xizmat',
                idPrefix: 'electrician'))
            .toList();
      case ServiceHubKind.santexnik:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.droplet,
                ServiceHubKind.santexnik, 100000, 'Uyga xizmat',
                idPrefix: 'plumber'))
            .toList();
      case ServiceHubKind.konditsioner:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.wind,
                ServiceHubKind.konditsioner, 180000, 'Uyga xizmat',
                idPrefix: 'ac'))
            .toList();
      case ServiceHubKind.tozalash:
        return data.masters
            .map((e) => _masterEntry(e, LucideIcons.sprayCan,
                ServiceHubKind.tozalash, 200000, 'Tozalash',
                idPrefix: 'cleaner'))
            .toList();
      case ServiceHubKind.usta:
        return data.masters
            .map((e) => _masterEntry(
                e, LucideIcons.hammer, ServiceHubKind.usta, 100000, 'Usta',
                idPrefix: 'master'))
            .toList();
      case ServiceHubKind.sartarosh:
        return [
          ...data.barberShops.map((s) => CatalogEntry(
                id: 'barber_${s.id}',
                name: s.name,
                subtitle: s.address,
                rating: s.rating,
                reviewCount: s.reviewCount,
                priceLabel: s.priceRangeLabel(),
                icon: LucideIcons.scissors,
                latitude: s.latitude,
                longitude: s.longitude,
                rawJson: s.rawJson,
                isOpen: s.isOpenNow(),
                // Teglar — sartaroshxona taklif qiladigan xizmatlar.
                tags: s.services.take(4).toList(),
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => BarberBookingScreen(shop: s),
                  ),
                ),
              )),
          ...data.mobileBarbers.map((e) => _masterEntry(e,
              LucideIcons.scissors, ServiceHubKind.sartarosh, 35000, 'Uyga xizmat',
              idPrefix: 'mobile_barber')),
        ];
      case ServiceHubKind.salon:
        return [
          ...data.salons.map((s) => CatalogEntry(
                id: 'salon_${s.id}',
                isOpen: s.isOpenNow(),
                tags: s.services.take(4).toList(),
                name: s.name,
                subtitle: s.address,
                rating: s.rating,
                reviewCount: s.reviewCount,
                priceLabel: s.priceRangeLabel(),
                icon: LucideIcons.sparkles,
                latitude: s.latitude,
                longitude: s.longitude,
                rawJson: s.rawJson,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => SalonBookingScreen(salon: s),
                  ),
                ),
              )),
          ...data.mobileStylists.map((e) => _masterEntry(
              e, LucideIcons.sparkles, ServiceHubKind.salon, 50000, 'Mutaxassis',
              idPrefix: 'mobile_stylist')),
        ];
      case ServiceHubKind.futbol:
        return data.footballFields
            .map((f) => CatalogEntry(
                  id: 'field_${f.id}',
                  isOpen: f.isOpenNow(),
                  tags: [f.sizeSurfaceLabel],
                  name: f.name,
                  subtitle: '${f.sizeSurfaceLabel} · ${f.address}',
                  rating: f.rating,
                  reviewCount: f.reviewCount,
                  priceLabel: f.priceLabel,
                  icon: LucideIcons.trophy,
                  latitude: f.latitude,
                  longitude: f.longitude,
                  rawJson: f.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => FootballFieldBookingScreen(field: f),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.enaga:
        return data.nannies
            .map((n) => CatalogEntry(
                  id: 'nanny_${n.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(n.rawJson),
                    defaultOpen: 6,
                    defaultClose: 22,
                  ),
                  tags: n.services.take(4).toList(),
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
                  id: 'courier_${c.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(c.rawJson),
                  defaultOpen: 6,
                  defaultClose: 22,
                ),
                  tags: c.prices.keys.take(4).toList(),
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
                id: 'automobile_${u.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(u.rawJson),
                  defaultOpen: 0,
                  defaultClose: 24,
                ),
                tags: u.services.take(4).toList(),
                name: u.name,
                subtitle: 'Mobil · ${u.serviceArea ?? u.vehicleType.label}',
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
                id: 'workshop_${w.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(w.rawJson),
                  defaultOpen: 8,
                  defaultClose: 19,
                ),
                tags: w.specializations.take(4).toList(),
                name: w.name,
                subtitle: w.specializations.isEmpty
                    ? 'Ustaxona'
                    : 'Ustaxona · ${w.specializations.take(2).join(', ')}',
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
        return [
          ...data.tutors.map((t) => CatalogEntry(
                id: 'tutor_${t.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(t.rawJson),
                  defaultOpen: 8,
                  defaultClose: 21,
                ),
                tags: t.subjects.take(4).toList(),
                name: t.name,
                subtitle: 'Repetitor · ${t.subjectsLabel}',
                rating: t.rating,
                reviewCount: t.reviewCount,
                priceLabel: '${(_minPrice(t.prices, 100000) / 1000).round()}k+',
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
              )),
          ...data.educationCenters.map((c) => CatalogEntry(
                id: 'edu_${c.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(c.rawJson),
                  defaultOpen: 9,
                  defaultClose: 19,
                ),
                tags: c.courses.take(4).toList(),
                name: c.name,
                subtitle: c.courses.isEmpty
                    ? "O'quv markazi"
                    : "Markaz · ${c.courses.take(2).join(', ')}",
                rating: c.rating,
                reviewCount: c.reviewCount,
                priceLabel: '',
                icon: LucideIcons.graduationCap,
                latitude: c.latitude,
                longitude: c.longitude,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => EducationCenterBookingScreen(center: c),
                  ),
                ),
              )),
        ];
      case ServiceHubKind.massajHijoma:
        return data.massage
            .map((s) => CatalogEntry(
                  id: 'massage_${s.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(s.rawJson),
                    defaultOpen: 9,
                    defaultClose: 21,
                  ),
                  tags: s.serviceTypes.take(4).map((t) => t.label).toList(),
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
      case ServiceHubKind.hamshira:
        return data.nurses
            .map((n) => CatalogEntry(
                  id: 'nurse_${n.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(n.rawJson),
                    defaultOpen: 0,
                    defaultClose: 24,
                  ),
                  tags: n.prices.keys.take(4).toList(),
                  name: n.name,
                  subtitle: n.serviceArea ?? 'Hamshira xizmati',
                  rating: n.rating,
                  reviewCount: n.reviewCount,
                  priceLabel: '',
                  icon: LucideIcons.heartPulse,
                  latitude: n.latitude,
                  longitude: n.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => NurseBookingScreen(service: n),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.stomatologiya:
        return data.dentalClinics
            .map((c) => CatalogEntry(
                  id: 'dental_${c.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(c.rawJson),
                    defaultOpen: 9,
                    defaultClose: 19,
                  ),
                  tags: c.services.take(4).toList(),
                  name: c.name,
                  subtitle: c.subCategory ?? c.address,
                  rating: c.rating,
                  reviewCount: c.reviewCount,
                  priceLabel: c.prices.values.isEmpty
                      ? ''
                      : '${(_minPrice(c.prices, 0) / 1000).round()}k+',
                  icon: LucideIcons.stethoscope,
                  latitude: c.latitude,
                  longitude: c.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => DentalBookingScreen(clinic: c),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.dezinfeksiya:
        return data.disinfection
            .map((s) => CatalogEntry(
                  id: 'disinfection_${s.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(s.rawJson),
                    defaultOpen: 8,
                    defaultClose: 20,
                  ),
                  tags: s.prices.keys.take(4).toList(),
                  name: s.name,
                  subtitle: s.serviceArea ?? 'Dezinfeksiya',
                  rating: s.rating,
                  reviewCount: s.reviewCount,
                  priceLabel: '',
                  icon: LucideIcons.sprayCan,
                  latitude: s.latitude,
                  longitude: s.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => DisinfectionProfileScreen(service: s),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.texnikaUstasi:
        return data.appliance
            .map((s) => CatalogEntry(
                  id: 'appliance_${s.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(s.rawJson),
                    defaultOpen: 9,
                    defaultClose: 19,
                  ),
                  tags: s.brands.take(4).toList(),
                  name: s.name,
                  subtitle: s.subCategory ?? 'Texnika ustasi',
                  rating: s.rating,
                  reviewCount: s.reviewCount,
                  priceLabel: '',
                  icon: LucideIcons.wrench,
                  latitude: s.latitude,
                  longitude: s.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ApplianceProfileScreen(service: s),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.ishchi:
        return data.workers
            .map((w) => CatalogEntry(
                  id: 'worker_${w.id}',
                  isOpen: isOpenAt(
                    defaultOpen: 7,
                    defaultClose: 19,
                  ),
                  tags: [w.type],
                  name: w.name,
                  subtitle: w.type,
                  rating: w.rating,
                  reviewCount: 0,
                  priceLabel: (w.price ?? 0) > 0
                      ? '${((w.price ?? 0) / 1000).round()}k+'
                      : '',
                  icon: LucideIcons.hardHat,
                  latitude: w.latitude,
                  longitude: w.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => WorkerProfileScreen(worker: w),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.gameZona:
        return data.genericProviders
            .whereType<GameZone>()
            .map((z) => CatalogEntry(
                  id: 'gamezone_${z.id}',
                  isOpen: isOpenAt(
                    defaultOpen: 10,
                    defaultClose: 24,
                  ),
                  tags: [z.zoneType],
                  name: z.name,
                  subtitle: z.zoneType,
                  rating: 0,
                  reviewCount: 0,
                  priceLabel: '${(z.basePricePerHour / 1000).round()}k/soat',
                  icon: LucideIcons.gamepad2,
                  latitude: z.latitude,
                  longitude: z.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => GameZoneBookingScreen(zone: z),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.sportMaydon:
        return data.genericProviders
            .whereType<SportFacility>()
            .map((f) => CatalogEntry(
                  id: 'sport_${f.id}',
                  isOpen: isOpenAt(
                    defaultOpen: 7,
                    defaultClose: 23,
                  ),
                  tags: [f.sportType],
                  name: f.name,
                  subtitle: f.sportType,
                  rating: 0,
                  reviewCount: 0,
                  priceLabel: '${(f.basePricePerHour / 1000).round()}k/soat',
                  icon: LucideIcons.dumbbell,
                  latitude: f.latitude,
                  longitude: f.longitude,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => SportFacilityBookingScreen(facility: f),
                    ),
                  ),
                ))
            .toList();
      case ServiceHubKind.tadbirlar:
        return [
          ...data.genericProviders.whereType<EventVenue>().map((v) => CatalogEntry(
                id: 'venue_${v.id}',
                isOpen: isOpenAt(
                  defaultOpen: 9,
                  defaultClose: 23,
                ),
                tags: [v.venueType],
                name: v.name,
                subtitle: 'Joy · ${v.venueType}',
                rating: 0,
                reviewCount: 0,
                priceLabel: '',
                icon: LucideIcons.partyPopper,
                latitude: v.latitude,
                longitude: v.longitude,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => EventVenueBookingScreen(venue: v),
                  ),
                ),
              )),
          ...data.events.map((s) => CatalogEntry(
                id: 'eventteam_${s.id}',
                isOpen: isOpenAt(
                  hours: workingHoursFrom(s.rawJson),
                  defaultOpen: 9,
                  defaultClose: 21,
                ),
                tags: s.prices.keys.take(4).toList(),
                name: s.name,
                subtitle: 'Tashkilotchi',
                rating: s.rating,
                reviewCount: s.reviewCount,
                priceLabel: '',
                icon: LucideIcons.users,
                latitude: s.latitude,
                longitude: s.longitude,
                onOpen: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => EventTeamProfileScreen(team: s),
                  ),
                ),
              )),
        ];
      case ServiceHubKind.bozorchi:
        return data.masters
            .map((m) => _masterEntry(
                m, LucideIcons.shoppingCart, ServiceHubKind.bozorchi, 0, 'Bozorchi',
                idPrefix: 'bozorchi'))
            .toList();
      case ServiceHubKind.oshxona:
        return data.masters
            .map((m) => CatalogEntry(
                  id: 'oshxona_${m.id}',
                  isOpen: isOpenAt(
                    hours: workingHoursFrom(m.rawJson),
                    defaultOpen: 9,
                    defaultClose: 23,
                  ),
                  tags: m.prices.keys.take(4).toList(),
                  name: m.name,
                  subtitle: m.serviceArea ?? 'Oshxona',
                  rating: m.rating,
                  reviewCount: m.reviewCount,
                  priceLabel: '${(_minPrice(m.prices, 0) / 1000).round()}k+',
                  icon: LucideIcons.utensils,
                  latitude: m.latitude,
                  longitude: m.longitude,
                  rawJson: m.rawJson,
                  onOpen: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => OshxonaProfileScreen(oshxona: m),
                    ),
                  ),
                ))
            .toList();
      default:
        return const [];
    }
  }

  /// Turli xil uslubдаги (masalan mobil avto-yordam + ustaxona) provayderlarni
  /// BITTA gorizontal qatorда, eng yaqin bo'yicha aralash ko'rsatadi. Har karta
  /// subtitle turini ajratib turadi. `_catalogEntries` bilan bir manba.
  Widget _mixedRow(
    BuildContext context,
    String title,
    List<CatalogEntry> entries, {
    bool withFilter = true,
  }) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final sorted = [...entries]
      ..sort((a, b) => distanceKm(kDefaultUserLat, kDefaultUserLng, a.latitude, a.longitude)
          .compareTo(distanceKm(kDefaultUserLat, kDefaultUserLng, b.latitude, b.longitude)));
    final showFilter =
        withFilter && categories.isNotEmpty && onCategorySelected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
              Text(
                '${sorted.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              if (showFilter) ...[
                const SizedBox(width: 10),
                HubFilterButton(
                  accent: accentColor,
                  showSort: false,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final e = sorted[i];
              return VenueHubCard.generic(
                name: e.name,
                subtitle: e.subtitle,
                rating: e.rating,
                reviewCount: e.reviewCount,
                priceLabel: e.priceLabel,
                icon: e.icon,
                accent: accentColor,
                rawJson: e.rawJson,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, e.latitude, e.longitude,
                ),
                onTap: () => e.onOpen(context),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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
