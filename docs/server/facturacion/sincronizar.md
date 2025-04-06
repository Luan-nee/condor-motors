# Sincronizar documento

## Método: POST

## Endpoint

{{base_url}}/api/facturacion/sincronizar

## Descripción

Este endpoint permite sincronizar el documento de facturación emitido ante sunat, esto funcionará siempre en cuando la venta haya sido declarada
Al realizar la accion de forma exitosa los datos del documento vinculado a la venta se actualizarán para reflejar el estado actual de estos ante sunat

## Explicación de los permisos

- El rol `administrador` es capaz de sincronizar documentos en cualquier sucursal
- El rol `vendedor` es capaz de sincronizar documentos pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de sincronizar documentos pero solo en la sucursal a la que pertenece

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
    "id": 6, // Id del documento de facturación actualizado
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
