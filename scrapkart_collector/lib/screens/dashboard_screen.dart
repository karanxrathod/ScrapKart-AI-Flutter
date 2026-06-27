import 'package:flutter/material.dart';
import 'pickup_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline = true;

  final List<Map<String, dynamic>> _activePickups = [
    {
      'id': 'REQ-9921',
      'category': 'Plastic Bottles',
      'weight': '2.4 kg',
      'address': '123 Green Street, Tech Park',
      'distance': '1.2 km',
      'status': 'Assigned'
    },
    {
      'id': 'REQ-9922',
      'category': 'Cardboard Boxes',
      'weight': '5.1 kg',
      'address': '456 Eco Road, Central City',
      'distance': '3.5 km',
      'status': 'Pending'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isOnline,
                activeColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                  });
                },
              ),
            ],
          )
        ],
      ),
      body: _isOnline ? _buildDashboard() : _buildOfflineState(),
    );
  }

  Widget _buildOfflineState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'You are currently offline.',
            style: TextStyle(fontSize: 20, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            'Toggle your status to start receiving pickups.',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Pickups', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('14', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earned', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('₹ 1,450', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Active Assignments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _activePickups.length,
              itemBuilder: (context, index) {
                final pickup = _activePickups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pickup['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pickup['status'],
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pickup['category'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Est. Weight: ${pickup['weight']}'),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pickup['address'], style: const TextStyle(color: Colors.black87))),
                            Text(pickup['distance'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PickupMapScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Start Navigation', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
