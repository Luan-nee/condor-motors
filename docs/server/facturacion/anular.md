# Anular venta

## Método: POST

## Endpoint

{{base_url}}/api/facturacion/anular

## Descripción

Este endpoint permite anular ante sunat una venta realizada, siempre en cuando esta haya sido declarada y cancelada
Al realizar la accion de forma exitosa los datos de la venta se actualizarán, y a partir de ese momento tendrá información acerca del documento que certifica su anulación en la propiedad documento de la respuesta, se actualizarán las siguientes propiedades:

- linkXmlAnulado
- linkPdfAnulado
- linkCdrAnulado (esta propiedad no se generará de inmediato)
- ticketAnulado

Además el estado de la anulación no será directamente anulada, en su lugar se encontrará en un estado de "por-anular"
esto significa que el sistema de sunat aún no aprobó la anulación, pero en un futuro este estado puede cambiar
para que eso suceda el usuario debe solicitar actualizar el documento
para más detalles acerca de eso revisar la documentación acerca de "sincronizar" en facturación

## Explicación de los permisos

El rol `administrador` es capaz de anular una venta en cualquier sucursal
El rol `vendedor` es capaz de anular ventas pero solo en la sucursal a la que pertenece
El rol `computadora` es capaz de anular ventas pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```jsonc
{
  "ventaId": 21,
}
```

## Response (success 200)

### Body (success 200 response)

```jsonc
{
  "status": "success",
  "data": {
    "id": 6, // Id del documento de facturación anulado, este es el mismo que está vinculado a la venta cuando esta se declara
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "No se encontró la venta con id 21 en la sucursal especificada", // El mensaje de error varía dependiendo del tipo de error
}
```

## Response (fail 401)

### Body (fail 401 response)

```jsonc
{
  "status": "fail",
  "error": "Token de facturación inválido",
}
```

## Response (error 500)

### Body (error 500 response)

```jsonc
{
  "status": "error",
  "error": "El servicio de facturación no se encuentra activo en este momento",
}
```

## Response (error 503)

### Body (error 503 response)

```jsonc
{
  "status": "fail",
  "error": "No se especificó un token de facturación, por lo que no se puede utilizar este servicio.",
}
```
