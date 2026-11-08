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
  String _selectedSkinId = 'cat';

  void _showSkinDetails(PetSkin skin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BotanicalTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skin Preview Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BotanicalTheme.butter,
                  border: Border.all(color: BotanicalTheme.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: skin.assetPath != null
                    ? Image.asset(skin.assetPath!, width: 68, height: 68)
                    : Text(skin.emoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 16),

              Text(
                skin.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: BotanicalTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BotanicalTheme.butter,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: BotanicalTheme.butterBorder),
                ),
                child: Text(
                  skin.rarity,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: BotanicalTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                skin.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: BotanicalTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              if (skin.isUnlocked) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedSkinId = skin.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${skin.name} is now active on your notch!'),
                          backgroundColor: BotanicalTheme.primary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BotanicalTheme.primary,
                      foregroundColor: BotanicalTheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      _selectedSkinId == skin.id ? 'Equipped' : 'Equip Skin',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'In-App Purchase (${skin.price}): Payment sandbox ready for ${skin.name}!',
                          ),
                          backgroundColor: BotanicalTheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BotanicalTheme.butter,
                      foregroundColor: BotanicalTheme.primary,
                      side: const BorderSide(color: BotanicalTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      'Unlock Skin for ${skin.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skins = PetSkin.defaultSkins;

    return Scaffold(
      backgroundColor: BotanicalTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner & Gem Balance Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pet Wardrobe & Skins',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: BotanicalTheme.textMain,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Tap any cozy friend to dress up your notch',
                        style: TextStyle(
                          fontSize: 12,
                          color: BotanicalTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
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
                        Text('💎', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          '320 Gems',
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

              // Soft Creamy Pastel Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BotanicalTheme.butter,
                  borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                  border: Border.all(color: BotanicalTheme.butterBorder),
                  boxShadow: BotanicalTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: BotanicalTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Your Screen Companion',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: BotanicalTheme.textMain,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose unique skins tailored for punch-hole cameras and OLED notch cutouts.',
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

              const SizedBox(height: 16),

              // Grid of Pet Skins
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
                  final isEquipped = skin.id == _selectedSkinId;

                  return InkWell(
                    onTap: () => _showSkinDetails(skin),
                    borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: BotanicalTheme.surface,
                        borderRadius: BorderRadius.circular(BotanicalTheme.radiusLg),
                        border: Border.all(
                          color: isEquipped
                              ? BotanicalTheme.primary
                              : BotanicalTheme.outline.withValues(alpha: 0.5),
                          width: isEquipped ? 2 : 1,
                        ),
                        boxShadow: BotanicalTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Right Status / Lock Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BotanicalTheme.canvas,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pets_rounded,
                                        size: 10, color: BotanicalTheme.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      isEquipped ? 'Notch Hug' : skin.rarity.split(' ').first,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: BotanicalTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isEquipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BotanicalTheme.butter,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: BotanicalTheme.butterBorder),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: BotanicalTheme.primary,
                                    ),
                                  ),
                                )
                              else if (!skin.isUnlocked)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: BotanicalTheme.canvas,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: BotanicalTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),

                          // Skin Avatar
                          Expanded(
                            child: Center(
                              child: skin.assetPath != null
                                  ? Image.asset(
                                      skin.assetPath!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    )
                                  : Text(
                                      skin.emoji,
                                      style: TextStyle(
                                        fontSize: 46,
                                        color: skin.isUnlocked
                                            ? null
                                            : Colors.grey.withValues(alpha: 0.5),
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

                          // Price / State Pill Button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? BotanicalTheme.primary
                                  : BotanicalTheme.butter,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isEquipped
                                    ? BotanicalTheme.primary
                                    : BotanicalTheme.butterBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isEquipped ? '✓ Equipped' : skin.price,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isEquipped
                                      ? BotanicalTheme.onPrimary
                                      : BotanicalTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Bottom Indie Support Note
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
                      'All purchases support cozy indie updates & seasonal skins!',
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
