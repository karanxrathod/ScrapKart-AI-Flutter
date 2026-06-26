import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/scan/prediction_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/donate/donate_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final initialData = state.extra as Map<String, dynamic>?;
          return BookingScreen(initialData: initialData);
        },
      ),
      GoRoute(
        path: '/prediction',
        builder: (context, state) {
          final scanResult = state.extra as Map<String, dynamic>?;
          return PredictionScreen(scanResult: scanResult);
        },
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) {
          final bookingId = state.uri.queryParameters['id'];
          return TrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/donate',
        builder: (context, state) => const DonateScreen(),
      ),
      // Future routes will be added here
    ],
  );
}
