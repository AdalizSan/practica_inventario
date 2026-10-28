# Pruebas y evidencia

## Reproducción

```sh
flutter analyze
flutter test --reporter expanded
```

`test/inventory_test.dart` ejecuta pruebas contra SQLite real mediante FFI. No reemplaza la base con un mapa en memoria: también prueba restricciones, triggers y transacciones del esquema entregado.

## Inventario: 12 casos aprobados

1. Flujo de aceptación: entrada 20, salida 16, alerta a 4, rechazo de salida 5, ajuste a 3 y exportación del valor correcto.
2. Existencias iniciales trazables y código duplicado rechazado.
3. Edición de datos sin alterar stock ni la instantánea del historial.
4. Desactivación, bloqueo de movimientos y restricción de borrado con referencias.
5. Historial protegido contra UPDATE y DELETE.
6. Fallo simulado al actualizar stock: revierte también la inserción del movimiento.
7. Dos salidas simultáneas: solo una puede consumir el stock; nunca queda negativo.
8. Validación de cantidades, justificación, responsable y límite superior.
9. Código desconocido, normalización y caracteres admitidos.
10. CSV con comillas, comas, UTF-8 y protección contra fórmulas.
11. Filtros por producto, tipo y rango con día final inclusivo.
12. Persistencia tras cerrar y volver a abrir un archivo SQLite.

Evidencia: [test-results.txt](test-results.txt).

## Interfaz: cuatro tamaños aprobados

`test/ui_test.dart` carga la demostración en SQLite y navega desde el resumen al catálogo, busca AB-002, abre el detalle, vuelve y abre el historial. Verifica la ausencia de excepciones de layout en 320 × 568, 390 × 844, 768 × 1024 y 1360 × 1000.

Las pruebas detectaron y permitieron corregir un desbordamiento del selector de categorías, una fila de unidades en móvil y el material de la barra lateral. Evidencia: [ui-test-results.txt](ui-test-results.txt).

## Análisis estático

La revisión estática se guarda en [analysis-results.txt](analysis-results.txt). No se silenciaron errores ni reglas de análisis para obtener un resultado aprobado.

La revisión final simplificó el cálculo semanal repetido y corrigió el estado del escáner cuando falla el inicio de la cámara. Después de esos cambios se repitieron `flutter analyze`, las 16 pruebas automatizadas y la compilación Android de lanzamiento.

## Pendiente de dispositivo físico

No había un teléfono ni un emulador configurado conectado durante la preparación. No se afirma haber probado cámara física, foco, iluminación, linterna, permisos reales Android, instalación ni reinicio del proceso en un teléfono.

Realizar los nueve pasos de [demostracion.md](demostracion.md), probar tanto Code 128 como QR, denegar y volver a conceder el permiso, repetir en modo avión y cerrar/reabrir la app. Registrar modelo, Android, fecha, responsable y resultado. Las comprobaciones de lógica y navegador no sustituyen esta prueba.

## Límites

La base no está cifrada, el perfil no autentica personas y no hay sincronización entre dispositivos. El CSV no restaura fotos ni movimientos. La cámara web puede requerir conexión inicial para cargar su lector; Android usa el componente incluido. No se han ejecutado pruebas exhaustivas de rendimiento con cientos de miles de movimientos ni de compatibilidad con todas las versiones de Android.
