class DashboardStats {
  final int todayBookings;
  final int yesterdayBookings;

  final double monthlyRevenue;
  final double lastMonthRevenue;

  final int completedBookings;

  final int totalReviews;

  final double averageRating;

  DashboardStats({
    required this.todayBookings,
    required this.yesterdayBookings,
    required this.monthlyRevenue,
    required this.lastMonthRevenue,
    required this.completedBookings,
    required this.totalReviews,
    required this.averageRating,
  });

  factory DashboardStats.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardStats(
      todayBookings:
          json['today_bookings'] ?? 0,

      yesterdayBookings:
          json['yesterday_bookings'] ?? 0,

      monthlyRevenue:
          double.tryParse(
                json['monthly_revenue']
                    .toString(),
              ) ??
              0,

      lastMonthRevenue:
          double.tryParse(
                json['last_month_revenue']
                    .toString(),
              ) ??
              0,

      completedBookings:
          json['completed_bookings'] ?? 0,

      totalReviews:
          json['total_reviews'] ?? 0,

      averageRating:
          double.tryParse(
                json['average_rating']
                    .toString(),
              ) ??
              0,
    );
  }

  // =====================================================
  // TODAY GROWTH
  // =====================================================

  int get todayGrowth =>
      todayBookings - yesterdayBookings;

  // =====================================================
  // REVENUE GROWTH %
  // =====================================================

  double get revenueGrowthPercent {

    if (lastMonthRevenue <= 0) {
      return 0;
    }

    return ((monthlyRevenue -
                lastMonthRevenue) /
            lastMonthRevenue) *
        100;
  }
}