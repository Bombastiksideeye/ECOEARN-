import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../services/waste_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WasteService _wasteService = WasteService();
  Timer? _timer;
  int _currentInfoIndex = 0;

  final List<Map<String, String>> _infoItems = [
    {
      'image': 'assets/images/reduce.jpg',
      'text': 'REDUCE\nMinimize your waste',
    },
    {
      'image': 'assets/images/reuse.jpg',
      'text': 'REUSE\nGive items a second life',
    },
    {
      'image': 'assets/images/recycle.jpg',
      'text': 'RECYCLE\nTransform waste to new',
    },
  ];

  @override
  void initState() {
    super.initState();
    _wasteService.initializeUserStats();
    _startAutoChange();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoChange() {
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      setState(() {
        _currentInfoIndex = (_currentInfoIndex + 1) % _infoItems.length;
      });
    });
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            _infoItems[_currentInfoIndex]['image']!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ')[0] ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green curved container with user info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $firstName!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Start Recycling Today!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatsContainer(), // Points section
                ],
              ),
            ),
            // Info Section (moved back here)
            _buildInfoSection(),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryItem('Glass', Icons.wine_bar, 'assets/images/glass_bottle.png'),
                      _buildCategoryItem('Metal', Icons.architecture, 'assets/images/metal_can.png'),
                      _buildCategoryItem('Plastic', Icons.local_drink, 'assets/images/plastic_bottle.png'),
                      _buildCategoryItem('Electronics', Icons.devices, 'assets/images/electronics.png'),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, true),
                  _buildNavItem(Icons.lightbulb_outline, false),
                  _buildNavItem(Icons.person_outline, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, [String? imagePath]) {
    return Column(
      children: [
        Container(
          width: 85,
          height: 85,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: imagePath != null
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                )
              : Icon(
                  icon,
                  color: const Color(0xFF2E7D32),
                  size: 40,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E7D32).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
      ),
    );
  }

  Widget _buildStatsContainer() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _wasteService.getWasteStats(),
      builder: (context, snapshot) {
        // Show default values for any state (loading, error, or no data)
        final data = snapshot.data ?? {'totalPoints': 0, 'totalItems': 0};
        final points = data['totalPoints'];
        final items = data['totalItems'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$points pts',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total waste collected',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$items items',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 