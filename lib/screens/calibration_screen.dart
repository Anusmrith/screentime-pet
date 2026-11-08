import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../overlay_bridge.dart';
import '../theme/botanical_theme.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  double _xPercent = 55.0;
  int _yDp = 4;
  int _sizeDp = 32;
  bool _isLoading = true;
  Timer? _syncDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialCalibration();
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialCalibration() async {
    final values = await OverlayBridge.getCalibration();
    if (mounted) {
      setState(() {
        _xPercent = (values['xPercent'] as num?)?.toDouble() ?? 55.0;
        _yDp = (values['yDp'] as num?)?.toInt() ?? 4;
        _sizeDp = (values['sizeDp'] as num?)?.toInt() ?? 32;
        _isLoading = false;
      });
    }
  }

  /// Debounces rapid slider movements to prevent flooding the platform IPC channel.
  void _syncCalibration({bool immediate = false}) {
    if (immediate) {
      _syncDebounceTimer?.cancel();
      OverlayBridge.updateCalibration(
        xPercent: _xPercent,
        yDp: _yDp,
        sizeDp: _sizeDp,
      );
      return;
    }

    if (_syncDebounceTimer?.isActive ?? false) return;
    _syncDebounceTimer = Timer(const Duration(milliseconds: 35), () {
      OverlayBridge.updateCalibration(
        xPercent: _xPercent,
        yDp: _yDp,
        sizeDp: _sizeDp,
      );
    });
  }

  void _resetToCenter() {
    HapticFeedback.lightImpact();
    setState(() {
      _xPercent = 55.0;
      _yDp = 4;
      _sizeDp = 32;
    });
    _syncCalibration(immediate: true);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to standard center punch-hole defaults'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _snapToCutout() async {
    HapticFeedback.mediumImpact();
    final result = await OverlayBridge.detectCutout();
    final detected = result['detected'] as bool? ?? false;
    final targetX = (result['xPercent'] as num?)?.toDouble() ?? 52.0;
    final targetY = (result['yDp'] as num?)?.toInt() ?? 8;

    setState(() {
      _xPercent = targetX;
      _yDp = targetY;
    });
    _syncCalibration(immediate: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          detected
              ? 'Snapped adjacent to front camera cutout!'
              : 'Cutout not reported; aligned to top center',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPetWidget(double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        'assets/cat/animations/gifs/idle.gif',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBadgeWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BotanicalTheme.butter,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: BotanicalTheme.butterBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        '0m 15s • 3 🔓',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: BotanicalTheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BotanicalTheme.canvas,
        body: Center(
          child: CircularProgressIndicator(color: BotanicalTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BotanicalTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Card Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BotanicalTheme.surface,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                  border: Border.all(
                    color: BotanicalTheme.outline.withValues(alpha: 0.5),
                  ),
                  boxShadow: BotanicalTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: BotanicalTheme.butter,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: BotanicalTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Punch-Hole Calibration',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: BotanicalTheme.textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Align your pet around camera lens',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: BotanicalTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: BotanicalTheme.primary),
                      tooltip: 'Reset Defaults',
                      onPressed: _resetToCenter,
                      style: IconButton.styleFrom(
                        backgroundColor: BotanicalTheme.canvas,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Live Notch Simulator Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: BotanicalTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LIVE NOTCH SIMULATOR',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: BotanicalTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: BotanicalTheme.butter,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: BotanicalTheme.butterBorder,
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Hardware Overlay v1.4',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: BotanicalTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dark Viewport in Deep Forest Evergreen (Glitch-free, clipped & dynamically oriented)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          color: BotanicalTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            final expandToLeft = _xPercent > 70.0;
                            final size = _sizeDp.toDouble().clamp(20.0, 56.0);
                            const totalBadgeW = 76.0;
                            final totalContentW = size + 4.0 + totalBadgeW;

                            // Calculate coordinate matching PetOverlayService
                            final petCenterTargetX = w * (_xPercent / 100.0);
                            final petTopTargetY = (_yDp * 1.0).clamp(4.0, (h - size - 6.0).clamp(4.0, h));

                            final double groupLeft;
                            if (expandToLeft) {
                              // [Badge] [Pet]
                              groupLeft = (petCenterTargetX - totalContentW + size / 2)
                                  .clamp(4.0, (w - totalContentW - 4.0).clamp(4.0, w));
                            } else {
                              // [Pet] [Badge]
                              groupLeft = (petCenterTargetX - size / 2)
                                  .clamp(4.0, (w - totalContentW - 4.0).clamp(4.0, w));
                            }

                            return Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // Center Camera Cutout Ring
                                Positioned(
                                  left: (w * 0.5) - 8,
                                  top: 10,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(
                                        color: BotanicalTheme.butter.withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Moving Pet + Badge Group
                                Positioned(
                                  left: groupLeft,
                                  top: petTopTargetY,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: expandToLeft
                                        ? [
                                            _buildBadgeWidget(),
                                            const SizedBox(width: 4),
                                            _buildPetWidget(size),
                                          ]
                                        : [
                                            _buildPetWidget(size),
                                            const SizedBox(width: 4),
                                            _buildBadgeWidget(),
                                          ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: BotanicalTheme.textMuted,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Live preview: pet moves on your phone status bar as you drag',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: BotanicalTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Precision Alignment Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BotanicalTheme.surface,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
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
                        Icon(Icons.tune_rounded, size: 19, color: BotanicalTheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Precision Alignment',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: BotanicalTheme.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Slider 1: Horizontal Position (X %)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Horizontal Position (X %)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BotanicalTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: BotanicalTheme.butter,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: BotanicalTheme.butterBorder),
                          ),
                          child: Text(
                            '${_xPercent.round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: BotanicalTheme.primary,
                        inactiveTrackColor: BotanicalTheme.surfaceContainer,
                        thumbColor: BotanicalTheme.primary,
                        overlayColor: BotanicalTheme.primary.withValues(alpha: 0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      ),
                      child: Slider(
                        value: _xPercent,
                        min: 0.0,
                        max: 100.0,
                        divisions: 100,
                        onChanged: (val) {
                          setState(() => _xPercent = val);
                          _syncCalibration();
                        },
                        onChangeEnd: (val) {
                          _syncCalibration(immediate: true);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Slider 2: Vertical Offset (Y dp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Vertical Offset (Y dp)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BotanicalTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: BotanicalTheme.butter,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: BotanicalTheme.butterBorder),
                          ),
                          child: Text(
                            '$_yDp dp',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: BotanicalTheme.primary,
                        inactiveTrackColor: BotanicalTheme.surfaceContainer,
                        thumbColor: BotanicalTheme.primary,
                        overlayColor: BotanicalTheme.primary.withValues(alpha: 0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      ),
                      child: Slider(
                        value: _yDp.toDouble(),
                        min: 0.0,
                        max: 80.0,
                        divisions: 80,
                        onChanged: (val) {
                          setState(() => _yDp = val.round());
                          _syncCalibration();
                        },
                        onChangeEnd: (val) {
                          _syncCalibration(immediate: true);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Slider 3: Pet Size (dp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Pet Size (dp)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BotanicalTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: BotanicalTheme.butter,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: BotanicalTheme.butterBorder),
                          ),
                          child: Text(
                            '$_sizeDp dp',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: BotanicalTheme.primary,
                        inactiveTrackColor: BotanicalTheme.surfaceContainer,
                        thumbColor: BotanicalTheme.primary,
                        overlayColor: BotanicalTheme.primary.withValues(alpha: 0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      ),
                      child: Slider(
                        value: _sizeDp.toDouble(),
                        min: 20.0,
                        max: 56.0,
                        divisions: 36,
                        onChanged: (val) {
                          setState(() => _sizeDp = val.round());
                          _syncCalibration();
                        },
                        onChangeEnd: (val) {
                          _syncCalibration(immediate: true);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reset and Cutout Detection Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetToCenter,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BotanicalTheme.primary,
                              side: const BorderSide(color: BotanicalTheme.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restart_alt_rounded, size: 16),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Reset Defaults',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _snapToCutout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BotanicalTheme.butter,
                              foregroundColor: BotanicalTheme.primary,
                              elevation: 1,
                              side: const BorderSide(color: BotanicalTheme.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.adjust_rounded, size: 16),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Snap to Cutout',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Test Poke & Animation on Status Bar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final roast = await OverlayBridge.pokePet();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text('🐾', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      roast ?? 'Pet animated on status bar!',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: BotanicalTheme.textMain,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: BotanicalTheme.butter,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: BotanicalTheme.butterBorder),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BotanicalTheme.primary,
                          foregroundColor: BotanicalTheme.onPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 17),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Test Pet Animation & Roast',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Interactive Touch Tip Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BotanicalTheme.surface,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
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
                      child: const Center(
                        child: Text('👆', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Direct Drag',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.textMain,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You can also drag the pet with your finger directly on your phone\'s status bar to position it!',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: BotanicalTheme.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
