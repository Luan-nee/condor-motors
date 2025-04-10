# Endpoint: Crear un Producto

## Descripción

Este endpoint permite crear un nuevo producto en el sistema.

## URL

`[POST] {{base_url}}/api/{{idSucursal}}/productos`

#### Descripción de la url:

`idSucursal`: representa la id de la sucursal con un valor de tipo `INT`

## Headers

| Nombre          | Tipo   | Requerido | Descripción                  |
| --------------- | ------ | --------- | ---------------------------- |
| `Content-Type`  | String | Sí        | Debe ser `application/json`. |
| `Authorization` | String | Sí        | Token de autenticación JWT.  |

## Cuerpo de la Solicitud (JSON) _Ejemplo_

```json
{
  "nombre": "MacbookPro",
  "descripcion": "uhhh",
  "maxDiasSinReabastecer": 90,
  "colorId": 8,
  "categoriaId": 8,
  "marcaId": 8,
  "precioCompra": 69.99,
  "precioVenta": 200,
  "precioOferta": 90,
  "stock": 50
}
```

## Campos del Cuerpo de la Solicitud

| Campo                   | Tipo   | Requerido | Descripción                                                          |
| ----------------------- | ------ | --------- | -------------------------------------------------------------------- |
| `nombre`                | String | Sí        | Nombre del producto.                                                 |
| `descripcion`           | String | Sí        | Descripción breve del producto.                                      |
| `maxDiasSinReabastecer` | Number | Sí        | Número máximo de días que el producto puede estar sin reabastecerse. |
| `colorId`               | Number | Sí        | Identificador del color asociado al producto.                        |
| `categoriaId`           | Number | Sí        | Identificador de la categoría a la que pertenece el producto.        |
| `marcaId`               | Number | Sí        | Identificador de la marca del producto.                              |
| `precioCompra`          | Number | Sí        | Precio de compra del producto.                                       |
| `precioVenta`           | Number | Sí        | Precio de venta del producto.                                        |
| `precioOferta`          | Number | Sí        | Precio de liquidación del producto.                                  |
| `stock`                 | Number | Sí        | Cantidad disponible en inventario del producto.                      |

## Respuesta Exitosa

> EXPLICAR QUE PASA SI LA RESPUESTA ES EXITOSA

## Errores Comunes

> AGREGAR LOS ERRORES MÁS COMUNES QUE HAY.

| Código | Descripción                              |
| ------ | ---------------------------------------- |
| `400`  | Datos inválidos en la solicitud.         |
| `401`  | No autorizado, token inválido o ausente. |
| `404`  | Categoría no encontrada.                 |
| `500`  | Error interno del servidor.              |
