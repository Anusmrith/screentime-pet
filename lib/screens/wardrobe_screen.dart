import 'package:flutter/material.dart';
import '../models/pet_skin.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _selectedSkinId = 'tiger';

  void _showSkinDetails(PetSkin skin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skin Preview Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF21262D),
                  border: Border.all(color: const Color(0xFFFF8C42), width: 2),
                ),
                alignment: Alignment.center,
                child: skin.assetPath != null
                    ? Image.asset(skin.assetPath!, width: 64, height: 64)
                    : Text(skin.emoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 16),

              Text(
                skin.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  skin.rarity,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C42),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                skin.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8B949E),
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
                      setState(() => _selectedSkinId = skin.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${skin.name} is now active on your notch!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_selectedSkinId == skin.id ? 'Equipped' : 'Equip Skin'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'In-App Purchase (${skin.price}): Payment sandbox ready for ${skin.name}!',
                          ),
                          backgroundColor: const Color(0xFF161B22),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Unlock Skin for ${skin.price}'),
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
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1116),
        elevation: 0,
        title: const Text(
          'Pet Wardrobe & Skins',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF0F6FC),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pro Tip / Store Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8C42).withValues(alpha: 0.15),
                      const Color(0xFF161B22),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Your Screen Companion',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF0F6FC),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose unique skins tailored for punch-hole cameras and OLED notch cutouts.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Grid of Pet Skins
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: skins.length,
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  final isEquipped = skin.id == _selectedSkinId;

                  return InkWell(
                    onTap: () => _showSkinDetails(skin),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isEquipped
                              ? const Color(0xFFFF8C42)
                              : const Color(0xFF30363D),
                          width: isEquipped ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Right Status / Lock Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isEquipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C42),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (!skin.isUnlocked)
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 16,
                                  color: Color(0xFF8B949E),
                                ),
                            ],
                          ),

                          // Skin Avatar
                          Expanded(
                            child: Center(
                              child: skin.assetPath != null
                                  ? Image.asset(
                                      skin.assetPath!,
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.contain,
                                    )
                                  : Text(
                                      skin.emoji,
                                      style: TextStyle(
                                        fontSize: 48,
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
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF0F6FC),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Price / State Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? const Color(0xFFFF8C42).withValues(alpha: 0.15)
                                  : const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isEquipped ? 'Equipped' : skin.price,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isEquipped
                                    ? const Color(0xFFFF8C42)
                                    : const Color(0xFF8B949E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
