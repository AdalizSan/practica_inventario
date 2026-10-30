import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/presentation/app_controller.dart';
import '../../../core/presentation/theme.dart';
import '../../../core/presentation/widgets.dart';
import '../../products/presentation/product_detail.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _camera = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.code128, BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _manual = TextEditingController();
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _enabled = false, _handling = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else {
      _sweep.repeat(reverse: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled || !_camera.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !_handling) {
      _start();
    } else {
      _camera.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweep.dispose();
    _camera.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() {
      _enabled = true;
      _error = null;
    });
    try {
      await _camera.start();
    } catch (_) {
      if (mounted) {
        setState(() {
          _enabled = false;
          _error =
              'No se pudo acceder a la cámara. Revisa los permisos o busca el código manualmente.';
        });
      }
    }
  }

  Future<void> _resolve(String code) async {
    if (_handling) return;
    _handling = true;
    try {
      final p = context.read<AppController>().resolve(code);
      if (_enabled) await _camera.stop();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetail(productId: p.id)),
      );
      if (mounted && _enabled) await _start();
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppController.friendly(e));
        if (_enabled) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _error = null);
        }
      }
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SectionHeading(
        'Apunta. Encuentra. Actualiza.',
        subtitle: 'Lee un código de barras Code 128 o un QR de producto.',
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 340,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.ink),
              if (_enabled)
                MobileScanner(
                  controller: _camera,
                  errorBuilder: (context, error) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text(
                        'Cámara no disponible. Activa el permiso de cámara en los ajustes del dispositivo o utiliza la búsqueda manual.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onDetect: (capture) {
                    for (final code in capture.barcodes) {
                      if (code.rawValue != null) {
                        _resolve(code.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 240,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .7),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (_, _) => Align(
                        alignment: Alignment(0, _sweep.value * 1.7 - .85),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7C5FF),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: .7),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_enabled)
                Center(
                  child: FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Activar cámara'),
                  ),
                ),
              if (_enabled)
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: IconButton.filled(
                    tooltip: 'Encender o apagar linterna',
                    onPressed: () async {
                      try {
                        await _camera.toggleTorch();
                      } catch (_) {
                        if (context.mounted) {
                          notice(context, 'La linterna no está disponible.');
                        }
                      }
                    },
                    icon: const Icon(Icons.flash_on_outlined),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Coloca el código completo dentro del marco y procura tener buena iluminación.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Card(
            color: const Color(0xFFFFF1E5),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!),
            ),
          ),
        ),
      const SizedBox(height: 28),
      const SectionHeading(
        'También puedes escribirlo',
        subtitle: 'La búsqueda manual funciona sin cámara.',
      ),
      TextField(
        controller: _manual,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Código del producto',
          prefixIcon: Icon(Icons.qr_code_2_rounded),
        ),
        onSubmitted: _resolve,
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => _resolve(_manual.text),
        icon: const Icon(Icons.search),
        label: const Text('Buscar producto'),
      ),
    ],
  );
}
