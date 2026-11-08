import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../overlay_bridge.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialCalibration();
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

  void _syncCalibration() {
    OverlayBridge.updateCalibration(
      xPercent: _xPercent,
      yDp: _yDp,
      sizeDp: _sizeDp,
    );
  }

  void _resetToCenter() {
    HapticFeedback.lightImpact();
    setState(() {
      _xPercent = 55.0;
      _yDp = 4;
      _sizeDp = 32;
    });
    _syncCalibration();
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
    _syncCalibration();

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E1116),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1116),
        elevation: 0,
        title: const Text(
          'Punch-Hole Calibration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF0F6FC),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF8C42)),
            tooltip: 'Reset Defaults',
            onPressed: _resetToCenter,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Punch-Hole Simulation Preview Box
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Stack(
                  children: [
                    // Simulated Front Camera Punch-Hole Ring (Center)
                    Align(
                      alignment: const Alignment(0.0, -0.6),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(color: const Color(0x40FFFFFF), width: 1.5),
                        ),
                      ),
                    ),

                    // Live Moving Pet Simulation with companion stats pill
                    Align(
                      alignment: Alignment(
                        ((_xPercent / 50.0) - 1.0).clamp(-1.0, 1.0),
                        ((_yDp / 40.0) - 0.7).clamp(-1.0, 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: _sizeDp.toDouble(),
                            height: _sizeDp.toDouble(),
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/cat/animations/gifs/idle.gif',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xE6161B22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x40FFFFFF)),
                            ),
                            child: const Text(
                              '0m 15s • 3 🔓',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF0F6FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Instruction pill at bottom of preview
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Live preview: pet moves on your phone status bar as you drag',
                          style: TextStyle(fontSize: 10, color: Color(0xFF8B949E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sliders Card Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slider 1: Horizontal Position (X %)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Horizontal Position (X %)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF0F6FC),
                          ),
                        ),
                        Text(
                          '${_xPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF8C42),
                        inactiveTrackColor: const Color(0xFF21262D),
                        thumbColor: const Color(0xFFFF8C42),
                        overlayColor: const Color(0xFFFF8C42).withValues(alpha: 0.2),
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Slider 2: Vertical Offset (Y dp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vertical Offset (Y dp)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF0F6FC),
                          ),
                        ),
                        Text(
                          '$_yDp dp',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF8C42),
                        inactiveTrackColor: const Color(0xFF21262D),
                        thumbColor: const Color(0xFFFF8C42),
                        overlayColor: const Color(0xFFFF8C42).withValues(alpha: 0.2),
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Slider 3: Pet Size (dp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pet Size (dp)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF0F6FC),
                          ),
                        ),
                        Text(
                          '$_sizeDp dp',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF8C42),
                        inactiveTrackColor: const Color(0xFF21262D),
                        thumbColor: const Color(0xFFFF8C42),
                        overlayColor: const Color(0xFFFF8C42).withValues(alpha: 0.2),
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
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reset and Cutout Detection Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetToCenter,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B949E),
                              side: const BorderSide(color: Color(0xFF30363D)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Reset Defaults'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _snapToCutout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF21262D),
                              foregroundColor: const Color(0xFFFF8C42),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFFF8C42), width: 0.8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Snap to Cutout'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Test Poke & Animation on Status Bar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                                      style: const TextStyle(fontSize: 12, color: Color(0xFFF0F6FC)),
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF161B22),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.touch_app_rounded, size: 16),
                        label: const Text('Test Pet Animation & Roast'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8C42),
                          side: const BorderSide(color: Color(0xFFFF8C42), width: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Interactive Touch Tip Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: const Row(
                  children: [
                    Text('👆', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Direct Drag: You can also drag the pet with your finger directly on your phone\'s status bar to position it!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B949E),
                          height: 1.4,
                        ),
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
