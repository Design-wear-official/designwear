class HomeBanner {
  final String id;
  final String badge;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String ctaAction; // 'shop' | 'design' | 'deal'
  final String ctaColor;  // 'purple' | 'blue' | 'orange'
  final String imageUrl;
  final int order;

  const HomeBanner({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaAction,
    required this.ctaColor,
    required this.imageUrl,
    required this.order,
  });

  factory HomeBanner.fromMap(Map<String, dynamic> map) => HomeBanner(
    id: map['_id'] as String? ?? '',
    badge: map['badge'] as String? ?? '',
    title: map['title'] as String? ?? '',
    subtitle: map['subtitle'] as String? ?? '',
    ctaLabel: map['ctaLabel'] as String? ?? 'SHOP NOW',
    ctaAction: map['ctaAction'] as String? ?? 'shop',
    ctaColor: map['ctaColor'] as String? ?? 'purple',
    imageUrl: map['imageUrl'] as String? ?? '',
    order: (map['order'] as num?)?.toInt() ?? 0,
  );

  // Hardcoded fallbacks used until Sanity content is published
  static const List<Map<String, Object>> fallbackRaw = [
    {
      'id': 'fallback_1', 'badge': 'NEW COLLECTION',
      'title': 'Signature Style,\nPremium Comfort',
      'subtitle': 'Explore handcrafted apparel for the modern wardrobe.',
      'ctaLabel': 'SHOP NOW', 'ctaAction': 'shop', 'ctaColor': 'purple',
      'imageUrl': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
      'order': 1,
    },
    {
      'id': 'fallback_2', 'badge': 'DESIGN STUDIO',
      'title': 'Design Your\nOwn Style',
      'subtitle': 'Create unique custom apparel that speaks for you.',
      'ctaLabel': 'START CREATING', 'ctaAction': 'design', 'ctaColor': 'blue',
      'imageUrl': 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
      'order': 2,
    },
    {
      'id': 'fallback_3', 'badge': 'FLASH SALE',
      'title': 'Up to 50% Off\nToday Only',
      'subtitle': 'Limited-time deals on premium collections.',
      'ctaLabel': 'GRAB DEAL', 'ctaAction': 'deal', 'ctaColor': 'orange',
      'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=2069&auto=format&fit=crop',
      'order': 3,
    },
  ];

  static List<HomeBanner> get fallbacks => fallbackRaw
      .map((m) => HomeBanner(
            id: m['id'] as String,
            badge: m['badge'] as String,
            title: m['title'] as String,
            subtitle: m['subtitle'] as String,
            ctaLabel: m['ctaLabel'] as String,
            ctaAction: m['ctaAction'] as String,
            ctaColor: m['ctaColor'] as String,
            imageUrl: m['imageUrl'] as String,
            order: m['order'] as int,
          ))
      .toList();
}
