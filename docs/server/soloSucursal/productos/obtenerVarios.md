# Endpoint: Obtener varios `[GET]`

Este endpoint obtienen los datos de varios productos de una sucursal especificada.

## URL

`[GET] {{base_url}}/api/{{idSucursal}}/productos`

#### Descripción de la url:

`idSucursal`: representa la id de la sucursal con un valor de tipo `INT`.<br>

## Headers

| Nombre          | Tipo   | Requerido | Descripción                  |
| --------------- | ------ | --------- | ---------------------------- |
| `Content-Type`  | String | Sí        | Debe ser `application/json`. |
| `Authorization` | String | Sí        | Token de autenticación JWT.  |

## Respuesta Exitosa _ejemplo_

```jsonc
{
  "status": "success",
  "data": [
    {
      "id": 38,
      "sku": "0000038",
      "nombre": "Producto 123",
      "descripcion": "descripción del producto 123",
      "maxDiasSinReabastecer": null,
      "stockMinimo": 10,
      "cantidadMinimaDescuento": null,
      "cantidadGratisDescuento": null,
      "porcentajeDescuento": null,
      "color": "Negro",
      "categoria": "Cascos",
      "marca": "Belstafffff",
      "fechaCreacion": "2025-04-10T01:20:55.206Z",
      "detalleProductoId": null,
      "precioCompra": null,
      "precioVenta": null,
      "precioOferta": null,
      "stock": null,
      "stockBajo": null,
      "liquidacion": null,
    },
    {
      "id": 37,
      "sku": "0000037",
      "nombre": "Producto 123",
      "descripcion": "descripción del producto 123",
      "maxDiasSinReabastecer": null,
      "stockMinimo": 10,
      "cantidadMinimaDescuento": null,
      "cantidadGratisDescuento": null,
      "porcentajeDescuento": null,
      "color": "Negro",
      "categoria": "Cascos",
      "marca": "Belstafffff",
      "fechaCreacion": "2025-04-10T01:20:53.786Z",
      "detalleProductoId": null,
      "precioCompra": null,
      "precioVenta": null,
      "precioOferta": null,
      "stock": null,
      "stockBajo": null,
      "liquidacion": null,
    },
  ],
}
```

## Errores Comunes

> REVISAR Y AGREGAR LOS ERRORES MÁS COMUNES QUE HAY.

| Código | Descripción                              |
| ------ | ---------------------------------------- |
| `400`  | Datos inválidos en la solicitud.         |
| `401`  | No autorizado, token inválido o ausente. |
| `404`  | Categoría no encontrada.                 |
| `500`  | Error interno del servidor.              |
