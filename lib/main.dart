import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/data/demo_loader.dart';
import 'core/data/local_database.dart';
import 'core/presentation/app_controller.dart';
import 'core/presentation/app_shell.dart';
import 'core/presentation/theme.dart';
import 'core/presentation/widgets.dart';
import 'features/inventory/data/sqlite_inventory_repository.dart';
import 'features/products/data/sqlite_product_repository.dart';
import 'features/settings/data/sqlite_profile_repository.dart';
import 'features/settings/presentation/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  AppController? _controller;
  String? _error;
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final db = await LocalDatabase.open();
      final controller = AppController(
        productsRepository: SqliteProductRepository(db),
        inventoryRepository: SqliteInventoryRepository(db),
        profileRepository: SqliteProfileRepository(db),
        loadDemo: DemoLoader(db).load,
      );
      await controller.initialize();
      if (mounted) setState(() => _controller = controller);
    } catch (error, stack) {
      debugPrint('Storage initialization failed: $error\n$stack');
      if (mounted) {
        setState(
          () => _error =
              'No se pudo abrir el almacenamiento. Revisa el espacio disponible y los permisos.',
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _controller != null
      ? TrazalApp(controller: _controller!)
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: Scaffold(
            body: Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : EmptyState(
                      title: 'No pudimos abrir tu inventario',
                      message: _error!,
                      action: FilledButton(
                        onPressed: _open,
                        child: const Text('Reintentar'),
                      ),
                    ),
            ),
          ),
        );
}

class TrazalApp extends StatelessWidget {
  const TrazalApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp(
      title: 'Trazal Inventario',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      locale: const Locale('es', 'GT'),
      supportedLocales: const [Locale('es', 'GT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Consumer<AppController>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (vm.error != null) {
            return Scaffold(
              body: Center(
                child: EmptyState(
                  title: 'No se pudo cargar el inventario',
                  message: vm.error!,
                  action: FilledButton(
                    onPressed: vm.initialize,
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
            );
          }
          return vm.profile == null
              ? const ProfileScreen(onboarding: true)
              : const AppShell();
        },
      ),
    ),
  );
}
