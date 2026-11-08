import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../overlay_bridge.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToCalibration;

  const DashboardScreen({
    super.key,
    required this.onNavigateToCalibration,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasPermission = false;
  bool _isOverlayRunning = false;
  int _unlockCount = 0;
  String _screenTimeFormatted = '0m 00s';
  String _lastRoast = 'ScreenPet on duty! 🐾';
  Timer? _refreshTimer;
  String _activeAnimation = 'idle';
  Timer? _animResetTimer;

  void _triggerPetAnimation(String animName, [String? dialogue]) {
    _animResetTimer?.cancel();
    setState(() {
      _activeAnimation = animName;
      if (dialogue != null && dialogue.isNotEmpty) {
        _lastRoast = dialogue;
      }
    });

    if (animName != 'idle') {
      _animResetTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) {
          setState(() {
            _activeAnimation = 'idle';
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshState();
    // Periodically update habit counters with live seconds while dashboard is in foreground
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _loadStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshState() async {
    final hasPerm = await OverlayBridge.checkOverlayPermission();
    final isRunning = await OverlayBridge.isOverlayRunning();
    await _loadStats();

    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _isOverlayRunning = isRunning;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await OverlayBridge.getStats();
    if (mounted) {
      setState(() {
        _unlockCount = stats['unlockCount'] as int? ?? 0;
        _screenTimeFormatted = stats['screenTimeFormatted'] as String? ?? '0m 00s';
        _lastRoast = stats['lastRoast'] as String? ?? _lastRoast;
      });
    }
  }

  Future<void> _pokePet() async {
    HapticFeedback.lightImpact();
    const pokeAnims = ['play', 'happy', 'pounce', 'jump'];
    final randomAnim = pokeAnims[DateTime.now().microsecond % pokeAnims.length];
    final newRoast = await OverlayBridge.pokePet();
    if (mounted) {
      _triggerPetAnimation(randomAnim, newRoast);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('😼', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lastRoast,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF0F6FC),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF161B22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleOverlay() async {
    HapticFeedback.lightImpact();
    if (!_hasPermission) {
      await OverlayBridge.requestOverlayPermission();
      // Re-check after user returns from settings
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshState();
      return;
    }

    if (_isOverlayRunning) {
      await OverlayBridge.stopOverlay();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen Pet dismissed from punch-hole.'),
            backgroundColor: Color(0xFF161B22),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      final success = await OverlayBridge.startOverlay();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Screen Pet is now floating beside your punch-hole!'
                  : 'Could not start overlay. Please check permissions.',
            ),
            backgroundColor: const Color(0xFF161B22),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    await _refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshState,
          color: const Color(0xFFFF8C42),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/cat/animations/gifs/idle.gif',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ScreenPet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: Color(0xFFF0F6FC),
                              ),
                            ),
                            Text(
                              'Punch-Hole Digital Companion',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isOverlayRunning
                            ? const Color(0xFF3FB950).withValues(alpha: 0.15)
                            : const Color(0xFFFF8C42).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _isOverlayRunning
                              ? const Color(0xFF3FB950).withValues(alpha: 0.4)
                              : const Color(0xFFFF8C42).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOverlayRunning
                                  ? const Color(0xFF3FB950)
                                  : const Color(0xFFFF8C42),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOverlayRunning ? 'Active on Notch' : 'Tracking in BG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isOverlayRunning
                                  ? const Color(0xFF3FB950)
                                  : const Color(0xFFFF8C42),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Permission Warning Banner (if missing)
                if (!_hasPermission) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261919),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF85149)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF85149), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Overlay Permission Required',
                              style: TextStyle(
                                color: Color(0xFFF85149),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ScreenPet needs system overlay access to draw the companion flush next to your front camera cutout across all apps.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF8B949E), height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await OverlayBridge.requestOverlayPermission();
                            await Future.delayed(const Duration(seconds: 1));
                            await _refreshState();
                          },
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Grant Overlay Access'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF85149),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Hero Pet Controller Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Column(
                    children: [
                      // Interactive Animated Pet Avatar Display
                      GestureDetector(
                        onTap: _pokePet,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFF8C42).withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/cat/animations/gifs/$_activeAnimation.gif',
                              width: 86,
                              height: 86,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Playful Cat Companion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF0F6FC),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOverlayRunning
                            ? 'Floating beside your front camera. Time and unlocks update live every second.'
                            : 'Companion is dismissed from notch, but habit tracking continues in background. Tap below to show it on camera.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B949E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Animation Selector Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAnimPill('🐾 Idle', 'idle'),
                            _buildAnimPill('😸 Happy', 'happy'),
                            _buildAnimPill('👋 Wave', 'wave'),
                            _buildAnimPill('🎾 Play', 'play'),
                            _buildAnimPill('👀 Curious', 'curious'),
                            _buildAnimPill('💤 Sleep', 'sleep'),
                            _buildAnimPill('🎉 Celebrate', 'celebrate'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Spawn / Dismiss Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _toggleOverlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isOverlayRunning
                                ? const Color(0xFF21262D)
                                : const Color(0xFFFF8C42),
                            foregroundColor: _isOverlayRunning
                                ? const Color(0xFFF85149)
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: _isOverlayRunning
                                  ? const BorderSide(color: Color(0xFF30363D))
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            _isOverlayRunning ? 'Dismiss Screen Pet' : 'Spawn Screen Pet',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      if (_isOverlayRunning) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _pokePet,
                            icon: const Icon(Icons.touch_app_rounded, size: 18),
                            label: const Text('Poke Pet (Roast & Animation)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF8C42),
                              side: const BorderSide(color: Color(0xFFFF8C42)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sarcastic Pet Dialogue Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('💬', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PET DIALOGUE & ROAST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF6E7681),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '"$_lastRoast"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF0F6FC),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Habit Statistics Section
                const Text(
                  'TODAY\'S SCREEN HABITS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF6E7681),
                  ),
                ),
                const SizedBox(height: 12),

                // 2-Card Habit Metrics Grid
                Row(
                  children: [
                    // Screen Time Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('⏱', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text(
                                  'Screen-On',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _screenTimeFormatted,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF8C42),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Active usage today',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unlocks Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('🔓', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text(
                                  'Unlocks',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$_unlockCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF0F6FC),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Phone pickups',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF6E7681)),
                    SizedBox(width: 5),
                    Text(
                      'Resets daily after 12:00 AM (Midnight) like a clock',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6E7681), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Calibration Callout Card
                InkWell(
                  onTap: widget.onNavigateToCalibration,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFFFF8C42),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Punch-Hole Alignment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF0F6FC),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Adjust X/Y sliders or snap to camera notch',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8B949E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF8B949E),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimPill(String label, String animKey) {
    final isSelected = _activeAnimation == animKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _triggerPetAnimation(animKey);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF8C42).withValues(alpha: 0.2)
                : const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF8C42) : const Color(0xFF30363D),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFFF8C42) : const Color(0xFFC9D1D9),
            ),
          ),
        ),
      ),
    );
  }
}
