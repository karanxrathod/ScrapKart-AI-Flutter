import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDbService {
  static const String _bookingsKey = 'local_bookings';
  static const String _currentUserKey = 'local_current_user';
  static const String _registeredUsersKey = 'local_registered_users';
  static const String _savedAddressesKey = 'local_saved_addresses';
  static const String _savedPaymentsKey = 'local_saved_payments';

  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  // --- USER AUTHENTICATION (LOCAL STORAGE ONLY) ---

  // Check if a user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentUserKey);
  }

  // Get current logged-in user details
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_currentUserKey);
    if (userStr == null) return null;
    final Map<String, dynamic> decoded = jsonDecode(userStr);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  // Register a new user locally
  Future<bool> registerUserLocal({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersListStr = prefs.getString(_registeredUsersKey) ?? '[]';
    final List<dynamic> users = jsonDecode(usersListStr);

    // Check if user already exists
    final exists = users.any((u) => u['email'] == email.trim().toLowerCase());
    if (exists) {
      throw Exception('An account with this email already exists.');
    }

    final newUser = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    users.add(newUser);
    await prefs.setString(_registeredUsersKey, jsonEncode(users));

    // Auto-login the registered user
    await prefs.setString(_currentUserKey, jsonEncode({'name': newUser['name'], 'email': newUser['email']}));
    return true;
  }

  // Login a user locally
  Future<bool> loginUserLocal({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersListStr = prefs.getString(_registeredUsersKey) ?? '[]';
    final List<dynamic> users = jsonDecode(usersListStr);

    final user = users.firstWhere(
      (u) => u['email'] == email.trim().toLowerCase() && u['password'] == password,
      orElse: () => null,
    );

    if (user == null) {
      throw Exception('Invalid email or password.');
    }

    await prefs.setString(_currentUserKey, jsonEncode({'name': user['name'], 'email': user['email']}));
    return true;
  }

  // Logout current user
  Future<void> logoutUserLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // --- BOOKINGS (LOCAL STORAGE ONLY) ---

  // Get all bookings from local storage
  Future<List<Map<String, dynamic>>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsStr = prefs.getString(_bookingsKey);
    if (bookingsStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(bookingsStr);
    return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>?> getBookingById(String id) async {
    final bookings = await getBookings();
    try {
      return bookings.firstWhere((b) => b['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateBookingStatus(
    String id,
    String status, {
    Map<String, dynamic>? collector,
    double? actualWeight,
    double? actualPrice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = await getBookings();
    bool updated = false;

    for (int i = 0; i < bookings.length; i++) {
      if (bookings[i]['id'] == id) {
        final Map<String, dynamic> updatedBooking = Map<String, dynamic>.from(bookings[i]);
        updatedBooking['status'] = status;
        if (collector != null) {
          updatedBooking['collector'] = collector;
        }
        if (actualWeight != null) {
          updatedBooking['actualWeight'] = actualWeight;
        }
        if (actualPrice != null) {
          updatedBooking['actualPrice'] = actualPrice;
        }
        bookings[i] = updatedBooking;
        updated = true;
        break;
      }
    }

    if (updated) {
      await prefs.setString(_bookingsKey, jsonEncode(bookings));
      debugPrint('✅ Booking updated locally: id=$id, status=$status');
    }
  }

  // Add a new booking locally
  Future<void> addBooking({
    required List<String> scrapTypes,
    required String estimatedWeight,
    required String pickupAddress,
    required String date,
    required String time,
    double? estimatedPrice,
    String? payoutMethod,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = await getBookings();

    final user = await getCurrentUser();
    final userEmail = user?['email'] ?? 'guest@example.com';

    // Fallback calculation for price if not provided
    double price = estimatedPrice ?? 0.0;
    if (estimatedPrice == null) {
      final double weight = double.tryParse(estimatedWeight) ?? 0.0;
      double maxRate = 15.0;
      for (final t in scrapTypes) {
        double rate = 15.0;
        if (t.toLowerCase().contains('metal')) {
          rate = 75.0;
        } else if (t.toLowerCase().contains('e-waste')) {
          rate = 50.0;
        } else if (t.toLowerCase().contains('plastic')) {
          rate = 15.0;
        } else if (t.toLowerCase().contains('paper') || t.toLowerCase().contains('cardboard')) {
          rate = 12.0;
        } else if (t.toLowerCase().contains('glass')) {
          rate = 8.0;
        }
        if (rate > maxRate) {
          maxRate = rate;
        }
      }
      price = weight * maxRate;
    }

    final newBooking = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userEmail': userEmail,
      'scrapTypes': scrapTypes,
      'estimatedWeight': estimatedWeight,
      'pickupAddress': pickupAddress,
      'date': date,
      'time': time,
      'status': 'Pending',
      'createdAt': DateTime.now().toIso8601String(),
      'estimatedPrice': price,
    };
    if (payoutMethod != null) {
      newBooking['payoutMethod'] = payoutMethod;
    }

    bookings.insert(0, newBooking); // Add to the top of list
    await prefs.setString(_bookingsKey, jsonEncode(bookings));
    debugPrint('✅ Booking saved locally: $newBooking');
  }

  // --- SAVED ADDRESSES ---

  Future<List<Map<String, String>>> getSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesStr = prefs.getString(_savedAddressesKey);
    if (addressesStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(addressesStr);
    return decoded.map((item) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      return map.map((key, value) => MapEntry(key, value.toString()));
    }).toList();
  }

  Future<void> addSavedAddress(String label, String addressLine) async {
    final prefs = await SharedPreferences.getInstance();
    final addresses = await getSavedAddresses();
    final newAddress = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'label': label,
      'addressLine': addressLine,
    };
    addresses.add(newAddress);
    await prefs.setString(_savedAddressesKey, jsonEncode(addresses));
  }

  Future<void> deleteSavedAddress(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final addresses = await getSavedAddresses();
    addresses.removeWhere((item) => item['id'] == id);
    await prefs.setString(_savedAddressesKey, jsonEncode(addresses));
  }

  // --- PAYMENT METHODS ---

  Future<List<Map<String, String>>> getSavedPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsStr = prefs.getString(_savedPaymentsKey);
    if (paymentsStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(paymentsStr);
    return decoded.map((item) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      return map.map((key, value) => MapEntry(key, value.toString()));
    }).toList();
  }

  Future<void> addSavedPaymentMethod(String type, String details) async {
    final prefs = await SharedPreferences.getInstance();
    final payments = await getSavedPaymentMethods();
    final newPayment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'details': details,
    };
    payments.add(newPayment);
    await prefs.setString(_savedPaymentsKey, jsonEncode(payments));
  }

  Future<void> deleteSavedPaymentMethod(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final payments = await getSavedPaymentMethods();
    payments.removeWhere((item) => item['id'] == id);
    await prefs.setString(_savedPaymentsKey, jsonEncode(payments));
  }
}
