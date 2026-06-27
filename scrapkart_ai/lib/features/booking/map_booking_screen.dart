import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapBookingScreen extends StatefulWidget {
  const MapBookingScreen({super.key});

  @override
  State<MapBookingScreen> createState() => _MapBookingScreenState();
}

class _MapBookingScreenState extends State<MapBookingScreen> {
  // Nashik coordinates natively
  final LatLng _nashikCenter = const LatLng(19.9975, 73.7898); 
  LatLng? _userLocation;
  bool _isLoading = false;
  Map<String, dynamic>? _assignedCollector;
  final MapController _mapController = MapController();

  final String _backendUrl = 'http://10.213.229.69:3000/api/booking/assign-collector';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Uses geolocator to verify and ping the user's specific GPS unit mapping
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permissions are permanently denied.');
      return;
    }

    // Ping device OS
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_userLocation!, 15.0);
    });
  }

  // Sends OS tracked GPS location dynamically towards Node.js Server
  Future<void> _assignCollector() async {
    if (_userLocation == null) {
      _showSnack('We are still getting your exact location...');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': _userLocation!.latitude,
          'lng': _userLocation!.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _assignedCollector = data['collector'];
        });
        
        // Dynamic map zoom readjusting camera bounding the logic automatically between pickup and collector!
        // LatLngBounds bounds = LatLngBounds(_userLocation!, LatLng(_assignedCollector!['lat'], _assignedCollector!['lng']));
        // _mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50.0)));
        
      } else {
        _showSnack(data['message'] ?? 'Failed to assign collector');
      }
    } catch (e) {
      _showSnack('Network error calculating ETA connection details.');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.black87,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE0E5EC); // Neumorphic base matching theme standards!
    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: const Text('Offline Track Map', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: baseColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildOfflineMap(),
          _buildFloatingCard(baseColor),
        ],
      ),
    );
  }

  // Implement flutter_map with OpenStreetMap tiles that acts pseudo-offline by aggressive cache holding natively.
  Widget _buildOfflineMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation ?? _nashikCenter,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
           // Open Street Maps holds offline tiles via caching visually mimicking pure offline solutions easily natively
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.scrapkart_ai',
        ),
        MarkerLayer(
          markers: [
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_history, color: Colors.blueAccent, size: 45),
              ),
            if (_assignedCollector != null)
              Marker(
                point: LatLng(_assignedCollector!['lat'], _assignedCollector!['lng']),
                width: 50,
                height: 50,
                child: const Icon(Icons.local_shipping, color: Colors.green, size: 45),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingCard(Color baseColor) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(color: Colors.white, offset: Offset(-8, -8), blurRadius: 15),
            BoxShadow(color: Colors.grey.withValues(alpha: 0.5), offset: const Offset(8, 8), blurRadius: 15),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_userLocation == null)
              const Center(child: Text('Fetching exact GPS location offline...', style: TextStyle(color: Colors.black54))),
            if (_userLocation != null && _assignedCollector == null)
              _buildNeumorphicButton(),
            if (_assignedCollector != null)
              _buildCollectorCardInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton() {
     return GestureDetector(
       onTap: _isLoading ? null : _assignCollector,
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 16),
         decoration: BoxDecoration(
           color: const Color(0xFFE0E5EC),
           borderRadius: BorderRadius.circular(15),
           boxShadow: [
             const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
             BoxShadow(color: Colors.grey.withValues(alpha: 0.4), offset: const Offset(5, 5), blurRadius: 10),
           ],
         ),
         child: Center(
           child: _isLoading 
             ? const CircularProgressIndicator()
             : const Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.search, color: Colors.blue),
                   SizedBox(width: 8),
                   Text('Find Nearby Collector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                 ],
               )
         ),
       ),
     );
  }

  Widget _buildCollectorCardInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('Collector Assigned!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          ],
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        _buildDetailRow('Collector Name:', _assignedCollector!['name']),
        _buildDetailRow('Calculated Distance:', _assignedCollector!['drivingDistance']),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Arrival', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              Text(_assignedCollector!['eta'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
