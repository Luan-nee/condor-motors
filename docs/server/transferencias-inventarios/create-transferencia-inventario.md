# Crear venta

## Método: POST

## Endpoint

{{base_url}}/api/transferenciasinventario

## Descripción

Endpoint para crear una transferencia de inventario, al crear una transferencia de inventario el estado de estas será "pedido", y su creación no afectará el stock de productos de ninguna sucursal

## Explicación de los permisos

- El rol `administrador` es capaz de crear transferencias de inventario para cualquier sucursal
- El rol `vendedor` es capaz de crear transferencias de inventario pero solo para la sucursal a la que pertenece
- El rol `computadora` es capaz de crear transferencias de inventario pero solo para la sucursal a la que pertenece

## Request

### Body (request)

```jsonc
{
  "sucursalDestinoId": 13, // Si el rol del usuario no es administrador este id solo podrá ser la misma que la de la sucursal a la que este empleado pertenecer
  "items": [
    {
      "productoId": 95,
      "cantidad": 4,
    },
    {
      "productoId": 118,
      "cantidad": 1,
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
    "id": 14, // Id de la transferencia de inventario creada
    /* Lista de los detalles de los items registrados en la transferencia de inventario */
    "items": [
      {
        "id": 15, // Id del primer item de transferencia
      },
      {
        "id": 16,
      },
    ],
  },
}
```

## Response (fail 400)

### Body (fail 400 response)

```jsonc
{
  "status": "fail",
  "error": "El producto con el id 1181 no existe", // El mensaje de error varía dependiendo del tipo de error
}
```
