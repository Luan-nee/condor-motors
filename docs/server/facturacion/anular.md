# Crear venta

## Método: POST

## Endpoint

{{base_url}}/api/facturacion/anular

## Explicación de los permisos

El rol `administrador` es capaz de anular una venta en cualquier sucursal
El rol `vendedor` es capaz de anular ventas pero solo en la sucursal a la que pertenece
El rol `computadora` es capaz de anular ventas pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```json
{
  "ventaId": 21
}
```

## Response (success 200)

### Body (success 200 response)

```json
{
  "status": "success",
  "data": {
    "id": 6 // Id del documento de facturación anulado, este es el mismo que está vinculado a la venta cuando esta se declara
  }
}
```

## Response (fail 400)

### Body (fail 400 response)

```json
{
  "status": "fail",
  "error": "No se encontró la venta con id 21 en la sucursal especificada" // El mensaje de error varía dependiendo del tipo de error
}
```

## Response (fail 401)

### Body (fail 401 response)

```json
{
  "status": "fail",
  "error": "Token de facturación inválido"
}
```

## Response (error 500)

### Body (error 500 response)

```json
{
  "status": "error",
  "error": "El servicio de facturación no se encuentra activo en este momento"
}
```

## Response (error 503)

### Body (error 503 response)

```json
{
  "status": "fail",
  "error": "No se especificó un token de facturación, por lo que no se puede utilizar este servicio."
}
```
