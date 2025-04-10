# Obtener proforma de venta por id

## Método: GET

## Endpoint

{{base_url}}/api/{{sucursalId}}/proformasventa/{{proformaVentaId}}

## Explicación de los permisos

- El rol `administrador` es capaz de obtener una proforma de venta de cualquier sucursal
- El rol `vendedor` es capaz de obtener una proforma de venta pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de obtener una proforma de venta pero solo en la sucursal a la que pertenece

## Request

### Body (request)

No existe cuerpo de la petición

## Response (success 200)

### Body (success 200 response)

Proforma de venta con cliente no definido

```jsonc
{
  "status": "success",
  "data": {
    "id": 128,
    "nombre": "Puede ser cualquier texto, como el nombre del cliente o el nombre del empleado junto con la hora",
    "total": "3072.40",
    "cliente": null,
    "empleado": {
      "id": 37,
      "nombre": "Administrador",
    },
    "sucursal": {
      "id": 13,
      "nombre": "Sucursal Principal",
    },
    "detalles": [
      {
        "nombre": "Awesome Bronze Salad8",
        "subtotal": 1350.9,
        "descuento": 16,
        "productoId": 99,
        "cantidadTotal": 10,
        "cantidadGratis": 0,
        "cantidadPagada": 10,
        "precioOriginal": 160.82,
        "precioUnitario": 135.09,
      },
      {
        "nombre": "Recycled Wooden Salad7",
        "subtotal": 1721.5,
        "descuento": null,
        "productoId": 98,
        "cantidadTotal": 12,
        "cantidadGratis": 2,
        "cantidadPagada": 10,
        "precioOriginal": 172.15,
        "precioUnitario": 172.15,
      },
    ],
    "fechaCreacion": "2025-04-06T15:56:19.230Z",
    "fechaActualizacion": "2025-04-06T15:56:19.230Z",
  },
}
```

Proforma de venta con cliente definido

```jsonc
{
  "status": "success",
  "data": {
    "id": 128,
    "nombre": "Puede ser cualquier texto, como el nombre del cliente o el nombre del empleado junto con la hora",
    "total": "3072.40",
    "cliente": {
      "id": 17,
      "nombre": "Parisian - DuBuque",
      "numeroDocumento": "20821221116",
    },
    "empleado": {
      "id": 37,
      "nombre": "Administrador",
    },
    "sucursal": {
      "id": 13,
      "nombre": "Sucursal Principal",
    },
    "detalles": [
      {
        "nombre": "Awesome Bronze Salad8",
        "subtotal": 1350.9,
        "descuento": 16,
        "productoId": 99,
        "cantidadTotal": 10,
        "cantidadGratis": 0,
        "cantidadPagada": 10,
        "precioOriginal": 160.82,
        "precioUnitario": 135.09,
      },
      {
        "nombre": "Recycled Wooden Salad7",
        "subtotal": 1721.5,
        "descuento": null,
        "productoId": 98,
        "cantidadTotal": 12,
        "cantidadGratis": 2,
        "cantidadPagada": 10,
        "precioOriginal": 172.15,
        "precioUnitario": 172.15,
      },
    ],
    "fechaCreacion": "2025-04-06T15:56:19.230Z",
    "fechaActualizacion": "2025-04-06T20:27:15.138Z",
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "No se encontró la proforma de venta",
}
```
