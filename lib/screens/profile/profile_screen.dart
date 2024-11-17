import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileService _profileService = ProfileService();

  Future<void> _redeemPoints(BuildContext context, int currentPoints) async {
    // Show points input dialog
    final pointsToRedeem = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int? points;
        return AlertDialog(
          title: const Text('Redeem Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the number of points to redeem:'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Points (must be multiple of 10)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  points = int.tryParse(value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'You will receive ${(points ?? 0) ~/ 10} TrashCoins',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (points != null && points! <= currentPoints && points! % 10 == 0) {
                  Navigator.pop(context, points);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid points amount')),
                  );
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (pointsToRedeem == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: Text(
            'Are you sure you want to redeem $pointsToRedeem points for ${pointsToRedeem ~/ 10} TrashCoins?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tcToAdd = pointsToRedeem ~/ 10;

      // Update points and TC
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalPoints': FieldValue.increment(-pointsToRedeem),
        'trashCoins': FieldValue.increment(tcToAdd),
      });

      // Add notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'type': 'redeem',
        'message': 'Successfully redeemed $pointsToRedeem points for $tcToAdd TC',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully redeemed $tcToAdd TC!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to redeem points')),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _profileService.getProfileStats(),
              builder: (context, profileSnapshot) {
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _profileService.getRecyclingStats(),
                  builder: (context, recyclingSnapshot) {
                    final profileData = profileSnapshot.data ?? {};
                    final recyclingData = recyclingSnapshot.data ?? {};
                    
                    final totalPoints = profileData['totalPoints'] ?? 0;
                    
                    final monthlyData = {
                      'plastic': recyclingData['plastic_month'] ?? 0,
                      'glass': recyclingData['glass_month'] ?? 0,
                      'metal': recyclingData['metal_month'] ?? 0,
                      'electronics': recyclingData['electronics_month'] ?? 0,
                    };
                    
                    final totalData = {
                      'plastic': recyclingData['plastic_total'] ?? 0,
                      'glass': recyclingData['glass_total'] ?? 0,
                      'metal': recyclingData['metal_total'] ?? 0,
                      'electronics': recyclingData['electronics_total'] ?? 0,
                    };

                    final monthlyTotal = monthlyData['plastic']! +
                                        monthlyData['glass']! +
                                        monthlyData['metal']! +
                                        monthlyData['electronics']!;

                    return Column(
                      children: [
                        // Header with Logout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showLogoutDialog(context),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Profile Image and Name
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Points Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Earned Total Points: ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '$totalPoints',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => _redeemPoints(context, totalPoints),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Redeem TC'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Recycled Materials Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recycled Materials',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Donut Chart
                              SizedBox(
                                height: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 70,
                                        sections: [
                                          PieChartSectionData(
                                            value: monthlyData['plastic']!.toDouble(),
                                            color: Colors.green,
                                            title: '',
                                            radius: 20,
                                          ),
                                          PieChartSectionData(
                                            value: monthlyData['glass']!.toDouble(),
                                            color: Colors.blue,
                                            title: '',
                                            radius: 20,
                                          ),
                                          PieChartSectionData(
                                            value: monthlyData['metal']!.toDouble(),
                                            color: Colors.yellow,
                                            title: '',
                                            radius: 20,
                                          ),
                                          PieChartSectionData(
                                            value: monthlyData['electronics']!.toDouble(),
                                            color: Colors.orange,
                                            title: '',
                                            radius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$monthlyTotal',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'g',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Text(
                                          'This month',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Legend Table
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(1.5),
                                  2: FlexColumnWidth(1),
                                },
                                children: [
                                  const TableRow(
                                    children: [
                                      Text('MATERIAL', style: TextStyle(color: Colors.grey)),
                                      Text('THIS MONTH', style: TextStyle(color: Colors.grey)),
                                      Text('TOTAL', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  _buildTableRow(
                                    'Plastic',
                                    '${monthlyData['plastic']}g',
                                    '${(totalData['plastic']! / 1000).toStringAsFixed(1)}kg',
                                    Colors.green,
                                  ),
                                  _buildTableRow(
                                    'Glass',
                                    '${monthlyData['glass']}g',
                                    '${(totalData['glass']! / 1000).toStringAsFixed(1)}kg',
                                    Colors.blue,
                                  ),
                                  _buildTableRow(
                                    'Metal',
                                    '${monthlyData['metal']}g',
                                    '${(totalData['metal']! / 1000).toStringAsFixed(1)}kg',
                                    Colors.yellow,
                                  ),
                                  _buildTableRow(
                                    'Electronics',
                                    '${monthlyData['electronics']}g',
                                    '${(totalData['electronics']! / 1000).toStringAsFixed(1)}kg',
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String material, String month, String total, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(material),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(month),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(total),
        ),
      ],
    );
  }
} 