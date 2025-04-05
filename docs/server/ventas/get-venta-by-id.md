# Obtener venta por id

## Método: GET

## Endpoint

{{base_url}}/api/{{sucursalId}}/ventas/{{ventaId}}

## Explicación de los permisos

El rol `administrador` es capaz de obtener una venta de cualquier sucursal
El rol `vendedor` es capaz de obtener una venta pero solo en la sucursal a la que pertenece
El rol `computadora` es capaz de obtener una venta pero solo en la sucursal a la que pertenece

## Request

### Body (request)

No existe cuerpo de la petición

## Response (success 200)

### Body (success 200 response)

Venta realizada pero no declarada

```json
{
  "status": "success",
  "data": {
    "id": 20,
    "declarada": false,
    "anulada": false,
    "serieDocumento": "B001",
    "numeroDocumento": "00000001",
    "observaciones": "*Observa fijamente hasta que le cae un poco de arena en el ojo*",
    "motivoAnulado": "Por favor anula esta venta",
    "tipoDocumento": "Boleta de venta electrónica",
    "fechaEmision": "2025-04-05",
    "horaEmision": "12:43:13",
    "moneda": "Soles",
    "metodoPago": "Contado",
    "cliente": {
      "id": 19,
      "tipoDocumento": "DNI",
      "numeroDocumento": "36569991",
      "denominacion": "John Cremin"
    },
    "empleado": {
      "id": 37,
      "nombre": "Administrador",
      "apellidos": "Principal"
    },
    "sucursal": {
      "id": 13,
      "nombre": "Sucursal Principal"
    },
    "totalesVenta": {
      "totalGravadas": "400.00",
      "totalExoneradas": "172.15",
      "totalGratuitas": "1000.00",
      "totalTax": "72.00",
      "totalVenta": "644.15"
    },
    "estado": null,
    "documentoFacturacion": null,
    "detallesVenta": [
      {
        "id": 37,
        "tipoUnidad": "NIU",
        "codigo": "0000098",
        "nombre": "Recycled Wooden Salad7",
        "cantidad": 1,
        "precioSinIgv": "172.15",
        "precioConIgv": "172.15",
        "tipoTax": "Exonerado (Sin impuestos)",
        "totalBaseTax": "172.15",
        "totalTax": "0.00",
        "total": "172.15",
        "productoId": 98
      },
      {
        "id": 38,
        "tipoUnidad": "NIU",
        "codigo": null,
        "nombre": "Producto espacial interestelar",
        "cantidad": 4,
        "precioSinIgv": "100.00",
        "precioConIgv": "118.00",
        "tipoTax": "Gravado (Con 18% de impuestos)",
        "totalBaseTax": "400.00",
        "totalTax": "72.00",
        "total": "472.00",
        "productoId": null
      },
      {
        "id": 39,
        "tipoUnidad": "NIU",
        "codigo": null,
        "nombre": "Producto espacial 2 interestelar",
        "cantidad": 10,
        "precioSinIgv": "100.00",
        "precioConIgv": "100.00",
        "tipoTax": "Gratuito (Producto gratuito)",
        "totalBaseTax": "1000.00",
        "totalTax": "0.00",
        "total": "1000.00",
        "productoId": null
      }
    ]
  }
}
```

Venta declarada

