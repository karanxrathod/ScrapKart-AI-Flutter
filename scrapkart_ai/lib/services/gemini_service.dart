import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
}
