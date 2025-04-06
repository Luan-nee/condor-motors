# Obtener información necesaria para emitir una venta

## Método: GET

## Endpoint

{{base_url}}/api/{{sucursalId}}/ventas/informacion

## Explicación de los permisos

Cualquier rol es capaz de acceder a estos datos

## Request

### Body (request)

No existe cuerpo de la petición

## Response (success 200)

### Body (success 200 response)

```json
{
  "status": "success",
  "data": {
    "tiposTax": [
      {
        "id": 10,
        "nombre": "Gravado (Con 18% de impuestos)",
        "codigo": "gravado"
      },
      {
        "id": 11,
        "nombre": "Exonerado (Sin impuestos)",
        "codigo": "exonerado"
      },
      {
        "id": 12,
        "nombre": "Gratuito (Producto gratuito)",
        "codigo": "gratuito"
      }
    ],
    "tiposDocFacturacion": [
      {
        "id": 7,
        "nombre": "Factura electrónica",
        "codigo": "factura"
      },
      {
        "id": 8,
        "nombre": "Boleta de venta electrónica",
        "codigo": "boleta"
      }
    ],
    "tiposDocCliente": [
      {
        "id": 19,
        "nombre": "RUC",
        "codigo": "ruc"
      },
      {
        "id": 20,
        "nombre": "DNI",
        "codigo": "dni"
      },
      {
        "id": 21,
        "nombre": "CARNET DE EXTRANJERÍA",
        "codigo": "carnet_extranjeria"
      },
      {
        "id": 22,
        "nombre": "PASAPORTE",
        "codigo": "pasaporte"
      },
      {
        "id": 23,
        "nombre": "CÉDULA DIPLOMÁTICA DE IDENTIDAD",
        "codigo": "cedula_diplomática_identidad"
      },
      {
        "id": 24,
        "nombre": "NO DOMICILIADO, SIN RUC",
        "codigo": "no_domiciliado_sin_ruc"
      }
    ]
  }
}
```
