import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../domain/movement.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({
    super.key,
    required this.productId,
    this.initialType = MovementType.entry,
  });
  final String productId;
  final MovementType initialType;
  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  late MovementType _type = widget.initialType;
  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<AppController>();
    final request = MovementRequest(
      productId: widget.productId,
      type: _type,
      quantity: int.parse(_quantity.text),
      reason: _reason.text.trim(),
      responsible: vm.profile!.responsible,
    );
    try {
      final after = CalculateStock()(vm.product(widget.productId), request);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmar ${_type.label.toLowerCase()}'),
          content: Text(
            'Las existencias quedarán en $after unidades.\n\nEl movimiento se conservará en el historial. Para corregirlo tendrás que registrar otro movimiento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Revisar'),
            ),
            FilledButton(
              key: const ValueKey('confirm_movement'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await vm.record(request);
      if (!mounted) return;
      Navigator.pop(context);
      notice(context, '${_type.label} registrada. Existencias actualizadas.');
    } catch (e) {
      if (mounted) notice(context, AppController.friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppController>();
    final p = vm.product(widget.productId);
    final quantity = int.tryParse(_quantity.text);
    final next = quantity == null
        ? p.stock
        : switch (_type) {
            MovementType.entry => p.stock + quantity,
            MovementType.exit => p.stock - quantity,
            MovementType.adjustment => quantity,
          };
    return FormPage(
      title: 'Registrar movimiento',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProductMark(p, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        p.code,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SegmentedButton<MovementType>(
              showSelectedIcon: false,
              segments: MovementType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXISTENCIAS ACTUALES',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          number(p.stock),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.purple,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DESPUÉS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: Duration(
                            milliseconds:
                                MediaQuery.disableAnimationsOf(context)
                                ? 0
                                : 250,
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: Text(
                            number(next),
                            key: ValueKey(next),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: next < 0
                                      ? Colors.red.shade700
                                      : AppColors.purple,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('movement_quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _type == MovementType.adjustment
                    ? 'Cantidad contada físicamente'
                    : 'Cantidad de unidades',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null ||
                        n < 0 ||
                        (n == 0 && _type != MovementType.adjustment)
                    ? 'Escribe una cantidad válida.'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const ValueKey('movement_reason'),
              controller: _reason,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _type == MovementType.adjustment
                    ? 'Justificación del ajuste'
                    : 'Motivo del movimiento',
                hintText: _type == MovementType.entry
                    ? 'Compra, devolución…'
                    : _type == MovementType.exit
                    ? 'Venta, daño…'
                    : 'Explica la diferencia encontrada',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'El motivo es obligatorio.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Responsable: ${vm.profile!.responsible}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            BusyButton(label: 'Revisar y confirmar', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
