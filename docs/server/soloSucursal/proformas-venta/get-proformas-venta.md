# Obtener proformas de venta

## Método: GET

## Endpoint

{{base_url}}/api/{{sucursalId}}/proformasventa

## Explicación de los permisos

- El rol `administrador` es capaz de obtener proformas de venta de cualquier sucursal
- El rol `vendedor` es capaz de obtener proformas de venta pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de obtener proformas de venta pero solo en la sucursal a la que pertenece

## Request

### Body (request)

No existe cuerpo de la petición

### Queries

#### Queries disponibles

A continuación se detalla una lista con el nombre de las queries aceptadas en este endpoint,
a la derecha de estas separada por ":" se encuentra el tipo de dato aceptado por estas

- search: string
- sort_by: string (solo los valores que se mencionan en la sección "Sort by")
- order: string (Solo se aceptan los siguientes valores "asc", "desc")
- page: number
- page_size: number (valor entre 1 y 150) valor por defecto: 30
- filter: string
- filter_value: any
- filter_type: string

Notas:
Si alguna query tiene un valor no procesable, simplemente será ignorada

#### Sort by (sort_by)

Es posible ordenar las ventas a través de las columnas siguientes, para realizarlo
es tan simple como agregar al query "sort_by" con el nombre de la columna involucrada

Ejemplo:
{{base_url}}/api/{{sucursalId}}/ventas?sort_by=fechaCreacion&order=asc

Posibles valores:

- fechaCreacion
- fechaActualizacion

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": [
    {
      "id": 128,
      "nombre": "La proforma definitiva no se me ocurre otra cosa",
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
    {
      "id": 113,
      "nombre": "umerus teneo ars",
      "total": "4857.09",
      "cliente": null,
      "empleado": {
        "id": 44,
        "nombre": "Amalia",
      },
      "sucursal": {
        "id": 13,
        "nombre": "Sucursal Principal",
      },
      "detalles": [
        {
          "nombre": "Awesome Cotton Pizza13",
          "subtotal": 812.75,
          "descuento": 0,
          "productoId": 104,
          "cantidadTotal": 6,
          "cantidadGratis": 1,
          "cantidadPagada": 5,
          "precioOriginal": 162.55,
          "precioUnitario": 162.55,
        },
        {
          "nombre": "Recycled Metal Gloves20",
          "subtotal": 1430.22,
          "descuento": 13,
          "productoId": 111,
          "cantidadTotal": 11,
          "cantidadGratis": 0,
          "cantidadPagada": 11,
          "precioOriginal": 163.99,
          "precioUnitario": 130.02,
        },
        {
          "nombre": "Sleek Granite Computer29",
          "subtotal": 756.95,
          "descuento": 0,
          "productoId": 120,
          "cantidadTotal": 6,
          "cantidadGratis": 1,
          "cantidadPagada": 5,
          "precioOriginal": 167.75,
          "precioUnitario": 151.39,
        },
        {
          "nombre": "Handmade Wooden Fish23",
          "subtotal": 332.78,
          "descuento": 0,
          "productoId": 114,
          "cantidadTotal": 2,
          "cantidadGratis": 0,
          "cantidadPagada": 2,
          "precioOriginal": 166.39,
          "precioUnitario": 166.39,
        },
        {
          "nombre": "Intelligent Wooden Mouse11",
          "subtotal": 1362.6,
          "descuento": 12,
          "productoId": 102,
          "cantidadTotal": 9,
          "cantidadGratis": 0,
          "cantidadPagada": 9,
          "precioOriginal": 172.05,
          "precioUnitario": 151.4,
        },
        {
          "nombre": "Handmade Steel Gloves10",
          "subtotal": 161.79,
          "descuento": 0,
          "productoId": 101,
          "cantidadTotal": 1,
          "cantidadGratis": 0,
          "cantidadPagada": 1,
          "precioOriginal": 161.79,
          "precioUnitario": 161.79,
        },
      ],
      "fechaCreacion": "2025-04-04T21:26:10.546Z",
      "fechaActualizacion": "2025-04-04T21:26:10.546Z",
    },
  ],
  "pagination": {
    "totalItems": 10,
    "totalPages": 5,
    "currentPage": 1,
    "hasNext": true,
    "hasPrev": false,
  },
  "metadata": {
    "sortByOptions": ["fechaCreacion", "fechaActualizacion"],
  },
}
```
