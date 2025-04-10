# Eliminar proforma de venta

## Método: DELETE

## Endpoint

{{base_url}}/api/{{sucursalId}}/proformasventa/{{proformaVentaId}}

## Descripción

Endpoint para eliminar una proforma de venta

## Explicación de los permisos

- El rol `administrador` es capaz de eliminar proformas de venta de cualquier sucursal
- El rol `vendedor` es capaz de eliminar proformas de venta pero solo de la sucursal a la que pertenece
- El rol `computadora` es capaz de eliminar proformas de venta pero solo de la sucursal a la que pertenece

## Request

### Body (request)

No existe cuerpo de la petición

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": {
    "id": 128, // Id de la proforma de venta eliminada
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "No se pudo eliminar la proforma de venta con el id 1288 (No encontrada)", // El mensaje de error varía dependiendo del tipo de error
}
```
