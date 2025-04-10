# Cancelar venta

## Método: POST

## Endpoint

{{base_url}}/api/{{sucursalId}}/ventas/{{ventaId}}/cancelar

## Descripción

Este endpoint permite cancelar una venta y revierte el stock de los productos involucrados en esta
Solo puede ser aplicado una vez por cada venta

## Explicación de los permisos

- El rol `administrador` es capaz de cancelar una venta en cualquier sucursal
- El rol `vendedor` es capaz de cancelar ventas pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de cancelar ventas pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```jsonc
{
  "motivoAnulado": "Por favor anula esta venta",
}
```

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": [
    {
      "id": 20, // Id de la venta cancelada
    },
  ],
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "Esta venta no se puede cancelar porque ya ha sido cancelada",
}
```

## Response (fail 404)

### Body (fail 404 response)

```jsonc
{
  "status": "fail",
  "error": "La venta que intentó cancelar no existe",
}
```
