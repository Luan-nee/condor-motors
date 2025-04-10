# Comparar Transferencia de Inventario

Permite comparar el stock actual y resultante entre la sucursal origen y destino para una transferencia de inventario.

## Endpoint

```http
POST /api/transferenciasInventario/{id}/comparar
```

## Parámetros de URL

| Parámetro | Tipo    | Descripción                          |
| --------- | ------- | ------------------------------------ |
| id        | integer | ID de la transferencia de inventario |

## Body de la Petición

```json
{
  "sucursalOrigenId": 123 // ID de la sucursal origen
}
```

### Campos del Body

| Campo            | Tipo    | Requerido | Descripción              |
| ---------------- | ------- | --------- | ------------------------ |
| sucursalOrigenId | integer | Sí        | ID de la sucursal origen |

## Respuesta Exitosa

```json
{
  "status": "success",
  "data": {
    "sucursalOrigen": {
      "id": 123,
      "nombre": "Sucursal A"
    },
    "sucursalDestino": {
      "id": 456,
      "nombre": "Sucursal B"
    },
    "productos": [
      {
        "productoId": 8,
        "nombre": "Producto Ejemplo",
        "stockOrigenActual": 128,
        "stockOrigenResultante": 116,
        "stockDestinoActual": 50,
        "stockMinimo": 26,
        "cantidadSolicitada": 12,
        "stockDisponible": true,
        "stockBajoEnOrigen": false
      }
    ]
  }
}
```

### Campos de la Respuesta

| Campo                  | Tipo    | Descripción                                      |
| ---------------------- | ------- | ------------------------------------------------ |
| sucursalOrigen.id      | integer | ID de la sucursal origen                         |
| sucursalOrigen.nombre  | string  | Nombre de la sucursal origen                     |
| sucursalDestino.id     | integer | ID de la sucursal destino                        |
| sucursalDestino.nombre | string  | Nombre de la sucursal destino                    |
| productos              | array   | Lista de productos incluidos en la transferencia |

### Campos de cada Producto

| Campo                 | Tipo    | Descripción                                                   |
| --------------------- | ------- | ------------------------------------------------------------- |
| productoId            | integer | ID del producto                                               |
| nombre                | string  | Nombre del producto                                           |
| stockOrigenActual     | integer | Stock actual en la sucursal origen                            |
| stockOrigenResultante | integer | Stock que quedará en origen después de la transferencia       |
| stockDestinoActual    | integer | Stock actual en la sucursal destino                           |
| stockMinimo           | integer | Stock mínimo configurado para el producto                     |
| cantidadSolicitada    | integer | Cantidad que se desea transferir                              |
| stockDisponible       | boolean | Indica si hay suficiente stock para realizar la transferencia |
| stockBajoEnOrigen     | boolean | Indica si el stock resultante quedará por debajo del mínimo   |

## Posibles Errores

| Código HTTP | Descripción                                                |
| ----------- | ---------------------------------------------------------- |
| 400         | La transferencia no existe                                 |
| 400         | La sucursal origen no existe                               |
| 400         | La sucursal destino no existe                              |
| 400         | La transferencia no tiene productos para ser transferidos  |
| 400         | Producto no existe en la sucursal origen                   |
| 400         | La transferencia ya ha sido atendida                       |
| 400         | La sucursal origen y destino no pueden ser la misma        |
| 401         | No autorizado - Token inválido o expirado                  |
| 403         | Forbidden - No tiene permisos para realizar esta operación |

## Ejemplo de Uso

### Petición

```http
POST /api/transferencias-inventario/123/comparar
Content-Type: application/json
Authorization: Bearer <token>
{
  "sucursalOrigenId": 456
}

```

### Respuesta

```json
{
  "status": "success",
  "data": {
    "sucursalOrigen": {
      "id": 3,
      "nombre": "Cremin, Hirthe and Hessel2"
    },
    "sucursalDestino": {
      "id": 1,
      "nombre": "Sucursal Principal"
    },
    "procesable": true,
    "productos": [
      {
        "productoId": 1,
        "nombre": "Practical Steel Gloves0",
        "cantidadSolicitada": 10,
        "origen": {
          "stockActual": 136,
          "stockDespues": 126,
          "stockMinimo": 30,
          "stockBajoDespues": false
        },
        "destino": {
          "stockActual": 138,
          "stockDespues": 148
        },
        "procesable": true
      },
      {
        "productoId": 2,
        "nombre": "Oriental Silk Sausages1",
        "cantidadSolicitada": 5,
        "origen": {
          "stockActual": 62,
          "stockDespues": 57,
          "stockMinimo": 27,
          "stockBajoDespues": false
        },
        "destino": {
          "stockActual": 88,
          "stockDespues": 93
        },
        "procesable": true
      }
    ]
  }
}
```

## Notas Adicionales

- Se requiere autenticación mediante token JWT.
- Se necesitan permisos específicos para realizar la comparación:
  - `transferenciasInvs.sendAny`: Para comparar transferencias de cualquier sucursal
  - `transferenciasInvs.sendRelated`: Para comparar transferencias de sucursales relacionadas
- La comparación no modifica ningún dato, solo muestra información del estado actual.
