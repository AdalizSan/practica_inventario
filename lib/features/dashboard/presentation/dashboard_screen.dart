import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../../inventory/domain/movement.dart';
import '../../products/presentation/product_form.dart';
import '../../products/presentation/products_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppController>();
    final report = vm.report;
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final entries = _weeklyTotals(days, vm.movements, MovementType.entry);
    final exits = _weeklyTotals(days, vm.movements, MovementType.exit);
    final max = [
      ...entries,
      ...exits,
    ].fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return PageBody(
      children: [
        Reveal(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, d MMMM',
                        'es',
                      ).format(now).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Todo bajo control.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Así se mueve ${vm.profile!.store}.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Reveal(
          delay: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final main = Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'VALOR EN INVENTARIO',
                            style: TextStyle(
                              color: Color(0xFFE5DAFB),
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.north_east,
                          color: Colors.white.withValues(alpha: .6),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        money(context, report.value),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 38,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_outlined,
                          color: Color(0xFFE5DAFB),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${number(report.units)} unidades disponibles',
                            style: const TextStyle(
                              color: Color(0xFFE5DAFB),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Estimación al precio de compra',
                      style: TextStyle(color: Color(0xFFCBB6F2), fontSize: 10),
                    ),
                  ],
                ),
              );
              final stats = Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Productos',
                      value: report.active.length,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: 'Por reponer',
                      value: report.alerts.length,
                      icon: Icons.notification_important_outlined,
                      alert: true,
                    ),
                  ),
                ],
              );
              return constraints.maxWidth > 850
                  ? Row(
                      children: [
                        Expanded(flex: 5, child: main),
                        const SizedBox(width: 18),
                        Expanded(flex: 4, child: stats),
                      ],
                    )
                  : Column(children: [main, const SizedBox(height: 14), stats]);
            },
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: 100,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                label: const Text('Escanear producto'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductForm()),
                ),
                icon: const Icon(Icons.add, size: 19),
                label: const Text('Nuevo producto'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Reveal(
          delay: 150,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    'El ritmo de tu tienda',
                    subtitle: 'Unidades registradas en los últimos 7 días',
                  ),
                  Row(
                    children: [
                      const _Legend('Entradas', AppColors.purple),
                      const SizedBox(width: 20),
                      _Legend(
                        'Salidas',
                        AppColors.purple.withValues(alpha: .25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 175,
                    child: BarChart(
                      BarChartData(
                        maxY: max < 4 ? 4 : max * 1.22,
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    i >= 0 && i < days.length
                                        ? DateFormat('E', 'es').format(days[i])
                                        : '',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(
                          7,
                          (i) => BarChartGroupData(
                            x: i,
                            barsSpace: 5,
                            barRods: [
                              BarChartRodData(
                                toY: entries[i].toDouble(),
                                color: AppColors.purple,
                                width: 12,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              BarChartRodData(
                                toY: exits[i].toDouble(),
                                color: AppColors.purple.withValues(alpha: .25),
                                width: 12,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      duration: Duration(
                        milliseconds: MediaQuery.disableAnimationsOf(context)
                            ? 0
                            : 650,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SectionHeading(
          'Necesitan tu atención',
          subtitle: 'Productos que llegaron a su stock mínimo.',
          action: TextButton(
            onPressed: () => onNavigate(1),
            child: const Text('Ver todos'),
          ),
        ),
        if (report.alerts.isEmpty)
          const Card(
            child: EmptyState(
              title: 'Sin alertas pendientes',
              message: 'Tus productos activos están por encima del mínimo.',
              icon: Icons.task_alt_rounded,
            ),
          ),
        ...report.alerts
            .take(4)
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProductTile(p),
              ),
            ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_pin_outlined, size: 14, color: AppColors.muted),
            SizedBox(width: 6),
            Text(
              'Guardado en este dispositivo',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

List<int> _weeklyTotals(
  List<DateTime> days,
  List<StockMovement> movements,
  MovementType type,
) => days.map((day) {
  return movements
      .where(
        (movement) =>
            movement.type == type &&
            movement.date.year == day.year &&
            movement.date.month == day.month &&
            movement.date.day == day.day,
      )
      .fold<int>(0, (sum, movement) => sum + movement.quantity);
}).toList();

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
  });
  final String label;
  final int value;
  final IconData icon;
  final bool alert;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: alert ? AppColors.amber : AppColors.purple,
            size: 22,
          ),
          const SizedBox(height: 18),
          Text(number(value), style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}
