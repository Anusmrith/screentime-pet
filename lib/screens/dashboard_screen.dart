import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../overlay_bridge.dart';
import '../theme/botanical_theme.dart';

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
      backgroundColor: BotanicalTheme.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshState,
          color: BotanicalTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BotanicalTheme.primary.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BotanicalTheme.primary.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            size: 20,
                            color: BotanicalTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'ScreenPet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: BotanicalTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: BotanicalTheme.butter,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: BotanicalTheme.butterBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BotanicalTheme.primary.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
                                  ? BotanicalTheme.primary
                                  : const Color(0xFFC47B2B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOverlayRunning ? 'ACTIVE' : 'BG TRACKING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: _isOverlayRunning
                                  ? BotanicalTheme.primary
                                  : const Color(0xFF8A5214),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Permission Warning Banner (if missing)
                if (!_hasPermission) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFB4A9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFBA1A1A), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Overlay Permission Required',
                              style: TextStyle(
                                color: Color(0xFFBA1A1A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ScreenPet needs system overlay access to draw the companion flush next to your front camera cutout across all apps.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF410002),
                            height: 1.4,
                          ),
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
                            backgroundColor: const Color(0xFFBA1A1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Top Companion Stage Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(
                    color: BotanicalTheme.surface,
                    borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                    border: Border.all(
                      color: BotanicalTheme.outline.withValues(alpha: 0.5),
                    ),
                    boxShadow: BotanicalTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Pet Cushion Bed & Animated Sprite Stage
                      GestureDetector(
                        onTap: _pokePet,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Gentle floating snooze puffs if companion is resting
                            if (!_isOverlayRunning)
                              const Positioned(
                                top: -6,
                                right: -4,
                                child: Text(
                                  'z Z z',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: BotanicalTheme.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            // Soft Butter sleeping cushion pad
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 140,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: BotanicalTheme.butter,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: BotanicalTheme.butterBorder.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                            // Pet Animated Character Sprite
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Image.asset(
                                'assets/cat/animations/gifs/$_activeAnimation.gif',
                                width: 96,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Playful Cat Companion',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: BotanicalTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOverlayRunning
                            ? 'Floating beside your front camera. Time and unlocks update live every second.'
                            : 'Companion is resting. Tap below to spawn it by your punch-hole.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BotanicalTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Spawn / Dismiss Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _toggleOverlay,
                          icon: Icon(
                            _isOverlayRunning
                                ? Icons.pause_circle_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _isOverlayRunning
                                ? 'Dismiss Screen Pet'
                                : 'Spawn Screen Pet',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BotanicalTheme.primary,
                            foregroundColor: BotanicalTheme.onPrimary,
                            elevation: 2,
                            shadowColor: BotanicalTheme.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      if (_isOverlayRunning) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _pokePet,
                            icon: const Icon(Icons.touch_app_rounded, size: 17),
                            label: const Text('Poke Pet (Roast & Animation)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BotanicalTheme.primary,
                              side: BorderSide(
                                color: BotanicalTheme.primary.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Pet Dialogue & Roast Card (Soft Butter Pod)
                InkWell(
                  onTap: _pokePet,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      color: BotanicalTheme.butter,
                      borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                      border: Border.all(
                        color: BotanicalTheme.butterBorder.withValues(alpha: 0.8),
                      ),
                      boxShadow: BotanicalTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_rounded,
                              size: 15,
                              color: BotanicalTheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'PET DIALOGUE & ROAST',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: BotanicalTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$_lastRoast"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BotanicalTheme.textMain,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Screen Habits Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'TODAY\'S SCREEN HABITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: BotanicalTheme.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 2-Column Game Stat Cards
                Row(
                  children: [
                    // Screen Time Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BotanicalTheme.surface,
                          borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                          border: Border.all(
                            color: BotanicalTheme.outline.withValues(alpha: 0.5),
                          ),
                          boxShadow: BotanicalTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 17, color: BotanicalTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Screen-On',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: BotanicalTheme.textMain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _screenTimeFormatted,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: BotanicalTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Active usage today',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: BotanicalTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Unlocks Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BotanicalTheme.surface,
                          borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                          border: Border.all(
                            color: BotanicalTheme.outline.withValues(alpha: 0.5),
                          ),
                          boxShadow: BotanicalTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_open_rounded,
                                    size: 17, color: BotanicalTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Unlocks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: BotanicalTheme.textMain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_unlockCount',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: BotanicalTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Phone pickups',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: BotanicalTheme.textMuted,
                              ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: BotanicalTheme.textMuted),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Resets daily after 12:00 AM (Midnight) like a clock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: BotanicalTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Punch-Hole Alignment Navigation Card
                InkWell(
                  onTap: widget.onNavigateToCalibration,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: BotanicalTheme.surface,
                      borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                      border: Border.all(
                        color: BotanicalTheme.outline.withValues(alpha: 0.5),
                      ),
                      boxShadow: BotanicalTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: BotanicalTheme.butter,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: BotanicalTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Punch-Hole Alignment',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: BotanicalTheme.textMain,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Adjust X/Y sliders or snap to camera notch',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BotanicalTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: BotanicalTheme.canvas,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: BotanicalTheme.primary,
                            size: 16,
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _triggerPetAnimation(animKey);
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? BotanicalTheme.butter
                : BotanicalTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? BotanicalTheme.butterBorder
                  : BotanicalTheme.outline.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: BotanicalTheme.textMain,
            ),
          ),
        ),
      ),
    );
  }
}
