import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';

/// Donut chart + legend of expenses per category.
class ExpenseDonut extends StatelessWidget {
  const ExpenseDonut({super.key, required this.data});

  final Map<UiCategory, int> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int total = data.values.fold(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    sections: [
                      for (final e in data.entries)
                        PieChartSectionData(
                          value: e.value.toDouble(),
                          color: e.key.color,
                          radius: 16,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'هزینه',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      '${PersianFormat.digits('${(total / 10000000).round()}')} میلیون',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final e in data.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key.name, style: theme.textTheme.bodySmall)),
                        Text(
                          PersianFormat.digits('${(e.value * 100 / total).round()}%'),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
