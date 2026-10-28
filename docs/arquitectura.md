# Arquitectura feature + domain

Ámbar es una aplicación Flutter para una tienda, una bodega y un dispositivo. Android es la plataforma de entrega; web sirve como vista de demostración y validación de interfaz.

## Organización

```text
lib/
  core/
    data/                  Apertura SQLite y carga transaccional de demostración
    domain/                AppFailure, errores recuperables
    presentation/          Composición, controlador, tema y componentes compartidos
  features/
    products/
      domain/              Product, ValidateProduct, ProductRepository
      data/                ProductMapper, SqliteProductRepository
      presentation/        Catálogo, formulario y detalle
    inventory/
      domain/              MovementRequest, StockMovement, CalculateStock, contrato
      data/                SqliteInventoryRepository
      presentation/        Registro y confirmación de movimientos
    scanner/
      domain/              ResolveCode
      presentation/        Cámara, permisos y búsqueda por código
    reports/
      domain/              InventoryReport, filtros y CSV
      data/                ExportService: archivos compartidos y etiquetas PDF
      presentation/        Historial y exportación
    settings/
      domain/              Profile y ProfileRepository
      data/                SqliteProfileRepository
      presentation/        Configuración inicial y perfil
    dashboard/
      presentation/        Resumen y gráfica derivados de los datos
```

No se crean carpetas vacías para capas sin responsabilidad real. El escáner recibe resultados del plugin de cámara y los resuelve mediante dominio; no mantiene una segunda base de productos. El resumen utiliza los agregados de reportes.

## Dependencias y responsabilidades

El dominio usa Dart puro, no widgets, Provider ni SQLite. Las entidades son inmutables. Los contratos están en dominio y las implementaciones SQLite en datos. La composición de dependencias ocurre en `main.dart`.

La presentación llama a `AppController`, un ViewModel compartido basado en ChangeNotifier e inyectado con Provider. El controlador recibe contratos de repositorio por constructor; expone listas no modificables, estado de carga, estado de escritura y errores legibles. No contiene las reglas que calculan existencias.

Flujo: pantalla → controlador → contrato de repositorio → transacción SQLite → CalculateStock → inserción del movimiento y actualización del producto → recarga de estado → notificación a la interfaz.

El repositorio vuelve a leer el stock dentro de la transacción. Así una vista previa desactualizada nunca autoriza una salida inválida. `busy` evita pulsaciones repetidas en la misma instancia del controlador; la transacción y las restricciones protegen la base independientemente de la interfaz.

## Casos de uso

- ValidateProduct verifica identidad, campos y límites numéricos.
- CalculateStock valida el movimiento y calcula el resultado para entrada, salida y conteo físico.
- ResolveCode normaliza y busca el código recibido de cámara o teclado.
- InventoryReport deriva existencias, alertas, valoración, filtros y CSV de los productos y movimientos almacenados.

## Decisiones

Los precios se almacenan en centavos enteros. La interfaz acepta hasta dos decimales; no se usan sumas monetarias con valores de punto flotante. Los movimientos guardan una instantánea del nombre y código para conservar el contexto histórico tras editar un producto. El perfil es local; no equivale a autenticación ni control de acceso.

Los datos de demostración viven en un JSON separado y se insertan una sola vez si el catálogo está vacío. La interfaz no depende de códigos, categorías ni cantidades de ese JSON. Una tienda nueva puede empezar sin productos.

## Diseño y movimiento

Paleta morado ciruela, lavanda, blanco y tinta. Manrope para lectura y Space Grotesk para títulos y cifras, ambas incluidas localmente con sus licencias. Material 3 ofrece controles y accesibilidad; `animations` aporta transiciones SharedAxis y OpenContainer, `flutter_animate` entradas escalonadas, `fl_chart` interpolación de la gráfica y Flutter anima el conteo y el marco del escáner. Se consulta la preferencia de reducción de movimiento.

La navegación inferior se sustituye por barra lateral según ancho disponible. Las listas largas se construyen de forma diferida. Formularios y detalle tienen ancho máximo. Las fotografías se reducen al seleccionarse y se limitan a 2 MB.
