# 👥 API Empleados - Condors Motos

## Autenticación

### Login
```http
POST /api/empleados/login
Content-Type: application/x-www-form-urlencoded

username=admin&password=admin123
```

#### Respuesta Exitosa (200 OK)
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "empleado": {
        "id": 1,
        "nombre_completo": "Administrador Sistema",
        "rol": "ADMINISTRADOR",
        "usuario": "admin",
        "lugar": "Central"
    }
}
```

### Uso del Token
Incluir el token en todas las peticiones protegidas:
```http
GET /api/empleados
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## Endpoints Protegidos

### Listar Empleados
```http
GET /api/empleados
Authorization: Bearer {token}
```

#### Permisos
- ADMINISTRADOR: Acceso total
- COLABORADOR: Puede ver lista
- VENDEDOR: Solo su perfil
- COMPUTADORA: Sin acceso

### Obtener Empleado
```http
GET /api/empleados/{id}
Authorization: Bearer {token}
```

### Crear Empleado
```http
POST /api/empleados
Authorization: Bearer {token}
Content-Type: application/json

{
    "nombre_completo": "Juan Pérez",
    "dni": "12345678",
    "rol": "VENDEDOR",
    "usuario": "jperez",
    "clave": "clave123",
    "lugar": "Central",
    "sucursal_id": 1
}
```

## Implementación en Flutter

### Servicio de Autenticación
```dart
class AuthService {
  final ApiService _api;
  final SharedPreferences _prefs;

  AuthService(this._api, this._prefs);

  Future<void> login(String username, String password) async {
    try {
      final response = await _api.post(
        '/empleados/login',
        {'username': username, 'password': password},
        formUrlEncoded: true,
      );

      final token = response['access_token'];
      await _prefs.setString('token', token);
      await _api.setToken(token);
    } catch (e) {
      throw AuthException('Error de autenticación');
    }
  }

  Future<void> logout() async {
    await _prefs.remove('token');
    _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = _prefs.getString('token');
    return token != null;
  }
}
```

### Ejemplo de Uso
```dart
class LoginScreen extends StatelessWidget {
  final AuthService _authService;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      await _authService.login(
        _userController.text,
        _passController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
```

## Códigos de Error
- 401: No autorizado / Credenciales inválidas
- 403: Permiso denegado
- 404: Empleado no encontrado
- 422: Datos inválidos