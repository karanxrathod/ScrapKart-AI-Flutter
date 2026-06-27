import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class PickupMapScreen extends StatefulWidget {
  final String? bookingId;
  const PickupMapScreen({super.key, this.bookingId});

  @override
  State<PickupMapScreen> createState() => _PickupMapScreenState();
}

class _PickupMapScreenState extends State<PickupMapScreen> {
  IO.Socket? _socket;
  Timer? _locationTimer;
  double _currentLat = 19.9975;
  double _currentLng = 73.7898;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _startLocationUpdates();
  }

  void _initSocket() {
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket?.connect();
  }

  void _startLocationUpdates() {
    // Mock sending location every 2 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (widget.bookingId != null) {
        _socket?.emit('collector_location', {
          'bookingId': widget.bookingId,
          'lat': _currentLat,
          'lng': _currentLng,
        });
        
        // Slightly move the collector for demo purposes
        _currentLat += 0.0001;
        _currentLng += 0.0001;
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socket?.disconnect();
    super.dispose();
  }

  Future<void> _showOtpDialog() async {
    final TextEditingController otpController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ask the user for their 4-digit OTP to confirm pickup.'),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '4-Digit OTP',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text;
                if (otp.length == 4) {
                  // Verify OTP with backend
                  try {
                    final dio = Dio();
                    final response = await dio.post('http://10.0.2.2:5000/api/booking/otp/verify', data: {
                      'bookingId': widget.bookingId ?? '1', // mock ID if null
                      'otp': otp
                    });
                    
                    if (response.data['success'] == true) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close map screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pickup Verified and Completed!')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid OTP. Please try again.')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                        // Mock success for demo if backend is not running or booking ID doesn't exist
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close map screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP Verified successfully!')),
                        );
                    }
                  }
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation to Pickup'),
      ),
      body: Stack(
        children: [
          // Mock Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE0E0E0),
            child: CustomPaint(
              painter: MapRoutePainter(),
            ),
          ),
          
          // Map Overlay Header
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.turn_right, size: 40, color: Colors.green),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In 200m, turn right onto Green St.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Total: 1.2 km • 5 mins away', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bottom Action Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Arriving at Pickup Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('123 Green Street, Tech Park', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Call user functionality
                          },
                          icon: const Icon(Icons.phone, color: Colors.green),
                          label: const Text('Call User', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showOtpDialog();
                          },
                          icon: const Icon(Icons.security, color: Colors.white),
                          label: const Text('Verify OTP & Pickup', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Simple CustomPainter to draw a fake route on the grey background
class MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);

    // Draw Collector Location
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 12, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 8, Paint()..color = Colors.blue);

    // Draw Destination Pin
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 12, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
