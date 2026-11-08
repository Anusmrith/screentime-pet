import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pet_skin.dart';
import '../theme/botanical_theme.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  void _showComingSoonToast([String? skinName]) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: BotanicalTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                skinName != null
                    ? '$skinName is coming soon! Stay tuned!'
                    : 'Wardrobe is coming soon! Stay tuned for cozy seasonal outfits!',
                style: const TextStyle(
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

  void _showActiveCatToast() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.pets_rounded, size: 18, color: BotanicalTheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Playful Cat is currently active on your screen!',
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

  @override
  Widget build(BuildContext context) {
    final skins = PetSkin.defaultSkins;

    return Scaffold(
      backgroundColor: BotanicalTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pet Wardrobe & Skins',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: BotanicalTheme.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Custom companion skins & outfits',
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BotanicalTheme.butter,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: BotanicalTheme.butterBorder),
                      boxShadow: [
                        BoxShadow(
                          color: BotanicalTheme.primary.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: BotanicalTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: BotanicalTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Locked Hero Callout Banner
              InkWell(
                onTap: () => _showComingSoonToast(),
                borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BotanicalTheme.butter,
                    borderRadius: BorderRadius.circular(BotanicalTheme.radiusXl),
                    border: Border.all(color: BotanicalTheme.butterBorder),
                    boxShadow: BotanicalTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_rounded, size: 24, color: BotanicalTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wardrobe Coming Soon!',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: BotanicalTheme.textMain,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'We\'re tailoring cozy companion outfits and OLED notch cutouts. Check back in an upcoming update!',
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
              ),

              const SizedBox(height: 16),

              // Section Label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'COMPANION SKINS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: BotanicalTheme.textMain,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Grid of Pet Skins (Playful Cat highlighted; other skins previewed)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: skins.length,
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  final isCurrentCat = skin.id == 'cat';

                  return InkWell(
                    onTap: () => isCurrentCat
                        ? _showActiveCatToast()
                        : _showComingSoonToast(skin.name),
                    borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: BotanicalTheme.surface,
                        borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                        border: Border.all(
                          color: isCurrentCat
                              ? BotanicalTheme.primary
                              : BotanicalTheme.outline.withValues(alpha: 0.5),
                          width: isCurrentCat ? 2 : 1,
                        ),
                        boxShadow: isCurrentCat
                            ? [
                                BoxShadow(
                                  color: BotanicalTheme.primary.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : BotanicalTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Status Tag (Active badge for Playful Cat, lock for others)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrentCat
                                      ? BotanicalTheme.primary
                                      : BotanicalTheme.canvas,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  isCurrentCat ? 'ACTIVE' : skin.rarity.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrentCat
                                        ? BotanicalTheme.onPrimary
                                        : BotanicalTheme.primary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isCurrentCat
                                      ? BotanicalTheme.butter
                                      : BotanicalTheme.canvas,
                                  shape: BoxShape.circle,
                                  border: isCurrentCat
                                      ? Border.all(color: BotanicalTheme.butterBorder)
                                      : null,
                                ),
                                child: Icon(
                                  isCurrentCat
                                      ? Icons.check_rounded
                                      : Icons.lock_rounded,
                                  size: isCurrentCat ? 13 : 12,
                                  color: isCurrentCat
                                      ? BotanicalTheme.primary
                                      : BotanicalTheme.textMuted,
                                ),
                              ),
                            ],
                          ),

                          // Skin Avatar (highlighted / full opacity for current cat)
                          Expanded(
                            child: Center(
                              child: Opacity(
                                opacity: isCurrentCat ? 1.0 : 0.75,
                                child: skin.assetPath != null
                                    ? Image.asset(
                                        skin.assetPath!,
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.contain,
                                      )
                                    : Text(
                                        skin.emoji,
                                        style: const TextStyle(fontSize: 44),
                                      ),
                              ),
                            ),
                          ),

                          Text(
                            skin.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Bottom Button: "Current Pet" for Playful Cat, "Coming Soon" with lock for others
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isCurrentCat
                                  ? BotanicalTheme.butter
                                  : BotanicalTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isCurrentCat
                                    ? BotanicalTheme.butterBorder
                                    : BotanicalTheme.outline.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCurrentCat
                                      ? Icons.pets_rounded
                                      : Icons.lock_rounded,
                                  size: 11,
                                  color: isCurrentCat
                                      ? BotanicalTheme.primary
                                      : BotanicalTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCurrentCat ? 'Current Pet' : 'Coming Soon',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isCurrentCat ? FontWeight.w800 : FontWeight.w700,
                                    color: isCurrentCat
                                        ? BotanicalTheme.primary
                                        : BotanicalTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Bottom Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: BotanicalTheme.surface,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusMd),
                  border: Border.all(
                    color: BotanicalTheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checkroom_rounded,
                        size: 16, color: BotanicalTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Wardrobe & custom skins are coming soon!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: BotanicalTheme.textMuted,
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
