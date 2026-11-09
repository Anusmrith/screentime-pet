class PetSkin {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final String rarity;
  final String price;
  final bool isUnlocked;
  final String? assetPath;

  const PetSkin({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.rarity,
    required this.price,
    this.isUnlocked = false,
    this.assetPath,
  });

  static const List<PetSkin> defaultSkins = [
    PetSkin(
      id: 'cat',
      name: 'Bubbloo',
      subtitle: 'Your animated screen-time companion',
      emoji: '🐱',
      rarity: 'Active Companion',
      price: 'FREE',
      isUnlocked: true,
      assetPath: 'assets/cat/animations/gifs/idle.gif',
    ),
    PetSkin(
      id: 'midnight_cat',
      name: 'Midnight Shadow',
      subtitle: 'Sleek black cat that blends into OLED notches',
      emoji: '🐈‍⬛',
      rarity: 'Rare Skin',
      price: '\$0.99',
      isUnlocked: false,
    ),
    PetSkin(
      id: 'cyber_feline',
      name: 'Cyber Neo-Cat',
      subtitle: 'Glitch effects and neon status aura',
      emoji: '🤖',
      rarity: 'Epic Skin',
      price: '\$1.49',
      isUnlocked: false,
    ),
    PetSkin(
      id: 'cozy_panda',
      name: 'Cozy Panda',
      subtitle: 'Calm and collected, reminds you to breathe',
      emoji: '🐼',
      rarity: 'Rare Skin',
      price: '\$0.99',
      isUnlocked: false,
    ),
    PetSkin(
      id: 'fennec_fox',
      name: 'Fennec Fox',
      subtitle: 'Big ears tuned to notification overload',
      emoji: '🦊',
      rarity: 'Epic Skin',
      price: '\$1.49',
      isUnlocked: false,
    ),
    PetSkin(
      id: 'mystic_dragon',
      name: 'Astral Dragon',
      subtitle: 'Spits miniature digital embers when screen time is high',
      emoji: '🐲',
      rarity: 'Legendary Skin',
      price: '\$2.99',
      isUnlocked: false,
    ),
  ];
}

