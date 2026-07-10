part of '../service_hub_screen.dart';

class _ActionList extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;
  final HubScreenData data;

  const _ActionList({
    required this.kind,
    required this.accentColor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (kind == ServiceHubKind.sartarosh) ...[
          BarberHubSection(shops: data.barberShops, accentColor: accentColor),
          MobileBarberHubSection(
            barbers: data.mobileBarbers,
            accentColor: accentColor,
          ),
        ],
        if (kind == ServiceHubKind.salon) ...[
          SalonHubSection(salons: data.salons, accentColor: accentColor),
          MobileSalonHubSection(
            stylists: data.mobileStylists,
            accentColor: accentColor,
          ),
        ],
        if (kind == ServiceHubKind.futbol)
          FootballHubSection(
            fields: data.footballFields,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.tozalash)
          CleaningHubSection(cleaners: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.usta)
          MasterDispatchHubSection(
            masters: data.masters,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.elektrik)
          ElectricianHubSection(
            electricians: data.masters,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.santexnik)
          PlumberHubSection(plumbers: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.konditsioner)
          AcHubSection(technicians: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.enaga)
          NannyHubSection(nannies: data.nannies, accentColor: accentColor),
        if (kind == ServiceHubKind.kuryerlik)
          CourierHubSection(couriers: data.couriers, accentColor: accentColor),
        if (kind == ServiceHubKind.avtoYordam)
          AutoHelpHubSection(units: data.autoMobile, accentColor: accentColor),
        if (kind == ServiceHubKind.avtoYordam)
          AutoWorkshopHubSection(
            workshops: data.workshops,
            accentColor: accentColor,
          ),
        if (kind == ServiceHubKind.repetitor) ...[
          TutorHubSection(tutors: data.tutors, accentColor: accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin o'quv markazlari",
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
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  EducationCenterSmallCard(center: data.educationCenters[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (kind == ServiceHubKind.usta) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin ustaxonalar",
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
              itemCount: data.workshops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  WorkshopSmallCard(workshop: data.workshops[i]),
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
        if (kind == ServiceHubKind.massajHijoma) ...[
          MassageCenterHubSection(
            centers: data.massage.where((m) => m.supportsAtCenter).toList(),
            accentColor: accentColor,
          ),
          MobileMassageHubSection(
            specialists: data.massage
                .where((m) => m.supportsHomeVisit)
                .toList(),
            accentColor: accentColor,
          ),
        ],
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

        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: actions
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HubActionCard(
                        title: a.title,
                        subtitle: a.subtitle,
                        icon: a.icon,
                        accentColor: accentColor,
                        onTap: a.onTap,
                      ),
                    ),
                  )
                  .toList(),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title,
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
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => items[i],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<_HubActionSpec> _actions(BuildContext context) {
    void toast(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    void openEvent({OrganizerServiceType? organizer, EventType? eventType}) {
      if (data.events.isEmpty) {
        toast('Tadbir guruhlari tez orada qo\'shiladi.');
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
        toast('Hamshira xizmatlari tez orada qo\'shiladi.');
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
        toast('Hozircha mobil sartaroshlar yo\'q. Tez orada qo\'shiladi.');
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Mobil sartarosh tanlang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...data.mobileBarbers.map(
                (b) => ListTile(
                  leading: const Icon(LucideIcons.scissors),
                  title: Text(b.name),
                  subtitle: Text(b.serviceArea ?? 'Uyga xizmat'),
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
          toast('Hozircha tozalash xizmatlari yo\'q.');
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'General tozalash jamoasi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...teams.map(
                (m) => ListTile(
                  leading: const Icon(LucideIcons.users),
                  title: Text(m.name),
                  subtitle: Text(
                    m.teamSize != null
                        ? '${m.teamSize} kishilik jamoa'
                        : 'Tozalash jamoasi',
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
          toast('Hozircha ustalar yo\'q.');
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ustalar brigadasi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...brigades.map(
                (m) => ListTile(
                  leading: const Icon(LucideIcons.users),
                  title: Text(m.name),
                  subtitle: Text(
                    m.teamSize != null
                        ? '${m.teamSize} kishilik brigada'
                        : 'Ustalar brigadasi',
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
        toast('Hozircha mobil kosmetologlar yo\'q. Tez orada qo\'shiladi.');
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Mobil kosmetolog',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...data.mobileStylists.map(
                (s) => ListTile(
                  leading: const Icon(LucideIcons.sparkles),
                  title: Text(s.name),
                  subtitle: Text(s.serviceArea ?? 'Uyga xizmat'),
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
          _HubActionSpec(
            LucideIcons.bookmark,
            'Saqlangan joylar',
            'Saqlab qo‘yilgan joylar va ustalar',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedPlacesScreen(category: kind),
              ),
            ),
          ),
          _HubActionSpec(
            LucideIcons.layoutGrid,
            'Barcha xizmatlar',
            'To‘liq katalog',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AllCategoriesScreen()),
            ),
          ),
          _HubActionSpec(
            LucideIcons.headphones,
            'Qo‘llab-quvvatlash',
            'Chat yoki qo‘ng‘iroq',
            () => toast('Support — tez orada'),
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
