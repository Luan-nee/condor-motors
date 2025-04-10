# Actualizar proforma de venta

## Método: PATCH

## Endpoint

{{base_url}}/api/{{sucursalId}}/proformasventa/{{proformaVentaId}}

## Descripción

Endpoint para actualizar datos específicos de una proforma de venta, o varios a la vez

## Explicación de los permisos

- El rol `administrador` es capaz de actualizar proformas de venta de cualquier sucursal
- El rol `vendedor` es capaz de actualizar proformas de venta pero solo de la sucursal a la que pertenece
- El rol `computadora` es capaz de actualizar proformas de venta pero solo de la sucursal a la que pertenece

## Request

### Body (request)

Todos los datos son opcionales, por lo que se puede enviar solo el nombre si se desea actulaizar solo este, o solo los nuevos detalles de la proforma en caso se deseen actualizar estos

Advertencia: Enviar datos en la propiedad detalles reemplazará completamente todos los items que se encuentren allí

```jsonc
{
  "nombre": "Nuevo nombre de la proforma de venta", // opcional
  "clienteId": 17, // opcional
  /* opcional */
  "detalles": [
    {
      "productoId": 76,
      "cantidad": 5,
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
    "id": 128, // Id de la proforma de venta actualizada
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
