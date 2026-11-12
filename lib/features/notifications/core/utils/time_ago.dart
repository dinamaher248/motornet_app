/// Arabic relative time formatter (e.g. منذ ساعتين).
String formatTimeAgoAr(DateTime? dateTime) {
  if (dateTime == null) return '';

  final now = DateTime.now();
  final diff = now.difference(dateTime.toLocal());

  if (diff.inSeconds < 45) return 'الآن';
  if (diff.inMinutes < 1) return 'منذ لحظات';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return 'منذ دقيقة';
    if (m == 2) return 'منذ دقيقتين';
    if (m >= 3 && m <= 10) return 'منذ $m دقائق';
    return 'منذ $m دقيقة';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return 'منذ ساعة';
    if (h == 2) return 'منذ ساعتين';
    if (h >= 3 && h <= 10) return 'منذ $h ساعات';
    return 'منذ $h ساعة';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    if (d == 1) return 'منذ يوم';
    if (d == 2) return 'منذ يومين';
    if (d >= 3 && d <= 10) return 'منذ $d أيام';
    return 'منذ $d يوم';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    if (w == 1) return 'منذ أسبوع';
    if (w == 2) return 'منذ أسبوعين';
    return 'منذ $w أسابيع';
  }

  final months = (diff.inDays / 30).floor();
  if (months < 12) {
    if (months <= 1) return 'منذ شهر';
    if (months == 2) return 'منذ شهرين';
    return 'منذ $months أشهر';
  }

  final years = (diff.inDays / 365).floor();
  if (years <= 1) return 'منذ سنة';
  if (years == 2) return 'منذ سنتين';
  return 'منذ $years سنوات';
}