```json
{
  "status": "success",
  "data": {
    "id": 20,
    "declarada": true,
    "anulada": false,
    "serieDocumento": "B001",
    "numeroDocumento": "00000014",
    "observaciones": "*Observa fijamente hasta que le cae un poco de arena en el ojo*",
    "motivoAnulado": "Por favor anula esta venta",
    "tipoDocumento": "Boleta de venta electrónica",
    "fechaEmision": "2025-04-05",
    "horaEmision": "12:43:13",
    "moneda": "Soles",
    "metodoPago": "Contado",
    "cliente": {
      "id": 19,
      "tipoDocumento": "DNI",
      "numeroDocumento": "36569991",
      "denominacion": "John Cremin"
    },
    "empleado": {
      "id": 37,
      "nombre": "Administrador",
      "apellidos": "Principal"
    },
    "sucursal": {
      "id": 13,
      "nombre": "Sucursal Principal"
    },
    "totalesVenta": {
      "totalGravadas": "400.00",
      "totalExoneradas": "172.15",
      "totalGratuitas": "1000.00",
      "totalTax": "72.00",
      "totalVenta": "644.15"
    },
    "estado": {
      "codigo": "aceptado-sunat",
      "nombre": "Aceptado ante la sunat"
    },
    "documentoFacturacion": {
      "id": 5,
      "codigoEstadoSunat": "05",
      "factproDocumentId": "84205364-fcdb-41ba-8ebc-0cf527fc8ea2",
      "hash": "GUD7yqQZpJi0+C2YTxynais/clw=",
      "qr": "iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAIAAACzY+a1AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAEgElEQVR4nO2d224bMQxE46L//8vpi7HdYglmRFLrDvacR1u3eEBKoijl9f39/QXO/Pr0AKALEtqDhPYgoT1IaA8S2oOE9iChPUhoDxLag4T2IKE9v8Vyr9er31keUj93cZQM+71+e255ZKgh4pHADb/VGazQHiS0R3WkB4XzxdCxhD4w6e7cyLXB3AkXHHj47bVfcfA6BSeMFdqDhPYgoT3Lc+GZ3HGvzhNheXFTkXehz5TibHcUy+fRsEo+1AJYoT1IaE/LkXZYdSyhuxO3HGIX4Ye6q/wUWKE9SGjPxxypGEMRP9Rd3Gr4I3fg/wNYoT1IaA8S2tOaCztTQj4nrUZJwpLh1LV6mKy3nLNv+sQK7UFCe5Yd6XhmihiMDscgxrvvqZtHdvaBFdqDhPaojnR8QbXqKu/p91osZN/hXwGs0B4ktAcJ7XntSzJfXbUXzgTGWxa3DftydgrzKFZoDxLas+xIx1fM42mGI4huVv/2WkzvNwcrtAcJ7ZnJ5u6s33IKQZzV+0eFNEPxJLJw76kwYWGF9iChPUhoz/JJxT3RigNxy6Efva72myeyTm1mOu1ghfYgoT1qdOZvhW3ZIrpDW1155964ULeDmHejgxXag4T2tMLcq0l5++iczHWOQsMxdJ6bIcz9RJDQHiS0p7WpuDJ1/6hzsykf1WrLet3VI19OKuANEtqz7Ej/qawt0AtbjnFvkzRyZiTc0xk8jvSJIKE9G59X35e/3FnNjmRzi5GdqWklByu0BwntQUJ7WrkzSbEveV7Z9+6vSOcvCtsp7Jc4qXg0SGjPrVdEx/NfVkcStlNI1y941NUZgejMg0BCe4ZfQjy7izuD0Z21br6a1QffcZWsSB8NEtqDhPbMPJdQyGHJ6+6bOTqbmdVZ9p53E7BCe5DQnjueS7iWP38reqcfPxRHlZQPGT8uLrScgxXag4T2zPzPps56dTybW1zNjtzxn0okJMz9aJDQHiS0Z+NzCSNnuZ9KyB9Jqs8hIR/eIKE9M7kzHX+SU4gU5+5dbDms23lhIW+ETcWjQUJ7hq+IiuVDCt64EF5fZTzMPXVMeIAV2oOE9iChPcP/CHbc0edTyL53Z8LynaX/yKs0IVihPUhoz8yRb07nIudIMFrvQkzI70RYCveecrBCe5DQnuGbTSFiRvZUyl4nhtJZUV/rFt6dKXhUrNAeJLQHCe1pnVS0Oh6N43ReOysk5P9YUhkhCfnwBgnt2fiY5ZXcS9yTkL9aNx9qHnzXr2WRO/NokNCe5ehM53p7oR3RB3Zeh+ncQg3pLPJZkT4RJLQHCe2ZeS4hZPZRg7DlzppefINNP09Y3Xfx7gy8QUJ77sidKTASJQkRw80FRu49FcAK7UFCez7vSPcFlFeXpuGHevC9k69NEuKjQUJ7kNCeO/JIO60VHkQ4vu2cNuR0ZuhCgzlYoT1IaM/wFdEChbPfq6eaSui7dlfYcogpQlO/JFZoDxLa87FsbpgCK7QHCe1BQnuQ0B4ktAcJ7UFCe5DQHiS0BwntQUJ7kNAeJLTnD1dJEj9vdjPlAAAAAElFTkSuQmCC",
      "linkXml": "https://factpro.pe/downloads/document/10709842591/xml/84205364-fcdb-41ba-8ebc-0cf527fc8ea2",
      "linkPdf": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=a4",
      "linkCdr": "https://factpro.pe/downloads/document/10709842591/cdr/84205364-fcdb-41ba-8ebc-0cf527fc8ea2",
      "factproDocumentIdAnulado": null,
      "linkXmlAnulado": null,
      "linkPdfAnulado": null,
      "linkCdrAnulado": null,
      "ticketAnulado": null,
      "informacionSunat": {
        "code": "0",
        "notes": [],
        "description": "La Boleta numero B001-14, ha sido aceptada"
      },
      "linkPdfA4": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=a4",
      "linkPdfTicket": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=ticket"
    },
    "detallesVenta": [
      {
        "id": 37,
        "tipoUnidad": "NIU",
        "codigo": "0000098",
        "nombre": "Recycled Wooden Salad7",
        "cantidad": 1,
        "precioSinIgv": "172.15",
        "precioConIgv": "172.15",
        "tipoTax": "Exonerado (Sin impuestos)",
        "totalBaseTax": "172.15",
        "totalTax": "0.00",
        "total": "172.15",
        "productoId": 98
      },
      {
        "id": 38,
        "tipoUnidad": "NIU",
        "codigo": null,
        "nombre": "Producto espacial interestelar",
        "cantidad": 4,
        "precioSinIgv": "100.00",
        "precioConIgv": "118.00",
        "tipoTax": "Gravado (Con 18% de impuestos)",
        "totalBaseTax": "400.00",
        "totalTax": "72.00",
        "total": "472.00",
        "productoId": null
      },
      {
        "id": 39,
        "tipoUnidad": "NIU",
        "codigo": null,
        "nombre": "Producto espacial 2 interestelar",
        "cantidad": 10,
        "precioSinIgv": "100.00",
        "precioConIgv": "100.00",
        "tipoTax": "Gratuito (Producto gratuito)",
        "totalBaseTax": "1000.00",
        "totalTax": "0.00",
        "total": "1000.00",
        "productoId": null
      }
    ]
  }
}
```

## Response (fail 404)

### Body (fail 404 response)

```json
{
  "status": "fail",
  "error": "La venta no se encontró"
}
```
