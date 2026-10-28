import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../../inventory/domain/movement.dart';
import '../../inventory/presentation/movement_screen.dart';
import '../../reports/data/export_service.dart';
import '../../reports/presentation/history_screen.dart';
import 'product_form.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.productId});
  final String productId;
  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool _exporting = false;
  Future<void> _export(bool print) async {
    setState(() => _exporting = true);
    try {
      final p = context.read<AppController>().product(widget.productId);
      final bytes = await ExportService().label(p);
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'Etiqueta ${p.code}',
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'etiqueta-${p.code.replaceAll(RegExp(r'[^A-Z0-9_-]'), '_')}.pdf',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'No se pudo exportar la etiqueta. Revisa que haya una aplicación para compartir o imprimir.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppController>();
    final p = vm.product(widget.productId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        actions: [
          IconButton(
            tooltip: 'Editar producto',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductForm(product: p)),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: PageBody(
            children: [
              Reveal(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductMark(p, size: 86),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          StockBadge(p),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              if (p.description.isNotEmpty) ...[
                Text(
                  p.description,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Disponibles',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${number(p.stock)} u.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Mínimo: ${p.minimum}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                money(context, p.valuation),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text(
                                'valor estimado',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Compra\n${money(context, p.purchaseCents)}',
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Venta\n${money(context, p.saleCents)}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (p.active)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: MovementType.values
                      .map(
                        (t) => FilledButton.tonalIcon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovementScreen(
                                productId: p.id,
                                initialType: t,
                              ),
                            ),
                          ),
                          icon: Icon(switch (t) {
                            MovementType.entry => Icons.south_west_rounded,
                            MovementType.exit => Icons.north_east_rounded,
                            MovementType.adjustment => Icons.tune_rounded,
                          }, size: 18),
                          label: Text(t.label),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 32),
              const SectionHeading(
                'Una etiqueta. Dos formas de leerla.',
                subtitle: 'Ambos códigos identifican el mismo producto.',
              ),
              Reveal(
                delay: 80,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          p.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: p.code,
                            height: 86,
                            drawText: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.code,
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        QrImageView(data: p.code, size: 160),
                        const SizedBox(height: 8),
                        const Text(
                          'La cantidad se consulta en el inventario.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : () => _export(false),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: Text(_exporting ? 'Preparando…' : 'Compartir PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : () => _export(true),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Imprimir'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Historial del producto'),
                      ),
                      body: HistoryScreen(productId: p.id),
                    ),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Ver movimientos'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: vm.busy
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              p.active
                                  ? '¿Desactivar producto?'
                                  : '¿Reactivar producto?',
                            ),
                            content: Text(
                              p.active
                                  ? 'Se conservarán las existencias y el historial. No podrás registrar movimientos mientras esté inactivo.'
                                  : 'Volverá a aparecer en el catálogo activo.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Confirmar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await vm.setActive(p.id, !p.active);
                          if (context.mounted) {
                            notice(
                              context,
                              p.active
                                  ? 'Producto desactivado.'
                                  : 'Producto reactivado.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            notice(context, AppController.friendly(e));
                          }
                        }
                      },
                child: Text(
                  p.active ? 'Desactivar producto' : 'Reactivar producto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
