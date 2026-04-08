import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────────────────────────────────────

const _kCardRadius = 16.0;
const _kBarColor   = Color(0xFF6366F1);
const _kLineColor  = Color(0xFF2563EB);

const _kMonthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Soft palette for the pie/donut slices
const _kPieColors = [
  Color(0xFF6366F1),
  Color(0xFF22D3EE),
  Color(0xFFFBBF24),
  Color(0xFF34D399),
  Color(0xFFF87171),
  Color(0xFFA78BFA),
];

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper card — every chart section uses this
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Sold Products Bar Chart (Jan – Dec)
// ─────────────────────────────────────────────────────────────────────────────

class SoldProductsBarChart extends StatelessWidget {
  /// 12-element list (Jan → Dec). Shorter lists are padded with 0.
  final List<int> monthlyCounts;
  final int year;

  const SoldProductsBarChart({
    Key? key,
    required this.monthlyCounts,
    this.year = 2026,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure we always have 12 data points
    final data = List<int>.from(monthlyCounts);
    while (data.length < 12) data.add(0);

    final maxY = (data.reduce((a, b) => a > b ? a : b) * 1.25)
        .ceilToDouble()
        .clamp(10.0, double.infinity);

    return _ChartCard(
      title: 'Sold Products in $year',
      child: LayoutBuilder(builder: (ctx, box) {
        final barWidth = ((box.maxWidth - 80) / 12 * 0.55).clamp(6.0, 22.0);
        final chartH = (box.maxWidth * 0.52).clamp(160.0, 260.0);

        return SizedBox(
          height: chartH,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1E293B),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${_kMonthLabels[group.x]}\n${rod.toY.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= 12) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _kMonthLabels[i],
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              barGroups: List.generate(
                12,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].toDouble(),
                      color: _kBarColor,
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Services Donut Chart
// ─────────────────────────────────────────────────────────────────────────────

class ServicesDonutChart extends StatefulWidget {
  /// Map of category label → count. E.g. { "Repair": 42 }
  final Map<String, int> breakdown;

  const ServicesDonutChart({Key? key, required this.breakdown}) : super(key: key);

  @override
  State<ServicesDonutChart> createState() => _ServicesDonutChartState();
}

class _ServicesDonutChartState extends State<ServicesDonutChart> {
  int _touchedIndex = -1;

  static const _kMaxSlices = 6;

  /// Collapses everything after the top-N into "Others".
  List<MapEntry<String, int>> _collapse(List<MapEntry<String, int>> sorted) {
    if (sorted.length <= _kMaxSlices) return sorted;
    final top = sorted.sublist(0, _kMaxSlices);
    final othersTotal =
        sorted.sublist(_kMaxSlices).fold<int>(0, (s, e) => s + e.value);
    return [...top, MapEntry('Others', othersTotal)];
  }

  @override
  Widget build(BuildContext context) {
    // Sort descending so biggest slices come first
    final sorted = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final entries = _collapse(sorted);
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return _ChartCard(
      title: 'Services Breakdown',
      child: LayoutBuilder(builder: (ctx, box) {
        final diameter = (box.maxWidth * 0.65).clamp(160.0, 210.0);

        return Column(
          children: [
            SizedBox(
              height: diameter,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: diameter * 0.28,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = (event.isInterestedForInteractions &&
                                response?.touchedSection != null)
                            ? response!.touchedSection!.touchedSectionIndex
                            : -1;
                      });
                    },
                  ),
                  sections: List.generate(entries.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final pct = total > 0
                        ? (entries[i].value / total * 100).toStringAsFixed(1)
                        : '0';
                    return PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      color: _kPieColors[i % _kPieColors.length],
                      radius: isTouched ? diameter * 0.40 : diameter * 0.34,
                      title: '$pct%',
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 13 : 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            // Legend
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _kPieColors[i % _kPieColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entries[i].key}  (${entries[i].value})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Top Products Horizontal Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class TopProductsChart extends StatelessWidget {
  /// List of up to 5 maps: [{"name": "...", "count": 42}, ...]
  final List<Map<String, dynamic>> products;

  const TopProductsChart({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = products.take(5).toList();
    if (data.isEmpty) {
      return _ChartCard(
        title: 'Top 5 Best-Selling Products',
        child: const SizedBox(
          height: 80,
          child: Center(
            child: Text('No data yet.',
                style: TextStyle(color: Colors.black38, fontSize: 13)),
          ),
        ),
      );
    }

    final maxCount = data
        .map((e) {
          final raw = e['count'];
          return raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
        })
        .reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Top 5 Best-Selling Products',
      child: Column(
        children: List.generate(data.length, (i) {
          final name = (data[i]['name'] ?? '').toString();
          final rawCount = data[i]['count'];
          final count = rawCount is num ? rawCount.toDouble() : double.tryParse(rawCount.toString()) ?? 0.0;
          final pct = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(builder: (ctx, box) {
                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: box.maxWidth * pct,
                        decoration: BoxDecoration(
                          color: _kPieColors[i % _kPieColors.length],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Client Growth Line Chart (Jan – Dec)
// ─────────────────────────────────────────────────────────────────────────────

class ClientGrowthLineChart extends StatelessWidget {
  /// 12-element list (Jan → Dec). Shorter lists are padded with 0.
  final List<int> monthlyCounts;
  final int year;

  const ClientGrowthLineChart({
    Key? key,
    required this.monthlyCounts,
    this.year = 2026,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = List<int>.from(monthlyCounts);
    while (data.length < 12) data.add(0);

    final maxY = (data.reduce((a, b) => a > b ? a : b) * 1.3)
        .ceilToDouble()
        .clamp(5.0, double.infinity);

    final spots = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), data[i].toDouble()),
    );

    return _ChartCard(
      title: 'Client Growth in $year',
      child: LayoutBuilder(builder: (ctx, box) {
        final chartH = (box.maxWidth * 0.45).clamp(130.0, 200.0);

        return SizedBox(
          height: chartH,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1E293B),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${_kMonthLabels[s.x.toInt()]}: ${s.y.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ))
                      .toList(),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= 12 || i % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _kMonthLabels[i],
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: _kLineColor,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: _kLineColor,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _kLineColor.withOpacity(0.18),
                        _kLineColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
