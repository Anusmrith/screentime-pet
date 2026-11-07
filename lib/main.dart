import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/wardrobe_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0E1116),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ScreenPetApp());
}

class ScreenPetApp extends StatelessWidget {
  const ScreenPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenPet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8C42),
          secondary: Color(0xFF3FB950),
          surface: Color(0xFF161B22),
          error: Color(0xFFF85149),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToCalibration: () => _navigateToIndex(1),
      ),
      const CalibrationScreen(),
      const WardrobeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF21262D), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateToIndex,
          backgroundColor: const Color(0xFF161B22),
          indicatorColor: const Color(0xFFFF8C42).withValues(alpha: 0.18),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFFFF8C42)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFFFF8C42)),
              label: 'Calibration',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded, color: Color(0xFFFF8C42)),
              label: 'Wardrobe',
            ),
          ],
        ),
      ),
    );
  }
}
