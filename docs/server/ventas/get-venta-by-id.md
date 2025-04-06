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

```jsonc
{
  "status": "success",
  "data": {
    "id": 20,
    "declarada": false,
    "anulada": false,
    "cancelada": false,
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
      "denominacion": "John Cremin",
    },
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
        "productoId": 98,
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
        "productoId": null,
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
        "productoId": null,
      },
    ],
  },
}
```

Venta declarada

```jsonc
{
  "status": "success",
  "data": {
    "id": 20,
    "declarada": true,
    "anulada": false,
    "cancelada": false,
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
      "denominacion": "John Cremin",
    },
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
        "description": "La Boleta numero B001-14, ha sido aceptada",
      },
      "linkPdfA4": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=a4",
      "linkPdfTicket": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f1759d562106550bee64f0?type=ticket",
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
        "productoId": 98,
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
        "productoId": null,
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
        "productoId": null,
      },
    ],
  },
}
```

Venta anulada

```jsonc
{
  "status": "success",
  "data": {
    "id": 21,
    "declarada": true,
    "anulada": true,
    "cancelada": true,
    "serieDocumento": "B001",
    "numeroDocumento": "00000015",
    "observaciones": "*Observa fijamente hasta que le cae un poco de arena en el ojo*",
    "motivoAnulado": "Por favor anula esta venta",
    "tipoDocumento": "Boleta de venta electrónica",
    "fechaEmision": "2025-04-05",
    "horaEmision": "15:20:29",
    "moneda": "Soles",
    "metodoPago": "Contado",
    "cliente": {
      "id": 19,
      "tipoDocumento": "DNI",
      "numeroDocumento": "36569991",
      "denominacion": "John Cremin",
    },
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
      "factproDocumentId": "a10988da-6fd2-40ac-8ba3-f106cc457d0e",
      "hash": "7v/WZo6wSDQlMXLvMuYnGqkCPWo=",
      "qr": "iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAIAAACzY+a1AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAEgklEQVR4nO2d227jMAxEm8X+/y933wKj1tLDi5wOfM5jIktqB6QkklZe39/fX+DMn09PALogoT1IaA8S2oOE9iChPUhoDxLag4T2IKE9SGgPEtrzV2z3er36g8Uh9eMQ75bLcc/f6sH6zh8ijnLD/+oIVmgPEtqjOtI3hfzi0rGIPnDpUc8dxk74OMR5uOWzy2/P44qT1yk4YazQHiS0BwntSa+FR2LHnV0nlu3FQ4U+gXg9E1e7d7N4HY3HvRxFBCu0BwntaTnSDlnHsnR38ZFj6Z2y7l13lZ8CK7QHCe35mCMVQ9Xih0s3u+w5G/6IHfhvACu0BwntQUJ7WmthZ0mI16RslGRqVvtSzfuWT6zQHiS0J+1IRwpDjix9V+zQ4uhM0Oxy3Jh43Diysw+s0B4ktEd1pOMbqo4PzKK76HOzyw6zz46DFdqDhPYgoT2vfUXm2V37PTmBuGfx2CCuhXp1a+fvxQrtQUJ7ZgryO3GQcZeVnXOM7u6y5fpTsRus0B4ktEfdka4fTjqWmCm3I/YjhqrjORSWlc63S7BCe5DQHiS054460sKq80asjslW4nz11qRCujim0w9WaA8S2tM6VFx0nYyYFILCYs/LUe68ROZIZ1lZghXag4T2tPKF2RzYeMlJJwje2VVOBVZGnsUK7UFCe5DQnjvqSEciLIXbzsYzBvH7wyLxzXBkKp4IEtozfIFX4Z3NfWUvYvtllESMbusRpX1ghfYgoT3Dr4gWdncFRIc2shGNey7kKQlzw0+Q0B4ktGcmU7GPfRnXeIjCShk/G3Tyvw9FsEJ7kNCetCPVQy3Z+pebC/IL7cX4S6fehzD3E0FCe35RNbf+iuhs/WA8K92hdVwlO9JHg4T2IKE9w7UzhU12oef4YNB5j/fM1PotNuNQ8USQ0J70m037nFKBTnlj4TWBkXTxEg4VjwYJ7Zm5CXE8Q5a94WVqVp1vswH0wqyWYIX2IKE9SGhPOjqjp17Fq1vO7eNmlz1nOxw/6sQTGB8LK7QHCe2ZSfkWLlPokI2MH6cnTqaQphahIB9+goT2DF/gNfWK6EjubTmBrOsbD3OPb1OxQnuQ0B4ktKf1lq9Yddm5oU2sNLmcQ8B4QX7cz3juFyu0BwntGS7IH793ZiTuU7h3JvhkOQF9VuOXR2CF9iChPTZh7tjtxBPQd8IjxTjirAqxmyVYoT1IaA8S2rPxp0YuBp6oulz2lg1/TGU5Otc0UJD/aJDQHvVQMXKRlh7pEJ/tzGpfqjlbfbnskDD3g0BCe9LRmc7bOoV+ClUq4gTiITpx86kglAhWaA8S2oOE9gz/1MiRznIS09mCj1zxoBfyiD2f4VDxIJDQnjsusyyQTYGO1+wU6KRtO2CF9iChPZ93pIVXNcVOxHCzXkg4kvOjCBF+goT2IKE9rbVw9kJKPakr3h2zb5c/frMvdaSPBgntGf4h2ALiPSzx9r3zbadsvnCoGHfvWKE9SGjPx6q5YQqs0B4ktAcJ7UFCe5DQHiS0BwntQUJ7kNAeJLQHCe1BQnuQ0J5/+BbZMMYpQzwAAAAASUVORK5CYII=",
      "linkXml": "https://factpro.pe/downloads/document/10709842591/xml/a10988da-6fd2-40ac-8ba3-f106cc457d0e",
      "linkPdf": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=a4",
      "linkCdr": "https://factpro.pe/downloads/document/10709842591/cdr/a10988da-6fd2-40ac-8ba3-f106cc457d0e",
      "factproDocumentIdAnulado": "8301d4fd-e87c-4d81-bdf8-5982f158dbb4",
      "linkXmlAnulado": "https://factpro.pe/downloads/summary/10709842591/xml/8301d4fd-e87c-4d81-bdf8-5982f158dbb4",
      "linkPdfAnulado": "https://cpe.factpro.la/summary/67dcb02df91586b81056d566/pdf/67f19220562106550bee90d2",
      "linkCdrAnulado": "",
      "ticketAnulado": "1743883638859",
      "informacionSunat": {
        "code": "0",
        "notes": [],
        "description": "La Boleta numero B001-15, ha sido aceptada",
      },
      "linkPdfA4": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=a4",
      "linkPdfTicket": "https://cpe.factpro.la/documents/67dcb02df91586b81056d566/print/pdf/67f190ac562106550bee8f62?type=ticket",
    },
    "detallesVenta": [
      {
        "id": 40,
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
        "productoId": 98,
      },
      {
        "id": 41,
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
        "productoId": null,
      },
      {
        "id": 42,
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
        "productoId": null,
      },
    ],
  },
}
```

## Response (fail 404)

### Body (fail 404 response)

```jsonc
{
  "status": "fail",
  "error": "La venta no se encontró",
}
```
