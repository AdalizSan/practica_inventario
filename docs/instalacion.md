# Instalación, ejecución y compilación

## Herramientas

La implementación se preparó con Flutter 3.47.8 y Dart 3.13.7. Las versiones exactas de bibliotecas están fijadas en `pubspec.lock`. Se necesita Android SDK, sus licencias y un JDK compatible con la versión de Gradle del proyecto. Android Studio incluye un JDK utilizable.

```sh
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
```

Para probar en teléfono: activar opciones de desarrollador y depuración USB, conectar el dispositivo, aceptar la autorización del equipo y verificarlo con `flutter devices`. El almacenamiento y la cámara reales requieren pruebas en el teléfono.

## APK

```sh
flutter build apk --release
```

El resultado estándar es `build/app/outputs/flutter-apk/app-release.apk`. La configuración usa la firma de desarrollo para una entrega académica instalable; no es una firma de publicación de Play Store. Para publicar, configurar una clave privada propia y mantenerla fuera del repositorio.

Instalar desde un teléfono permite abrir el archivo APK y autorizar a la aplicación de archivos para instalarlo. Con ADB:

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

La cámara se solicita cuando se pulsa Activar cámara. La selección de imágenes usa el selector del sistema. Los archivos se exportan mediante compartir o imprimir, sin solicitar acceso indiscriminado al almacenamiento.

## Vista web local

```sh
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8765
```

Para generar una compilación estática:

```sh
flutter build web --no-web-resources-cdn
python -m http.server 8765 --directory build/web
```

Mantener el mismo origen y puerto conserva la base IndexedDB. No abrir `index.html` con `file://`. No ejecutar compilaciones web y Android simultáneamente sobre la misma carpeta de build.

## Bibliotecas

Provider administra el estado; sqflite persiste en Android; sqflite_common_ffi permite pruebas contra SQLite en escritorio; sqflite_common_ffi_web habilita la demostración web. mobile_scanner lee códigos; barcode_widget y qr_flutter los muestran. pdf y printing generan y comparten etiquetas; share_plus exporta CSV. image_picker selecciona fotos. animations, flutter_animate y fl_chart aportan transiciones y gráfica. intl da formato local, uuid crea identificadores y path construye rutas.

Las fuentes son locales y se distribuyen con licencia OFL en `assets/fonts`.

## Mantenimiento

Ejecutar análisis y pruebas antes de cambiar dependencias. Revisar permisos y compatibilidad Android de plugins al actualizar. No usar una actualización destructiva del esquema. Mantener las claves de firma fuera de Git. Los nombres de tienda y responsable no deben incorporarse al código: se configuran en la app.
