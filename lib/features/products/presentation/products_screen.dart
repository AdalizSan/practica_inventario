import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../domain/product.dart';
import 'product_detail.dart';
import 'product_form.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '', _status = 'Activos';
  String? _category;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppController>();
    final products = vm.products
        .where(
          (p) =>
              (p.name.toLowerCase().contains(_query.toLowerCase()) ||
                  p.code.toLowerCase().contains(_query.toLowerCase())) &&
              (_category == null || p.category == _category) &&
              switch (_status) {
                'Activos' => p.active,
                'Stock bajo' => p.lowStock,
                'Inactivos' => !p.active,
                _ => true,
              },
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Tu catálogo',
                  subtitle:
                      '${vm.report.active.length} productos activos · ${vm.categories.length} categorías',
                  action: FilledButton.icon(
                    key: const ValueKey('new_product'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductForm()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo'),
                  ),
                ),
                TextField(
                  key: const ValueKey('product_search'),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Activos', 'Stock bajo', 'Inactivos', 'Todos']
                      .map(
                        (s) => ChoiceChip(
                          label: Text(s),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...vm.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 24),
                Text(
                  '${products.length} resultados',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              title: 'Aquí empieza el orden',
              message: 'Registra un producto o prueba con otros filtros.',
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          sliver: SliverList.separated(
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => ProductTile(products[index]),
          ),
        ),
      ],
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile(this.product, {super.key});
  final Product product;
  @override
  Widget build(BuildContext context) => OpenContainer(
    transitionDuration: Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
    ),
    closedElevation: 0,
    openElevation: 0,
    closedColor: Colors.white,
    closedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    openBuilder: (_, _) => ProductDetail(productId: product.id),
    closedBuilder: (context, open) => InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProductMark(product),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.code} · ${product.category}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StockBadge(product),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  number(product.stock),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'unidades',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  money(context, product.saleCents),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
