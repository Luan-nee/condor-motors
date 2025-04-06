# Obtener ventas

## Método: GET

## Endpoint

{{base_url}}/api/{{sucursalId}}/ventas

## Explicación de los permisos

- El rol `administrador` es capaz de obtener ventas de cualquier sucursal
- El rol `vendedor` es capaz de obtener ventas pero solo en la sucursal a la que pertenece
- El rol `computadora` es capaz de obtener ventas pero solo en la sucursal a la que pertenece

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
{{base_url}}/api/{{sucursalId}}/ventas?sort_by=fechaEmision

Posibles valores:

- declarada
- anulada
- estadoDocFacturacion
- totalVenta
- documentoFacturacion
- serieDocumento
- numeroDocumento
- nombreEmpleado
- tipoDocumentoCliente
- fechaEmision
- fechaCreacion

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": [
    {
      "id": 21,
      "declarada": true,
      "anulada": true,
      "cancelada": true,
      "serieDocumento": "B001",
      "numeroDocumento": "00000015",
      "tipoDocumento": "Boleta de venta electrónica",
      "fechaEmision": "2025-04-05",
      "horaEmision": "15:20:29",
      "empleado": {
        "id": 37,
        "nombre": "Administrador",
        "apellidos": "Principal",
      },
      "sucursal": {
        "id": 13,
        "nombre": "Sucursal Principal",
      },
      "totalesVenta": {
        "totalGravadas": "400.00",
        "totalExoneradas": "172.15",
        "totalGratuitas": "1000.00",
        "totalTax": "72.00",
        "totalVenta": "644.15",
      },
      "estado": {
        "codigo": "por-anular",
        "nombre": "Por anular ",
      },
      "documentoFacturacion": {
        "id": 6,
        "codigoEstadoSunat": "13",
        "linkPdf": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=a4",
        "linkPdfA4": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=a4",
        "linkPdfTicket": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=ticket",
      },
    },
    {
      "id": 20,
      "declarada": true,
      "anulada": false,
      "cancelada": true,
      "serieDocumento": "B001",
      "numeroDocumento": "00000014",
      "tipoDocumento": "Boleta de venta electrónica",
      "fechaEmision": "2025-04-05",
      "horaEmision": "12:43:13",
      "empleado": {
        "id": 37,
        "nombre": "Administrador",
        "apellidos": "Principal",
      },
      "sucursal": {
        "id": 13,
        "nombre": "Sucursal Principal",
      },
      "totalesVenta": {
        "totalGravadas": "400.00",
        "totalExoneradas": "172.15",
        "totalGratuitas": "1000.00",
        "totalTax": "72.00",
        "totalVenta": "644.15",
      },
      "estado": {
        "codigo": "aceptado-sunat",
        "nombre": "Aceptado ante la sunat",
      },
      "documentoFacturacion": {
        "id": 5,
        "codigoEstadoSunat": "05",
        "linkPdf": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=a4",
        "linkPdfA4": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=a4",
        "linkPdfTicket": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=ticket",
      },
    },
  ],
  "pagination": {
    "totalItems": 2,
    "totalPages": 1,
    "currentPage": 1,
    "hasNext": false,
    "hasPrev": false,
  },
  "metadata": {
    "sortByOptions": [
      "declarada",
      "anulada",
      "estadoDocFacturacion",
      "totalVenta",
      "documentoFacturacion",
      "serieDocumento",
      "numeroDocumento",
      "nombreEmpleado",
      "tipoDocumentoCliente",
      "fechaEmision",
      "fechaCreacion",
    ],
  },
}
```
