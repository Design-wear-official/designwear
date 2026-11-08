/// Names of brands, clubs, leagues and celebrities other people own (Nike, Puma, Real Madrid...). Entertainment
/// names (films, shows, games, comics) are allowed, so they are not listed here. A snapshot of the API's built-in
/// BRANDS list (designwear-backend `src/ip_guard.js`), used only to stop a studio design with such a name being
/// published. The API stays the authority (it also checks every AI prompt); keep this in step with it.
const protectedNames = <String>[
  'nike',
  'adidas',
  'puma',
  'reebok',
  'under armour',
  'new balance',
  'jordan brand',
  'supreme',
  'off white',
  'gucci',
  'louis vuitton',
  'chanel',
  'prada',
  'balenciaga',
  'versace',
  'burberry',
  'hermes',
  'dior',
  'fendi',
  'ralph lauren',
  'tommy hilfiger',
  'calvin klein',
  'levis',
  'lacoste',
  'the north face',
  'champion brand',
  'bape',
  'yeezy',
  'coca cola',
  'pepsi',
  'red bull',
  'monster energy',
  'mcdonalds',
  'starbucks',
  'kfc',
  'amul',
  'maggi',
  'ferrari',
  'lamborghini',
  'porsche',
  'bmw',
  'mercedes benz',
  'tesla',
  'harley davidson',
  'royal enfield',
  'apple logo',
  'google logo',
  'microsoft',
  'amazon prime',
  'netflix',
  'spotify',
  'youtube logo',
  'tiktok',
  'rolex',
  'lego',
  'hot wheels',
  'rolling stones',
  'metallica',
  'bts',
  'blackpink',
  'taylor swift',
  'beyonce',
  'real madrid',
  'fc barcelona',
  'manchester united',
  'manchester city',
  'liverpool fc',
  'chelsea fc',
  'arsenal fc',
  'juventus',
  'bayern munich',
  'psg',
  'fifa',
  'uefa',
  'premier league',
  'la liga',
  'nba',
  'nfl',
  'nhl',
  'mlb',
  'wwe',
  'ufc',
  'olympics',
  'ipl',
  'bcci',
  'chennai super kings',
  'csk',
  'mumbai indians',
  'rcb',
  'royal challengers',
  'kolkata knight riders',
  'sunrisers hyderabad',
  'delhi capitals',
  'rajasthan royals',
  'team india jersey',
];

const _leet = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '7': 't',
  '@': 'a',
  r'$': 's',
  '!': 'i',
};
const _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
};

/// Lower case, accents removed, look-alike digits/symbols mapped, everything else a single space.
String normaliseForNames(String value) {
  final b = StringBuffer();
  for (final ch in value.toLowerCase().split('')) {
    final c = _accents[ch] ?? _leet[ch] ?? ch;
    b.write(RegExp(r'[a-z]').hasMatch(c) ? c : ' ');
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _terms = {
  for (final n in protectedNames)
    if (normaliseForNames(n).length >= 3) normaliseForNames(n),
};

/// The protected name found in [text], or null. Whole words always count; a spaced-out or joined
/// spelling ("s p i d e r m a n") counts only for terms of 7+ letters, so short words stay safe ("thor"
/// in "author"). Mirrors the API's guard.
String? protectedNameIn(String text) {
  final t = normaliseForNames(text);
  final spaced = ' $t ';
  final squashed = t.replaceAll(' ', '');
  for (final term in _terms) {
    if (spaced.contains(' $term ')) return term;
    if (term.length >= 7 && squashed.contains(term.replaceAll(' ', ''))) {
      return term;
    }
  }
  return null;
}

/// The protected name in anything a design prints as text: its name, text and sticker elements.
String? protectedNameInDesign(String name, Iterable<String> texts) {
  for (final s in [name, ...texts]) {
    final hit = protectedNameIn(s);
    if (hit != null) return hit;
  }
  return null;
}

const protectedNameMessage =
    'That is someone else’s trademark or character, which DesignWear cannot print without a licence. '
    'Change the name or text to something original and try again.';
