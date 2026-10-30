import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/reports/presentation/history_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import 'app_controller.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _labels = ['Resumen', 'Productos', 'Escanear', 'Historial'];
  final _icons = [
    Icons.space_dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.qr_code_scanner_rounded,
    Icons.receipt_long_outlined,
  ];
  void _navigate(int index) => setState(() => _index = index);
  void _settings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProfileScreen()),
  );
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppController>().profile!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final content = PageTransitionSwitcher(
          duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 320,
          ),
          transitionBuilder: (child, primary, secondary) =>
              SharedAxisTransition(
                animation: primary,
                secondaryAnimation: secondary,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: AppColors.canvas,
                child: child,
              ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: switch (_index) {
              0 => DashboardScreen(onNavigate: _navigate),
              1 => const ProductsScreen(),
              2 => const ScannerScreen(),
              _ => const HistoryScreen(),
            },
          ),
        );
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  title: const Row(
                    children: [
                      Icon(
                        Icons.all_inbox_rounded,
                        color: AppColors.purple,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'trazal',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Configurar tienda y responsable',
                      onPressed: _settings,
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                  ],
                ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _navigate,
                  destinations: List.generate(
                    4,
                    (i) => NavigationDestination(
                      key: ValueKey('nav_$i'),
                      icon: Icon(_icons[i]),
                      label: _labels[i],
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 238,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: AppColors.border),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 32, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.all_inbox_rounded,
                              color: AppColors.purple,
                              size: 34,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'trazal',
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 44, top: 2),
                          child: Text(
                            'INVENTARIO',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'ESPACIO DE TRABAJO',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(
                          4,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              decoration: BoxDecoration(
                                color: _index == i
                                    ? AppColors.lavender
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  key: ValueKey('nav_$i'),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  minLeadingWidth: 20,
                                  leading: Icon(
                                    _icons[i],
                                    size: 21,
                                    color: _index == i
                                        ? AppColors.purple
                                        : AppColors.muted,
                                  ),
                                  title: Text(
                                    _labels[i],
                                    style: TextStyle(
                                      fontWeight: _index == i
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                      color: _index == i
                                          ? AppColors.purple
                                          : AppColors.muted,
                                    ),
                                  ),
                                  onTap: () => _navigate(i),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.offline_pin_outlined,
                                color: AppColors.green,
                                size: 20,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tu tienda, siempre a mano.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Trabaja sin conexión. Tus datos permanecen en este dispositivo.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Divider(),
                        Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lavender,
                              child: Text(
                                profile.responsible.characters.first
                                    .toUpperCase(),
                                style: const TextStyle(color: AppColors.purple),
                              ),
                            ),
                            title: Text(
                              profile.responsible,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              profile.store,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.settings_outlined,
                              size: 18,
                            ),
                            onTap: _settings,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
