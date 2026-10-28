# Funcionalidades, validaciones y permisos

## Configuración e inicio

Al abrir por primera vez se solicita tienda, responsable y moneda. Se puede activar la carga de 15 productos distribuidos en Despensa, Cuidado personal y Hogar. Las existencias de ejemplo generan entradas trazables. El resumen calcula productos activos, unidades, alertas, valoración y entradas/salidas de los últimos siete días.

## Productos

Crear, buscar por nombre o código, filtrar por categoría/estado/stock bajo, editar datos y desactivar/reactivar. La búsqueda por nombre no depende de la cámara. Los productos inactivos conservan su stock y sus movimientos; no admiten nuevos movimientos. No existe eliminación definitiva desde la interfaz.

El código se convierte a mayúsculas y acepta letras ASCII, números, punto, guion, guion bajo y barra. Se limita a 48 caracteres para que la etiqueta sea manejable. El nombre y categoría son obligatorios; fotografía y descripción son opcionales. Precios entre 0 y 9,999,999.99; cantidades hasta 1,000,000,000.

## Etiquetas y escáner

Code 128 y QR contienen exclusivamente el código único, por ejemplo `AB-001`. No incluyen existencias, precio ni datos personales. Al leerlos se consulta la base local. Se muestran en el detalle y se pueden compartir o imprimir en un PDF de 100 × 130 mm.

`mobile_scanner` usa la cámara para Code 128 y QR. En Android el modelo de lectura se incluye con el plugin para trabajar sin conexión. El permiso CAMERA se solicita al activar la cámara; el hardware de cámara se declara opcional para conservar la búsqueda manual en dispositivos sin ella.

La cámara se detiene al abrir el detalle y al pasar a segundo plano. Un indicador evita procesar varias lecturas mientras se abre un producto. Si el código no existe, se informa y se permite volver a activar la cámara. El botón de linterna captura errores cuando el dispositivo no la admite.

Si se deniega el permiso, habilitarlo en Ajustes de Android → Aplicaciones → Ámbar Inventario → Permisos → Cámara. En web la cámara requiere un contexto seguro como localhost o HTTPS, y su biblioteca puede requerir descarga en el primer uso; la garantía de operación sin conexión corresponde al APK Android.

## Movimientos

| Operación | Resultado | Validación |
|---|---|---|
| Entrada | stock + cantidad | Cantidad mayor que cero |
| Salida | stock - cantidad | Cantidad mayor que cero y no superior al disponible |
| Ajuste | cantidad contada | Conteo entero no negativo y justificación |

Todas las operaciones requieren motivo y responsable. La pantalla muestra stock actual y resultado previsto. Un diálogo confirma antes de escribir. La base vuelve a validar el stock, por lo que el cálculo mostrado no sustituye a la transacción. Los errores se corrigen con otro movimiento, conservando el original.

## Reportes

Historial filtrable por producto, tipo y rango de fechas. La fecha final incluye el día completo en hora local. Cada elemento se expande para mostrar motivo, responsable, código, hora, stock anterior y posterior.

La valoración del inventario activo es la suma de stock × precio de compra actual. Los productos inactivos se informan por separado. No se implementan FIFO, promedio ponderado ni valoración histórica. El CSV exporta todos los productos con su estado, moneda y valoración; los filtros de historial no alteran ese inventario completo.

El CSV usa UTF-8 con BOM, comillas escapadas y protección de celdas que comienzan como fórmulas. El usuario elige dónde guardar o compartir mediante el diálogo del sistema.

## Errores y estados

Inicio con progreso, fallo de almacenamiento con reintento, formularios con validación, botones deshabilitados mientras se guarda, confirmaciones de resultado y estados vacíos. Los fallos de exportación, fotografía o cámara muestran una acción para recuperarse. No se requiere conexión a un servidor ni se incluyen credenciales.
