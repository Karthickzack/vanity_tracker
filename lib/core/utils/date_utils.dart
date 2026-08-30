class VanityDateUtils {
  /// Calculates expiry date given opened date and PAO in months.
  /// Example: Opened Jan 15 with 12 months PAO -> Expiry Jan 15 of next year.
  static DateTime calculateExpiryDate(DateTime openedDate, int paoMonths) {
    var year = openedDate.year;
    var month = openedDate.month + paoMonths;
    var day = openedDate.day;

    while (month > 12) {
      year += 1;
      month -= 12;
    }

    // Handle month length variations (e.g. Feb 29, 30, 31)
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInMonth) {
      day = daysInMonth;
    }

    return DateTime(year, month, day, openedDate.hour, openedDate.minute);
  }

  /// Calculates remaining days until expiry from reference date (default: today midnight)
  static int calculateDaysRemaining(DateTime expiryDate, [DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  /// Calculate cost per day used
  static double? calculateCostPerDay(double? price, DateTime? openedDate, DateTime? finishedDate) {
    if (price == null || price <= 0 || openedDate == null) return null;
    final end = finishedDate ?? DateTime.now();
    final days = end.difference(openedDate).inDays;
    final totalDays = days <= 0 ? 1 : days;
    return price / totalDays;
  }

  /// Categorizes urgency:
  /// - 'green' (Active): > 30 days
  /// - 'amber' (Expiring Soon): 0 to 30 days
  /// - 'red' (Expired): < 0 days
  /// - 'unopened' (Not Opened Yet)
  static String getUrgencyCategory(DateTime? openedDate, DateTime? expiryDate, [DateTime? fromDate]) {
    if (openedDate == null || expiryDate == null) {
      return 'unopened';
    }
    final days = calculateDaysRemaining(expiryDate, fromDate);
    if (days < 0) return 'red';
    if (days <= 30) return 'amber';
    return 'green';
  }
}
