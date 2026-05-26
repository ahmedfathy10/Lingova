import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/admin_user.dart';
import '../../data/services/admin_api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  final AdminSession session;

  const AdminDashboardPage({super.key, required this.session});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _service = AdminApiService();
  AdminDashboardPeriod _period = AdminDashboardPeriod.day;
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<AdminStats> _loadStats() {
    return _service.getStats(widget.session.token, period: _period);
  }

  void _refresh() {
    setState(() => _statsFuture = _loadStats());
  }

  void _setPeriod(AdminDashboardPeriod period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<AdminStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _DashboardError(message: 'تعذر تحميل بيانات الداشبورد.'),
              ],
            );
          }

          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            children: [
              _DashboardHeader(
                period: _period,
                rangeDescription: stats.period.rangeDescription,
                onPeriodChanged: _setPeriod,
                onRefresh: _refresh,
              ),
              const SizedBox(height: 20),
              _KpiGrid(
                items: [
                  _KpiItem(
                    title: 'الطلاب',
                    value: stats.studentsCount,
                    icon: Icons.school_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  _KpiItem(
                    title: 'تسجيلات الكورسات',
                    value: stats.courseRegistrationsCount,
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _KpiItem(
                    title: 'إيراد الفترة',
                    value: _sumSeries(stats.charts.revenue),
                    icon: Icons.payments_rounded,
                    color: AppColors.orange,
                    formatter: _money,
                  ),
                  _KpiItem(
                    title: 'فتح التطبيق',
                    value: _sumSeries(stats.charts.appOpens),
                    icon: Icons.mobile_friendly_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _KpiItem(
                    title: 'طلاب جدد',
                    value: _sumSeries(stats.charts.newStudents),
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                  _KpiItem(
                    title: 'فاتحين الآن',
                    value: stats.activity.activeNowCount,
                    icon: Icons.online_prediction_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                  _KpiItem(
                    title: 'طلبات اشتراك معلقة',
                    value: stats.overview.pendingSubscriptions,
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _KpiItem(
                    title: 'محاولات امتحان',
                    value: _sumSeries(stats.charts.examAttempts),
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _RevenueSummaryStrip(stats: stats),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final revenueChart = _ChartPanel(
                    title: 'تطور الإيرادات',
                    subtitle: 'المبالغ المحصلة (${stats.period.label})',
                    height: 280,
                    child: _AreaLineChart(
                      points: stats.charts.revenue,
                      lineColor: AppColors.orange,
                      formatValue: _money,
                    ),
                  );
                  final activityChart = _ChartPanel(
                    title: 'نشاط المستخدمين',
                    subtitle: 'فتح التطبيق مقابل الطلاب الجدد',
                    height: 280,
                    child: _MultiLineChart(
                      series: [
                        _ChartSeriesConfig(
                          label: 'فتح التطبيق',
                          points: stats.charts.appOpens,
                          color: const Color(0xFF8B5CF6),
                        ),
                        _ChartSeriesConfig(
                          label: 'طلاب جدد',
                          points: stats.charts.newStudents,
                          color: const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: revenueChart),
                        const SizedBox(width: 16),
                        Expanded(child: activityChart),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      revenueChart,
                      const SizedBox(height: 16),
                      activityChart,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _ChartPanel(
                title: 'التعلم والمشاركة',
                subtitle: 'تسجيلات، مشاهدات، امتحانات، ومجتمع',
                height: 330,
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 6,
                      children: const [
                        _ChartLegendDot(
                          label: 'تسجيل كورس',
                          color: Color(0xFF10B981),
                        ),
                        _ChartLegendDot(
                          label: 'مشاهدة',
                          color: Color(0xFF3B82F6),
                        ),
                        _ChartLegendDot(
                          label: 'امتحان',
                          color: Color(0xFFEF4444),
                        ),
                        _ChartLegendDot(
                          label: 'مجتمع',
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _GroupedBarChart(
                        groups: [
                          _BarGroupConfig(
                            label: 'تسجيل كورس',
                            points: stats.charts.enrollments,
                            color: const Color(0xFF10B981),
                          ),
                          _BarGroupConfig(
                            label: 'مشاهدة',
                            points: stats.charts.watchSessions,
                            color: const Color(0xFF3B82F6),
                          ),
                          _BarGroupConfig(
                            label: 'امتحان',
                            points: stats.charts.examAttempts,
                            color: const Color(0xFFEF4444),
                          ),
                          _BarGroupConfig(
                            label: 'مجتمع',
                            points: stats.charts.communityPosts,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final languagePanel = _ChartPanel(
                    title: 'اللغات المختارة',
                    subtitle: 'توزيع اهتمام الطلاب',
                    height: 280,
                    child: _LanguagePieChart(
                      data: stats.registrationsByLanguage,
                    ),
                  );
                  final subscriptionsPanel = _ChartPanel(
                    title: 'طلبات الاشتراك',
                    subtitle: 'الطلبات الواردة خلال الفترة',
                    height: 280,
                    child: _SimpleBarChart(
                      points: stats.charts.subscriptionRequests,
                      barColor: const Color(0xFFF59E0B),
                    ),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: languagePanel),
                        const SizedBox(width: 16),
                        Expanded(child: subscriptionsPanel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      languagePanel,
                      const SizedBox(height: 16),
                      subscriptionsPanel,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _TopCoursesPanel(rows: stats.revenue.byCourse),
              const SizedBox(height: 16),
              _PlatformOverviewPanel(overview: stats.overview, stats: stats),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AdminDashboardPeriod period;
  final String rangeDescription;
  final ValueChanged<AdminDashboardPeriod> onPeriodChanged;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.period,
    required this.rangeDescription,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'لوحة المراقبة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'متابعة شاملة للمنصة — $rangeDescription',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: AdminDashboardPeriod.values.map((item) {
            final selected = item == period;
            return ChoiceChip(
              label: Text(item.label),
              selected: selected,
              onSelected: (_) => onPeriodChanged(item),
              selectedColor: AppColors.orange.withValues(alpha: 0.22),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.orange : AppColors.textMuted,
              ),
              side: BorderSide(
                color: selected ? AppColors.orange : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _KpiItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String Function(int value)? formatter;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.formatter,
  });

  String get displayValue => formatter?.call(value) ?? value.toString();
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiItem> items;

  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 4
            : width >= 860
            ? 3
            : width >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _DashboardCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.displayValue,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RevenueSummaryStrip extends StatelessWidget {
  final AdminStats stats;

  const _RevenueSummaryStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('اليوم', stats.revenue.today),
      ('الشهر', stats.revenue.month),
      ('السنة', stats.revenue.year),
      ('الإجمالي', stats.revenue.total),
    ];
    return _DashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 4 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 72,
            ),
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _money(tile.$2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'إيراد ${tile.$1}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final Widget child;

  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _ChartSeriesConfig {
  final String label;
  final List<AdminChartPoint> points;
  final Color color;

  const _ChartSeriesConfig({
    required this.label,
    required this.points,
    required this.color,
  });
}

class _AreaLineChart extends StatelessWidget {
  final List<AdminChartPoint> points;
  final Color lineColor;
  final String Function(int value)? formatValue;

  const _AreaLineChart({
    required this.points,
    required this.lineColor,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((point) => point.value == 0)) {
      return const _ChartEmptyState();
    }

    final maxY = _maxValue(points, min: 1).toDouble();
    final spots = _toSpots(points);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                _compactNumber(value.toInt()),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (points.length / 5).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[index].label,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final value = spot.y.toInt();
              final label = formatValue?.call(value) ?? value.toString();
              return LineTooltipItem(
                label,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiLineChart extends StatelessWidget {
  final List<_ChartSeriesConfig> series;

  const _MultiLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final hasData = series.any(
      (item) => item.points.any((point) => point.value > 0),
    );
    if (!hasData) {
      return const _ChartEmptyState();
    }

    final maxY = series
        .map((item) => _maxValue(item.points))
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 6,
          children: series
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      _compactNumber(value.toInt()),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (series.first.points.length / 5)
                        .ceilToDouble()
                        .clamp(1, 999),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final points = series.first.points;
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        points[index].label,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: series
                  .map(
                    (item) => LineChartBarData(
                      spots: _toSpots(item.points),
                      isCurved: true,
                      color: item.color,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarGroupConfig {
  final String label;
  final List<AdminChartPoint> points;
  final Color color;

  const _BarGroupConfig({
    required this.label,
    required this.points,
    required this.color,
  });
}

class _GroupedBarChart extends StatelessWidget {
  final List<_BarGroupConfig> groups;

  const _GroupedBarChart({required this.groups});

  @override
  Widget build(BuildContext context) {
    final length = groups.firstOrNull?.points.length ?? 0;
    if (length == 0) {
      return const _ChartEmptyState();
    }

    final maxY = groups
        .expand((group) => group.points)
        .map((point) => point.value)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                _compactNumber(value.toInt()),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (length / 5).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final label = groups.first.points[index].label;
                return Text(
                  label,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              for (final group in groups)
                BarChartRodData(
                  toY: group.points[index].value.toDouble(),
                  width: 5,
                  color: group.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<AdminChartPoint> points;
  final Color barColor;

  const _SimpleBarChart({required this.points, required this.barColor});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((point) => point.value == 0)) {
      return const _ChartEmptyState();
    }

    final maxY = _maxValue(points, min: 1).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                _compactNumber(value.toInt()),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 5).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  points[index].label,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(points.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: points[index].value.toDouble(),
                color: barColor,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LanguagePieChart extends StatelessWidget {
  final Map<String, int> data;

  const _LanguagePieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartEmptyState();
    }

    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    final colors = [
      AppColors.orange,
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];
                final color = colors[index % colors.length];
                final percent = total == 0 ? 0.0 : entry.value / total;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  color: color,
                  title: '${(percent * 100).round()}%',
                  radius: 58,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((entry) {
              final index = entries.indexOf(entry);
              final color = colors[index % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        entry.key,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TopCoursesPanel extends StatelessWidget {
  final List<AdminCourseRevenue> rows;

  const _TopCoursesPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    final topRows = rows.take(6).toList();
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أعلى الكورسات إيرادًا',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (topRows.isEmpty)
            Text(
              'لا توجد مشتريات مدفوعة حتى الآن.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...topRows.map((row) {
              final maxAmount = topRows.first.collectedAmount;
              final progress = maxAmount == 0
                  ? 0.0
                  : row.collectedAmount / maxAmount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          _money(row.collectedAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Text(
                            '${row.courseLanguage} — ${row.courseTitle}',
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceHigh,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PlatformOverviewPanel extends StatelessWidget {
  final AdminDashboardOverview overview;
  final AdminStats stats;

  const _PlatformOverviewPanel({
    required this.overview,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('الكورسات', stats.coursesCount, Icons.menu_book_rounded),
      ('الكتب', overview.booksCount, Icons.library_books_rounded),
      ('المفردات', overview.vocabularyCount, Icons.translate_rounded),
      ('الامتحانات', overview.examsCount, Icons.fact_check_rounded),
      ('نجاح الامتحانات', overview.passedExamAttempts, Icons.verified_rounded),
      ('المجتمع', overview.communityPostsCount, Icons.forum_rounded),
      ('مشاهدات', overview.watchProgressCount, Icons.play_circle_rounded),
      ('محادثات الدعم', overview.supportConversationsCount, Icons.support_agent_rounded),
      ('سجل النشاط', overview.activityLogsCount, Icons.history_rounded),
      ('اشتراكات معتمدة', overview.approvedSubscriptions, Icons.verified_user_rounded),
      ('حسابات موقوفة', stats.suspendedUsersCount, Icons.block_rounded),
      ('نشطون الآن', stats.activity.activeNowCount, Icons.sensors_rounded),
    ];

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'نظرة على المنصة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 3
                  : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 78,
                ),
                itemBuilder: (context, index) {
                  final tile = tiles[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tile.$3, size: 18, color: AppColors.orange),
                        const Spacer(),
                        Text(
                          tile.$2.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          tile.$1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartLegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا توجد بيانات كافية في هذه الفترة.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  const _DashboardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
      ),
    );
  }
}

List<FlSpot> _toSpots(List<AdminChartPoint> points) {
  return List.generate(
    points.length,
    (index) => FlSpot(index.toDouble(), points[index].value.toDouble()),
  );
}

int _maxValue(List<AdminChartPoint> points, {int min = 0}) {
  if (points.isEmpty) return min == 0 ? 1 : min;
  final max = points.map((point) => point.value).fold<int>(0, (a, b) => a > b ? a : b);
  return max < min ? min : max;
}

int _sumSeries(List<AdminChartPoint> points) {
  return points.fold<int>(0, (sum, point) => sum + point.value);
}

String _money(num value) => '${value.toStringAsFixed(0)} ج.م';

String _compactNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}
