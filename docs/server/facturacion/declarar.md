# Declarar venta

## Método: POST

## Endpoint

{{base_url}}/api/facturacion/declarar

## Descripción

Este endpoint permite declarar ante sunat una venta realizada, siempre en cuando esta no haya sido cancelada
Al realizar la accion de forma exitosa los datos de la venta se actualizarán, y a partir de ese momento tendrá información acerca del documento emitido en la propiedad documento de la respuesta

## Explicación de los permisos

- El rol `administrador` es capaz de declarar una venta en cualquier sucursal
- El rol `vendedor` es capaz de declarar ventas pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de declarar ventas pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```jsonc
{
  "enviarCliente": false,
  "ventaId": 21,
}
```

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": {
    "id": 6, // Id del documento de facturación generado para la venta declarada
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "No se encontró la venta con id 21 en la sucursal especificada", // El mensaje de error varía dependiendo del tipo de error
}
```

## Response (fail 401)

### Body (fail 401 response)

```jsonc
{
  "status": "fail",
  "error": "Token de facturación inválido",
}
```

## Response (error 500)

### Body (error 500 response)

```jsonc
{
  "status": "error",
  "error": "El servicio de facturación no se encuentra activo en este momento",
}
```

## Response (error 503)

### Body (error 503 response)

```jsonc
{
  "status": "fail",
  "error": "No se especificó un token de facturación, por lo que no se puede utilizar este servicio.",
}
```
