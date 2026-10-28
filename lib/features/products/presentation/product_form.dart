import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../domain/product.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product});
  final Product? product;
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  late final String _id;
  final _fields = List.generate(8, (_) => TextEditingController());
  String? _photo;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _id = p?.id ?? const Uuid().v4();
    final values = [
      p?.name ?? '',
      p?.code ?? '',
      p?.category ?? '',
      p?.description ?? '',
      p == null ? '' : (p.purchaseCents / 100).toStringAsFixed(2),
      p == null ? '' : (p.saleCents / 100).toStringAsFixed(2),
      p?.minimum.toString() ?? '5',
      '0',
    ];
    for (var i = 0; i < values.length; i++) {
      _fields[i].text = values[i];
    }
    _photo = p?.photo;
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 2000000) {
        notice(context, 'Selecciona una fotografía de menos de 2 MB.');
        return;
      }
      setState(() => _photo = base64Encode(bytes));
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'No se pudo abrir la fotografía. Revisa los permisos de fotos.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    int cents(String value) {
      final parts = value.replaceAll(',', '.').split('.');
      return int.parse(parts[0]) * 100 +
          int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
    }

    final p = Product(
      id: _id,
      code: _fields[1].text.trim().toUpperCase(),
      name: _fields[0].text.trim(),
      category: _fields[2].text.trim(),
      description: _fields[3].text.trim(),
      purchaseCents: cents(_fields[4].text.trim()),
      saleCents: cents(_fields[5].text.trim()),
      minimum: int.parse(_fields[6].text),
      photo: _photo,
    );
    try {
      await context.read<AppController>().saveProduct(
        p,
        widget.product == null ? int.parse(_fields[7].text) : 0,
      );
      if (!mounted) return;
      Navigator.pop(context);
      notice(
        context,
        widget.product == null ? 'Producto registrado.' : 'Cambios guardados.',
      );
    } catch (e) {
      if (mounted) notice(context, AppController.friendly(e));
    }
  }

  Widget _field(
    int i,
    String label, {
    bool decimal = false,
    bool integer = false,
    int lines = 1,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('product_field_$i'),
      controller: _fields[i],
      maxLines: lines,
      maxLength: maxLength,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : integer
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (i == 3) return null;
        if (v.isEmpty) return 'Completa este campo.';
        if (decimal && !RegExp(r'^\d{1,7}([.,]\d{1,2})?$').hasMatch(v)) {
          return 'Escribe un precio válido con hasta 2 decimales.';
        }
        if (integer &&
            (int.tryParse(v) == null ||
                int.parse(v) < 0 ||
                int.parse(v) > 1000000000)) {
          return 'Usa un entero entre 0 y 1,000,000,000.';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppController>().categories;
    return FormPage(
      title: widget.product == null ? 'Nuevo producto' : 'Editar producto',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(
              'Un lugar en tu inventario',
              subtitle:
                  'Define el producto. Sus existencias tendrán su propio historial.',
            ),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photo == null
                      ? const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: AppColors.purple,
                        )
                      : Image.memory(base64Decode(_photo!), fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: _pick,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Elegir fotografía'),
                      ),
                      if (_photo != null)
                        TextButton(
                          onPressed: () => setState(() => _photo = null),
                          child: const Text('Quitar foto'),
                        ),
                      const Text(
                        'Opcional · hasta 2 MB',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _field(0, 'Nombre del producto', maxLength: 100),
            _field(1, 'Código único', maxLength: 48),
            _field(2, 'Categoría', maxLength: 50),
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: categories
                      .map(
                        (c) => ActionChip(
                          label: Text(c),
                          onPressed: () => setState(() => _fields[2].text = c),
                        ),
                      )
                      .toList(),
                ),
              ),
            _field(3, 'Descripción (opcional)', lines: 3, maxLength: 500),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field(4, 'Precio de compra', decimal: true)),
                const SizedBox(width: 16),
                Expanded(child: _field(5, 'Precio de venta', decimal: true)),
              ],
            ),
            _field(6, 'Stock mínimo', integer: true),
            if (widget.product == null) ...[
              _field(7, 'Existencias iniciales', integer: true),
              const Text(
                'Si ingresas existencias, se registrará una entrada inicial para conservar su trazabilidad.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
            BusyButton(
              label: widget.product == null
                  ? 'Registrar producto'
                  : 'Guardar cambios',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
