import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/animated_blob_background.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../profile/profile_screen.dart';
import '../booking/bookings_list_screen.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onProfileTap: () => setState(() => _currentIndex = 3),
        onScanTap: () => setState(() => _currentIndex = 1),
      ),
      const ScanScreen(),
      BookingsListScreen(
        onNewBookingTap: () => setState(() => _currentIndex = 1),
      ),
      ProfileScreen(
        onOrderHistoryTap: () => setState(() => _currentIndex = 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const AnimatedBlobBackground(child: SizedBox.expand()),
          
          // Current Screen
          SafeArea(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.tertiary,
        child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, semanticLabel: 'Open AI Chatbot'),
        onPressed: () => context.push('/chatbot'),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.5),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded, semanticLabel: 'Home Tab'), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.document_scanner, semanticLabel: 'Scan Tab'), label: 'Scan'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded, semanticLabel: 'Orders Tab'), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded, semanticLabel: 'Profile Tab'), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
