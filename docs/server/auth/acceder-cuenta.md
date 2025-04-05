# Acceder cuenta

## Endpoint: {{base_url}}/api/auth/login

Endpoint para iniciar sesión con las credenciales del usuario

## Request

### Body (request)

```json
{
  "usuario": "Administrador",
  "clave": "Admin123"
}
```

## Response (success)

### Body (success response )

```json
{
  "status": "success",
  "data": {
    "id": 7,
    "usuario": "Administrador",
    "rolCuentaEmpleadoId": 10,
    "rolCuentaEmpleadoCodigo": "administrador",
    "empleadoId": 28,
    "fechaCreacion": "2025-03-29T10:32:53.675Z",
    "fechaActualizacion": "2025-03-29T10:32:53.675Z",
    "sucursal": "Sucursal Principal",
    "sucursalId": 10
  }
}
```

### Headers (success response)

access_token
Authorization: Json Web Token que se utiliza para identificar al usuario en cada petición,
este debe ser enviado si se requiere acceder a una ruta protegida

### Cookies (success response)

refresh_token: Json Web Token que se utiliza para obtener un nuevo token de acceso cuando el actual vence

## Response (fail)

### Body (fail response)

```json
{
  "status": "fail",
  "error": "Nombre de usuario o contraseña incorrectos"
}
```

### Cookies (fail response)

Ninguna cookie
