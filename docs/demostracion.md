# Guion de presentación y aceptación

## Presentación: 6–8 minutos

1. Problema: una tienda necesita saber qué hay, identificar cada producto y explicar cada cambio de cantidad.
2. Solución: una app local con catálogo, cámara, etiquetas y movimientos trazables.
3. Arquitectura: mostrar el árbol feature + domain y CalculateStock, separado de Flutter y SQLite.
4. Consistencia: explicar la transacción que inserta el movimiento y actualiza las existencias, y los triggers que protegen el historial.
5. Demostración: ejecutar el flujo siguiente mostrando el teléfono.
6. Pruebas y límites: mostrar las evidencias automatizadas y diferenciar pruebas de cámara física de las de lógica/interfaz. Una tienda, una bodega, un dispositivo; sin sincronización.

## Flujo obligatorio

Preparar otro dispositivo o una etiqueta impresa para mostrar los códigos a la cámara. Iniciar con un código nuevo, por ejemplo `DEMO-ACEPTACION-01`; si ya existe, usar otro código.

| Paso | Acción | Resultado esperado |
|---|---|---|
| 1 | Registrar producto, mínimo 5, existencias iniciales 0 | Producto activo con stock 0 |
| 2 | Abrir detalle y compartir etiqueta | Code 128 y QR identifican el mismo código |
| 3 | Entrada 20, motivo Compra inicial | Stock 20, primer movimiento |
| 4 | Escanear Code 128 y salida 16, motivo Venta | Stock 4 |
| 5 | Volver a resumen o catálogo | Alerta Stock bajo |
| 6 | Intentar salida 5 | Mensaje Stock insuficiente, sin movimiento nuevo |
| 7 | Escanear QR y ajuste 3, justificar conteo | Stock 3 y diferencia -1 |
| 8 | Historial filtrado por producto y exportar CSV | Entrada, salida y ajuste; CSV contiene stock 3 |
| 9 | Cerrar y reabrir la aplicación | Stock e historial se mantienen |

## Registro físico a completar durante la demostración

- Modelo del teléfono y versión Android:
- Fecha y responsable de la prueba:
- Code 128 leído correctamente:
- QR leído correctamente:
- Prueba con permiso de cámara denegado:
- Lectura y movimientos en modo avión:
- Reinicio y persistencia:
- Exportación CSV y etiqueta PDF:

No marcar estas verificaciones como realizadas sin ejecutarlas en un dispositivo físico.
