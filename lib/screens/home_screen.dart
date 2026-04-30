import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/service_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assalomu alaykum,",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        "Kudratulloh",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Xizmatlarni qidirish...",
                    border: InputBorder.none,
                    icon: Icon(LucideIcons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Banner
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  viewportFraction: 1.0,
                  autoPlay: true,
                  enlargeCenterPage: false,
                ),
                items: [1, 2, 3].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Bugungi chegirmalar!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Sartaroshxonalarda 30% gacha",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {},
                                child: const Text("Batafsil"),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              // Services Grid Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "Xizmatlar",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Barchasi"),
                  )
                ],
              ),
              const SizedBox(height: 15),
              // Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
                children: [
                  ServiceCard(
                    title: "Sartarosh",
                    icon: LucideIcons.scissors,
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Salon",
                    icon: LucideIcons.sparkles,
                    color: Colors.pink,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Futbol",
                    icon: LucideIcons.trophy,
                    color: Colors.green,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Ishchi",
                    icon: LucideIcons.users,
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Usta",
                    icon: LucideIcons.wrench,
                    color: Colors.teal,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Elektrik",
                    icon: LucideIcons.zap,
                    color: Colors.yellow,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Santexnik",
                    icon: LucideIcons.droplet,
                    color: Colors.lightBlue,
                    onTap: () {},
                  ),
                  ServiceCard(
                    title: "Yana",
                    icon: LucideIcons.moreHorizontal,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Featured Section
              Text(
                "Tavsiya etiladi",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Premium Barber Shop",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Toshkent, Chilonzor tumani",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(LucideIcons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text("4.9 (120 sharh)", style: TextStyle(fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ),
    );
  }
}
