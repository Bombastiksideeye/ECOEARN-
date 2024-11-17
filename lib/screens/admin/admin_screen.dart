import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'admin_service.dart';

class AdminScreen extends StatelessWidget {
  final AdminService _adminService = AdminService();

  AdminScreen({super.key});

  Widget _buildImageWidget(BuildContext context, String? base64Image) {
    if (base64Image == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Show full-screen image
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Stack(
              children: [
                Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: MemoryImage(base64Decode(base64Image)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.getRecyclingRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No recycling requests found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('${data['userName'] ?? 'Unknown User'}'),
                  subtitle: Text(
                    '${data['materialType']?.toUpperCase()} - ${DateFormat('MMM dd, yyyy HH:mm').format(data['timestamp'].toDate())}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${data['status']?.toUpperCase()}'),
                          Text('Quantity: ${data['quantity']}'),
                          Text('Weight: ${data['weight']} kg'),
                          const SizedBox(height: 8),
                          if (data['imageData'] != null) ...[
                            const Text('Image:'),
                            const SizedBox(height: 8),
                            _buildImageWidget(context, data['imageData']),
                          ],
                          const SizedBox(height: 16),
                          if (data['status'] == 'pending')
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _adminService.approveRequest(
                                    doc.id,
                                    data['userId'],
                                    data['weight'].toDouble(),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request approved successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                              child: const Text('Approve Request'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
