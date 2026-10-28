import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../../inventory/domain/movement.dart';
import '../data/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.productId});
  final String? productId;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String? _product = widget.productId;
  MovementType? _type;
  DateTimeRange? _range;
  bool _exporting = false;
  Future<void> _export() async {
    setState(() => _exporting = true);
    final vm = context.read<AppController>();
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? const Rect.fromLTWH(0, 0, 100, 100)
          : box.localToGlobal(Offset.zero) & box.size;
      await ExportService().shareInventory(
        vm.report,
        vm.profile!.currency,
        origin,
      );
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'No se pudo exportar. Inténtalo de nuevo y elige una aplicación para guardar el archivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppController>();
    final rows = vm.report.filter(
      productId: _product,
      type: _type,
      from: _range?.start,
      to: _range?.end,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Cada unidad tiene una historia',
                  subtitle:
                      'Entradas, salidas y conteos. Sin perder el rastro.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VALOR DEL INVENTARIO ACTIVO',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          money(context, vm.report.value),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Estimación: existencias × precio de compra registrado.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (vm.report.dormantValue > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Productos inactivos: ${money(context, vm.report.dormantValue)} adicionales.',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _exporting
                                ? 'Preparando…'
                                : 'Exportar inventario CSV',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _product,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Producto'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los productos'),
                    ),
                    ...vm.products.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _product = v),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _type == null,
                      onSelected: (_) => setState(() => _type = null),
                    ),
                    ...MovementType.values.map(
                      (t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final first = vm.movements.isEmpty
                            ? DateTime(now.year - 1)
                            : DateTime(vm.movements.last.date.year - 1);
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: first,
                          lastDate: DateTime(now.year + 1),
                          initialDateRange: _range,
                          helpText: 'Filtrar movimientos por fecha',
                        );
                        if (range != null && mounted) {
                          setState(() => _range = range);
                        }
                      },
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        _range == null
                            ? 'Todas las fechas'
                            : '${DateFormat('dd/MM/yy').format(_range!.start)} – ${DateFormat('dd/MM/yy').format(_range!.end)}',
                      ),
                    ),
                    if (_range != null)
                      IconButton(
                        tooltip: 'Quitar filtro de fechas',
                        onPressed: () => setState(() => _range = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${rows.length} movimientos',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              title: 'Aún no hay movimientos aquí',
              message:
                  'Registra una entrada o cambia los filtros para consultar el historial.',
              icon: Icons.history_rounded,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => MovementTile(rows[i]),
          ),
        ),
      ],
    );
  }
}

class MovementTile extends StatelessWidget {
  const MovementTile(this.movement, {super.key});
  final StockMovement movement;
  @override
  Widget build(BuildContext context) {
    final m = movement;
    final color = m.type == MovementType.entry
        ? AppColors.green
        : m.type == MovementType.exit
        ? AppColors.amber
        : AppColors.purple;
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            m.type == MovementType.entry
                ? Icons.south_west_rounded
                : m.type == MovementType.exit
                ? Icons.north_east_rounded
                : Icons.tune_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          m.productName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${m.type.label} · ${DateFormat('dd MMM, HH:mm', 'es').format(m.date)}',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        trailing: Text(
          '${m.delta > 0 ? '+' : ''}${m.delta}',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                Text(m.reason),
                const SizedBox(height: 8),
                Text(
                  '${m.before} → ${m.after} unidades · ${m.responsible}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  '${m.productCode} · ${DateFormat('dd/MM/yyyy HH:mm:ss').format(m.date)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
