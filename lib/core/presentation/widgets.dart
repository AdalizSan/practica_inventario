import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../features/products/domain/product.dart';
import 'app_controller.dart';
import 'theme.dart';

String money(BuildContext context, int cents) => NumberFormat.currency(
  locale: 'es_GT',
  name: context.read<AppController>().profile?.currency ?? 'GTQ',
  decimalDigits: 2,
).format(cents / 100);
String number(int value) => NumberFormat.decimalPattern('es_GT').format(value);
void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : child
            .animate()
            .fadeIn(duration: 400.ms, delay: delay.ms)
            .slideY(
              begin: .035,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: AppColors.purple),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class ProductMark extends StatelessWidget {
  const ProductMark(this.product, {super.key, this.size = 52});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.lavender,
      borderRadius: BorderRadius.circular(size * .26),
    ),
    clipBehavior: Clip.antiAlias,
    child: product.photo != null
        ? Image.memory(
            base64Decode(product.photo!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.image_not_supported_outlined),
          )
        : Icon(
            Icons.inventory_2_outlined,
            color: AppColors.purple,
            size: size * .43,
          ),
  );
}

class StockBadge extends StatelessWidget {
  const StockBadge(this.product, {super.key});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final color = !product.active
        ? AppColors.muted
        : product.lowStock
        ? AppColors.amber
        : AppColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        !product.active
            ? 'Inactivo'
            : product.stock == 0
            ? 'Agotado'
            : product.lowStock
            ? 'Stock bajo'
            : 'Disponible',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 32),
    children: children,
  );
}

class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.check_rounded,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AppController>().busy;
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 19),
      label: Text(busy ? 'Guardando…' : label),
    );
  }
}
