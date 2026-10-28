/// A weekly design challenge, as served by the API.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.entries,
    required this.open,
  });

  final String id, title, description;
  final DateTime startsAt, endsAt;
  final int entries;
  final bool open;

  factory Challenge.fromJson(Map<String, Object?> j) => Challenge(
    id: '${j['id']}',
    title: '${j['title']}',
    description: '${j['description'] ?? ''}',
    startsAt: DateTime.parse('${j['startsAt']}').toLocal(),
    endsAt: DateTime.parse('${j['endsAt']}').toLocal(),
    entries: (j['entries'] as num?)?.toInt() ?? 0,
    open: j['open'] == true,
  );

  /// "ends in 3 days", "ends in 5 hours", "ends in 20 minutes" or "ended".
  String timeLeft(DateTime now) {
    final left = endsAt.difference(now);
    if (left.isNegative || left == Duration.zero) return 'ended';
    if (left.inDays >= 1) {
      final days = (left.inHours / 24).ceil();
      return 'ends in $days ${days == 1 ? 'day' : 'days'}';
    }
    if (left.inHours >= 1) {
      return 'ends in ${left.inHours} ${left.inHours == 1 ? 'hour' : 'hours'}';
    }
    final mins = left.inMinutes < 1 ? 1 : left.inMinutes;
    return 'ends in $mins ${mins == 1 ? 'minute' : 'minutes'}';
  }

  /// "⑂ 248 entries · ends in 3 days"
  String summary(DateTime now) =>
      '⑂ $entries ${entries == 1 ? 'entry' : 'entries'} · ${timeLeft(now)}';
}
