import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  // Fetch role and details from Firestore
  try {
    final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      return UserModel(
        uid: user.uid,
        name: data['name'] ?? user.displayName ?? 'ScrapKart User',
        email: data['email'] ?? user.email ?? '',
        phone: user.phoneNumber ?? '',
        // You could add a role property to UserModel if needed
      );
    }
  } catch (e) {
    print("Error fetching user data from Firestore: $e");
  }

  // Fallback if Firestore fails or user is a guest
  return UserModel(
    uid: user.uid,
    name: user.isAnonymous ? 'Guest User' : (user.displayName ?? 'ScrapKart User'),
    email: user.email ?? '',
    phone: user.phoneNumber ?? '',
  );
});
