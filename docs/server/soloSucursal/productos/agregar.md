# Agregar Producto

Este endpoint permite habilitar un producto dentro de una sucursal.

## URL

`[POST] {{base_url}}/api/{{idSucursal}}/productos/{{idProducto}}`

#### Descripción de la url:

`idSucursal`: representa la id de la sucursal con un valor de tipo `INT`.<br>
`idProducto`: representa la id de producto que vas habilitar, valor de tipo `INT`.<br>

## Headers

| Nombre          | Tipo   | Requerido | Descripción                  |
| --------------- | ------ | --------- | ---------------------------- |
| `Content-Type`  | String | Sí        | Debe ser `application/json`. |
| `Authorization` | String | Sí        | Token de autenticación JWT.  |

## Cuerpo de la Solicitud (JSON) _Ejemplo_

```json
{
  "precioCompra": 300.32,
  "precioVenta": 1023.99,
  "precioOferta": 999.99,
  "stock": 777
}
```

## Campos del Cuerpo de la Solicitud

| Campo          | Tipo   | Requerido | Descripción                                                                                                                                                                                     |
| -------------- | ------ | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `precioCompra` | Number | Sí        | Precio que el dueño paga a sus distribuidores para comprar productos y luego venderlo.                                                                                                          |
| `precioVenta`  | Number | Sí        | Precio que usa una sucursal para vender el producto a sus clientes.                                                                                                                             |
| `precioOferta` | Number | Sí        | Precio de liquidación, es el precio que toma el producto cuando el administrador lo decida. Este precio es menor al `precioVenta` y el proposito es reducir el precio para realizar más ventas. |
| `stock`        | Number | Sí        | Es el stock que tendrá el producto cuando se habilite.                                                                                                                                          |

## Respuesta Exitosa

> EXPLICAR QUE PASA SI LA RESPUESTA ES EXITOSA

## Errores Comunes

> REVISAR Y AGREGAR LOS ERRORES MÁS COMUNES QUE HAY.

| Código | Descripción                              |
| ------ | ---------------------------------------- |
| `400`  | Datos inválidos en la solicitud.         |
| `401`  | No autorizado, token inválido o ausente. |
| `404`  | Categoría no encontrada.                 |
| `500`  | Error interno del servidor.              |
