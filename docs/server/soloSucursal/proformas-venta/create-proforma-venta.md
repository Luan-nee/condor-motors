# Crear proforma de venta

## Método: POST

## Endpoint

{{base_url}}/api/{{sucursalId}}/proformasventa

## Descripción

Endpoint para generar proformas de venta, estas son una forma simplificada de tener un registro de los productos que serán vendidos posteriormente

Aclaración: La creación de proformas de venta no afecta de ninguna forma el stock de los productos

## Explicación de los permisos

- El rol `administrador` es capaz de crear proformas de venta en cualquier sucursal
- El rol `vendedor` es capaz de crear proformas de venta pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de crear proformas de venta pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```jsonc
{
  "nombre": "La proforma definitiva no se me ocurre otra cosa", // opcional
  "empleadoId": 28,
  "clienteId": 11, // opcional
  "detalles": [
    {
      "productoId": 68,
      "cantidad": 10,
    },
    {
      "productoId": 69,
      "cantidad": 10,
    },
  ],
}
```

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": {
    "id": 128, // Id de la proforma de venta creada
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "Estos productos no existen en su sucursal: 1198, 1182", // El mensaje de error varía dependiendo del tipo de error
}
```
