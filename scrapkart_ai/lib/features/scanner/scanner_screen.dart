import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;
  final String _backendUrl = 'http://10.213.229.69:3000/api/scrap/scan-scrap';

  // Instantiate image picker
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _scanResult = null; // Clear previous results
      });
      _analyzeImage(_image!);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For this example, we encode as Base64. A Multipart approach using http.MultipartRequest is also perfectly valid.
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // We'll mock weight as 2.0 kg coming from a user input/scale.
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageBase64': base64Image,
          'weight': 2.0, 
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _scanResult = decoded['data'];
          });
        }
      } else {
        _showError('Failed to analyze image. Status Code: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      _showError('Network error connecting to AI Server. Please ensure Node.js backend is running.\nDetails: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Neumorphic/Soft UI Constants
    const baseColor = Color(0xFFE0E5EC);
    
    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: const Text('ScrapKart Vision AI', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: baseColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(baseColor),
              const SizedBox(height: 30),
              _buildControlButtons(baseColor),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.black54)),
              if (_scanResult != null && !_isLoading)
                _buildResultsCard(baseColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(Color baseColor) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            offset: const Offset(8, 8),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _image != null
            ? Image.file(_image!, fit: BoxFit.cover)
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_enhance_rounded, size: 80, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('Capture or upload scrap to identify', style: TextStyle(color: Colors.black54)),
                ],
              ),
      ),
    );
  }

  Widget _buildControlButtons(Color baseColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNeumorphicButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _pickImage(ImageSource.camera),
          baseColor: baseColor,
        ),
        _buildNeumorphicButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: () => _pickImage(ImageSource.gallery),
          baseColor: baseColor,
        ),
      ],
    );
  }

  Widget _buildNeumorphicButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color baseColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black54, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(Color baseColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Inner shadow simulation for 'pressed' state matching Neu-UI trends
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.4),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Analysis Result',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          _buildResultRow('Material Type', _scanResult!['material'].toString()),
          _buildResultRow('Condition Factor', _scanResult!['conditionFactor'].toString()),
          _buildResultRow('Base Rate (per kg)', "₹${_scanResult!['baseRate']}"),
          _buildResultRow('Weight', "${_scanResult!['weight']} kg"),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: Colors.green.shade100,
               borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                Text("₹${_scanResult!['estimatedPrice']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}
