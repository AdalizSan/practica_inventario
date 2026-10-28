# Ámbar Inventario

Aplicación Flutter para administrar una pequeña tienda sin depender de una conexión. Catálogo editable, etiquetas Code 128 y QR, escáner, entradas, salidas, conteos físicos, alertas y exportación CSV.

El diseño usa morado, fuentes locales y transiciones adaptables. Los indicadores provienen de SQLite. Los datos de ejemplo se cargan opcionalmente desde `assets/data/demo.json`; no sustituyen a la persistencia real.

## Empezar

```sh
flutter pub get
flutter run
```

Configura tienda, responsable y moneda. Activa la tienda de ejemplo para cargar 15 productos de 3 categorías, o desactívala para comenzar vacía.

## Verificar y compilar

```sh
flutter analyze
flutter test
flutter build apk --release
```

## Documentación

- [Instalación, dependencias y compilación](docs/instalacion.md)
- [Arquitectura feature + domain](docs/arquitectura.md)
- [Modelo de datos y persistencia](docs/modelo-datos.md)
- [Funcionalidades, validaciones y permisos](docs/funcionalidades.md)
- [Pruebas y límites de verificación](docs/pruebas.md)
- [Guion de presentación y demostración](docs/demostracion.md)
- [Presentación visual](docs/presentacion.pdf)
- [Manual de usuario](docs/manual-usuario.pdf)

## Alcance

Una tienda, una bodega y un dispositivo. No incorpora usuarios remotos, sincronización, proveedores ni valoración contable. El responsable es un perfil local. La valoración usa las existencias y el precio de compra actual.

Los movimientos confirmados no se pueden editar ni borrar. Una salida superior a las existencias es rechazada dentro de una transacción. Las existencias iniciales se registran como entrada. Los productos se desactivan conservando su historial.

## Entrega y prueba física

El repositorio incluye pruebas automatizadas de dominio, repositorio SQLite y navegación a cuatro tamaños de pantalla, con logs en `docs`. La lectura de ambos formatos con cámara, la instalación y el ciclo de vida Android deben validarse en un teléfono físico antes de la demostración; el documento de pruebas registra el estado real de esa validación.

El APK académico usa firma de desarrollo. Las fuentes se distribuyen con sus licencias OFL. La exportación CSV es un reporte, no un respaldo restaurable completo.
