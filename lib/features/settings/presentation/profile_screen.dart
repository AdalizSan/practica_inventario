import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../domain/profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _store = TextEditingController();
  final _responsible = TextEditingController();
  String _currency = 'GTQ';
  bool _demo = true;
  @override
  void initState() {
    super.initState();
    final profile = context.read<AppController>().profile;
    _store.text = profile?.store ?? '';
    _responsible.text = profile?.responsible ?? '';
    _currency = profile?.currency ?? 'GTQ';
  }

  @override
  void dispose() {
    _store.dispose();
    _responsible.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<AppController>();
    final profile = Profile(
      store: _store.text.trim(),
      responsible: _responsible.text.trim(),
      currency: _currency,
    );
    try {
      if (widget.onboarding) {
        await vm.setup(profile, _demo);
      } else {
        await vm.saveProfile(profile);
      }
      if (!mounted) return;
      if (!widget.onboarding) Navigator.pop(context);
      notice(context, 'Tu espacio está listo.');
    } catch (e) {
      if (mounted) notice(context, AppController.friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) => FormPage(
    title: widget.onboarding ? 'Trazal / Inventario' : 'Tu espacio',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.all_inbox_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.onboarding
                        ? 'Todo en su lugar.'
                        : 'Un inventario con nombre propio.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Productos, etiquetas y movimientos.\nTu tienda, organizada incluso sin conexión.',
                    style: TextStyle(color: Color(0xFFE7DDFB), height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _store,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nombre de la tienda',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _responsible,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Tu nombre · responsable',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Moneda'),
            items: [
              'GTQ',
              'USD',
              'MXN',
              'EUR',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) => setState(() => _currency = value!),
          ),
          const SizedBox(height: 20),
          if (widget.onboarding)
            Card(
              child: SwitchListTile.adaptive(
                value: _demo,
                onChanged: (v) => setState(() => _demo = v),
                title: const Text('Empezar con una tienda de ejemplo'),
                subtitle: const Text(
                  '15 productos y 3 categorías. Podrás editarlos o desactivarlos.',
                ),
              ),
            ),
          if (!widget.onboarding)
            const Text(
              'Cambiar la moneda solo cambia la unidad mostrada; no convierte precios. El historial conserva el responsable de cada operación.',
              style: TextStyle(color: AppColors.muted),
            ),
          const SizedBox(height: 24),
          BusyButton(
            label: widget.onboarding
                ? 'Abrir mi inventario'
                : 'Guardar configuración',
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;
}
