# Endpoint: Obtener uno `[GET]`

Este endpoint obtienen los datos de un producto en una sucursal especificada.

## URL

`[POST] {{base_url}}/api/{{idSucursal}}/productos/{{idProducto}}`

#### Descripción de la url:

`idSucursal`: representa la id de la sucursal con un valor de tipo `INT`.<br>
`idProducto`: representa la id del producto, valor de tipo `INT`.<br>

## Headers

| Nombre          | Tipo   | Requerido | Descripción                  |
| --------------- | ------ | --------- | ---------------------------- |
| `Content-Type`  | String | Sí        | Debe ser `application/json`. |
| `Authorization` | String | Sí        | Token de autenticación JWT.  |

## Respuesta Exitosa _ejemplo_

```jsonc
{
  "status": "success",
  "data": {
    "id": 10,
    "sku": "0000010",
    "nombre": "Ergonomic Gold Keyboard9",
    "descripcion": "Featuring Flerovium-enhanced technology, our Sausages offers unparalleled neighboring performance",
    "maxDiasSinReabastecer": 61,
    "stockMinimo": 27,
    "cantidadMinimaDescuento": 3,
    "cantidadGratisDescuento": null,
    "porcentajeDescuento": 14,
    "color": "Verde",
    "categoria": "Toritos",
    "marca": "Hondaaaaa",
    "fechaCreacion": "2025-04-05T02:27:58.693Z",
    "detalleProductoId": 28,
    "precioCompra": "106.29",
    "precioVenta": "166.99",
    "precioOferta": "152.39",
    "stock": 161,
    "stockBajo": false,
    "liquidacion": false,
  },
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
