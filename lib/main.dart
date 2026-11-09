import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/botanical_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/wardrobe_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: BotanicalTheme.canvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BubblooApp());
}

class BubblooApp extends StatelessWidget {
  const BubblooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubbloo',
      debugShowCheckedModeBanner: false,
      theme: BotanicalTheme.themeData,
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
    HapticFeedback.selectionClick();
    if (index == 2) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: BotanicalTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wardrobe is coming soon! Stay tuned for cozy seasonal outfits!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: BotanicalTheme.textMain,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: BotanicalTheme.butter,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: BotanicalTheme.butterBorder),
          ),
        ),
      );
    }
    setState(() => _currentIndex = index);
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToIndex(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? BotanicalTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: BotanicalTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? BotanicalTheme.onPrimary
                    : BotanicalTheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? BotanicalTheme.onPrimary
                        : BotanicalTheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: BotanicalTheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: BotanicalTheme.floatingTrayShadow,
          ),
          child: Row(
            children: [
              _buildTabItem(0, Icons.auto_awesome_rounded, 'Dashboard'),
              _buildTabItem(1, Icons.tune_rounded, 'Calibration'),
              _buildTabItem(2, Icons.lock_outline_rounded, 'Wardrobe'),
            ],
          ),
        ),
      ),
    );
  }
}
