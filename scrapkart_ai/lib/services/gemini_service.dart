import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class GeminiService {
  static const String _apiKeyKey = 'gemini_api_key';
  
  // Singleton instance
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  // Save API Key
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey.trim());
  }

  // Get API Key
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  // Check if API Key is configured
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  // Clear API Key
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }

  // Direct chat calling Gemini 2.5 Flash
  Future<String> getChatResponse({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY_NOT_CONFIGURED');
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    // Build the request contents
    final List<Map<String, dynamic>> contents = [];

    // Map existing conversation history into Gemini format (user vs model roles)
    for (final msg in conversationHistory) {
      final bool isMe = msg['isMe'] ?? false;
      final text = msg['text'] ?? '';
      contents.add({
        'role': isMe ? 'user' : 'model',
        'parts': [
          {'text': text}
        ]
      });
    }

    // Add the new message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': message}
      ]
    });

    final requestBody = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {
            'text':
                'You are ScrapKart AI, a smart, friendly, and helpful recycling assistant for ScrapKart. '
                'ScrapKart is a mobile application that allows users to sell their household scrap (like paper, plastic bottles, metals, e-waste, glass) '
                'or donate pre-loved goods (like clothes, books, toys) to local NGOs. '
                'Your goal is to assist users with pricing queries, recycling best practices, scheduling pickups, '
                'or general scrap segregation questions. Keep your answers brief, modern, clear, and action-oriented.'
          }
        ]
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 800,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'No text generated.';
          }
        }
        return 'Could not retrieve AI response.';
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        final errMsg = errData['error']?['message'] ?? 'Status Code: ${response.statusCode}';
        throw Exception('Gemini API Error: $errMsg');
      }
    } catch (e) {
      debugPrint('Gemini Chat Request failed: $e');
      rethrow;
    }
  }

  // Vision Direct call for Material Analysis
  Future<Map<String, dynamic>> scanMaterial(File imageFile) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY_NOT_CONFIGURED');
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Analyze this household scrap material image. Determine what scrap material is present, '
                  'its recyclability details, and estimate key metrics including its visual volume and weight. '
                  'You MUST respond strictly with a valid JSON block containing only these exact keys: '
                  '"material" (a string with a clean name like "Green Glass Bottle", "PET Soda Bottle", "Cardboard Box", "Iron Pipe Scrap", "Aluminum Can", "Defunct Keyboard"), '
                  '"conditionFactor" (a float/double between 0.0 and 1.0 representing how clean/well-preserved it is, e.g. 0.85), '
                  '"estimatedPricePerKg" (an integer representing typical scrap value in Indian Rupees (INR) per kg, e.g. 10 to 120), '
                  '"suggestedCategory" (a string choosing EXACTLY one of: "Recyclable Plastics", "Metal Scrap", "E-Waste", "Paper & Cardboard", "Glass Scrap"), '
                  '"estimatedVolumeLiters" (an integer representing the visual volume in liters, e.g., 2, 15, 50), '
                  '"estimatedWeightKg" (a float representing the estimated weight in kg based on the material and volume, e.g., 0.5, 2.5). '
                  'Do NOT include any markdown code blocks or backticks. Return only raw JSON.'
            },
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String textResult = parts[0]['text'] ?? '';
            
            // Clean markdown if the LLM ignored instructions
            textResult = textResult.trim();
            if (textResult.startsWith('```')) {
              textResult = textResult.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
            }
            
            final Map<String, dynamic> parsedJson = jsonDecode(textResult);
            return parsedJson;
          }
        }
        throw Exception('Failed to parse scan data.');
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        final errMsg = errData['error']?['message'] ?? 'Status Code: ${response.statusCode}';
        throw Exception('Gemini Vision API Error: $errMsg');
      }
    } catch (e) {
      debugPrint('Gemini Vision Request failed: $e');
      rethrow;
    }
  }

  // ── Offline AI Fallback: Smart Image Color Analysis ──────────────────────
  // No model file needed. Analyzes dominant colors to classify scrap type.
  // Works 100% offline on any device.
  Future<Map<String, dynamic>> scanMaterialOffline(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception('Cannot decode image.');

      // Resize for faster processing
      img.Image small = img.copyResize(originalImage, width: 64, height: 64);

      double totalR = 0, totalG = 0, totalB = 0;
      double totalBrightness = 0;
      double metallic = 0; // silver/grey pixels
      double greenish = 0; // green/natural pixels
      double darkPixels = 0; // dark/black (e-waste boards)
      int count = small.width * small.height;

      for (var y = 0; y < small.height; y++) {
        for (var x = 0; x < small.width; x++) {
          final pixel = small.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          final brightness = (r + g + b) / 3.0;

          totalR += r;
          totalG += g;
          totalB += b;
          totalBrightness += brightness;

          // Metallic: grey/silver = R~G~B all similar & mid-brightness
          if ((r - g).abs() < 25 && (g - b).abs() < 25 && brightness > 80 && brightness < 200) {
            metallic++;
          }
          // Greenish: nature/paper/cardboard
          if (g > r * 1.1 && g > b * 1.1) greenish++;
          // Dark: e-waste PCBs are very dark
          if (brightness < 60) darkPixels++;
        }
      }

      final avgR = totalR / count;
      final avgG = totalG / count;
      final avgB = totalB / count;
      final avgBright = totalBrightness / count;
      final metallicRatio = metallic / count;
      final greenRatio = greenish / count;
      final darkRatio = darkPixels / count;

      // ── Classification Rules ─────────────────────────────────────────────
      String category;
      String material;
      int pricePerKg;

      if (darkRatio > 0.35 && metallicRatio < 0.2) {
        // Lots of dark pixels + not metallic = E-Waste (PCBs, wires)
        category = 'E-Waste';
        material = 'Electronic Waste / PCB Board';
        pricePerKg = 120;
      } else if (metallicRatio > 0.30) {
        // Lots of grey/silver pixels = Metal
        category = 'Metal Scrap';
        material = 'Metal Scrap (Steel / Aluminium)';
        pricePerKg = 45;
      } else if (avgBright > 200 && avgR < 200 && avgG < 200 && avgB > 180) {
        // Very bright & blue-ish = Glass
        category = 'Glass Scrap';
        material = 'Glass Bottle / Container';
        pricePerKg = 5;
      } else if (greenRatio > 0.25 ||
          (avgG > avgR * 0.9 && avgBright > 120 && avgBright < 210)) {
        // Green tones or warm brown = Paper/Cardboard
        category = 'Paper & Cardboard';
        material = 'Cardboard / Paper Waste';
        pricePerKg = 8;
      } else if (avgR > 160 && avgB > 150 && avgG > 150 && avgBright > 150) {
        // Bright, colorful, mixed = Plastic
        category = 'Recyclable Plastics';
        material = 'Plastic Bottle / Container';
        pricePerKg = 12;
      } else {
        // Default fallback
        category = 'Recyclable Plastics';
        material = 'Mixed Recyclable Plastic';
        pricePerKg = 10;
      }

      debugPrint('Offline Scan: avgR=$avgR avgG=$avgG avgB=$avgB metallic=${(metallicRatio*100).toStringAsFixed(1)}% dark=${(darkRatio*100).toStringAsFixed(1)}% -> $category');

      return {
        'material': '$material (Offline Scan)',
        'conditionFactor': (avgBright / 255).clamp(0.6, 0.95),
        'estimatedPricePerKg': pricePerKg,
        'suggestedCategory': category,
        'estimatedVolumeLiters': 3,
        'estimatedWeightKg': 1.2,
      };
    } catch (e) {
      debugPrint('Offline color analysis failed: $e');
      // Last-resort fallback — return a safe generic result
      return {
        'material': 'Mixed Scrap (Offline Fallback)',
        'conditionFactor': 0.7,
        'estimatedPricePerKg': 10,
        'suggestedCategory': 'Recyclable Plastics',
        'estimatedVolumeLiters': 3,
        'estimatedWeightKg': 1.0,
      };
    }
  }
}
