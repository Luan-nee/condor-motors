import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Importar para KeyboardListener
import '../api/main.api.dart';
import '../routes/routes.dart';
import '../api/empleados.api.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _capsLockOn = false;
  bool _obscurePassword = true;
  final _empleadoApi = EmpleadoApi(ApiService());
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    
    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  // Manejar eventos del teclado
  bool _handleKeyEvent(KeyEvent event) {
    setState(() {
      _capsLockOn = HardwareKeyboard.instance.lockModesEnabled
          .contains(KeyboardLockMode.capsLock);
    });
    return false;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final username = _usernameController.text;
        final password = _passwordController.text;

        final userData = await _empleadoApi.login(username, password);
        
        if (!mounted) return;

        // Validar que el rol sea válido
        final rol = userData['empleado']['rol'].toString().toUpperCase();
        if (!EmpleadoApi.roles.containsKey(rol)) {
          throw Exception('Rol de usuario no válido');
        }

        // Navegar según el rol del empleado
        final route = Routes.getInitialRoute(rol);
        
        Navigator.pushReplacementNamed(
          context, 
          route,
          arguments: userData['empleado'],
        );

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController,
                  ),
                );
              },
            ),
          ),
          // Contenido del login
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // Logo actualizado
                        Center(
                          child: Container(
                            width: 250, // Ajustado para el logo
                            height: 250, // Ajustado para el logo
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Image.asset(
                              'assets/images/condor-motors-logo.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Título y subtítulo
                        const Text(
                          'Condors Motors',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Repuestos de Calidad',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Campo de usuario
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFE31E24)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Campo de contraseña
                        Focus(
                          focusNode: _focusNode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFE31E24)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: const Color(0xFFE31E24),
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Por favor ingrese su contraseña';
                                  }
                                  return null;
                                },
                              ),
                              if (_capsLockOn)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFE31E24),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bloq Mayús está activado',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botón de inicio de sesión
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _animationController.dispose();
    super.dispose();
  }
}

// Clase para dibujar el fondo
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  BackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Valor de animación para movimiento
    final animValue = animation.value;
    final wave = math.sin(animValue * math.pi * 2) * 20;
    final scale = 1 + math.sin(animValue * math.pi) * 0.1;

    // Dibujar formas geométricas con animación
    final path = Path();
    
    // Patrón superior izquierdo animado
    path.moveTo(0, wave);
    path.lineTo(size.width * 0.4 * scale, wave);
    path.lineTo(size.width * 0.3 * scale, size.height * 0.3 + wave);
    path.lineTo(0, size.height * 0.4 + wave);
    path.close();

    // Patrón inferior derecho animado
    path.moveTo(size.width, size.height - wave);
    path.lineTo(size.width * (0.6 + math.sin(animValue * math.pi) * 0.1), size.height - wave);
    path.lineTo(size.width * 0.7, size.height * 0.7 - wave);
    path.lineTo(size.width, size.height * 0.6 - wave);
    path.close();

    canvas.drawPath(path, paint);

    // Círculos decorativos animados
    final circlePaint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Círculos flotantes
    final circleOffset = math.sin(animValue * math.pi * 2) * 15;
    
    // Círculos superiores
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.cos(animValue * math.pi) * 10,
        size.height * 0.2 + circleOffset
      ),
      size.width * 0.15 * scale,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.9 - math.sin(animValue * math.pi) * 10,
        size.height * 0.1 - circleOffset
      ),
      size.width * 0.1 * scale,
      circlePaint,
    );

    // Círculos inferiores
    canvas.drawCircle(
      Offset(
        size.width * 0.2 - math.cos(animValue * math.pi) * 10,
        size.height * 0.8 - circleOffset
      ),
      size.width * 0.15 * scale,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.1 + math.sin(animValue * math.pi) * 10,
        size.height * 0.9 + circleOffset
      ),
      size.width * 0.1 * scale,
      circlePaint,
    );

    // Líneas decorativas animadas
    final linePaint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.05)
      ..strokeWidth = 2 + math.sin(animValue * math.pi) * 1
      ..style = PaintingStyle.stroke;

    // Líneas superiores con movimiento
    canvas.drawLine(
      Offset(size.width * 0.1 + wave, 0),
      Offset(size.width * 0.3 + wave, size.height * 0.2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2 - wave, 0),
      Offset(size.width * 0.4 - wave, size.height * 0.2),
      linePaint,
    );

    // Líneas inferiores con movimiento
    canvas.drawLine(
      Offset(size.width * 0.7 + wave, size.height),
      Offset(size.width * 0.9 + wave, size.height * 0.8),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8 - wave, size.height),
      Offset(size.width * 1.0 - wave, size.height * 0.8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return true;
  }
}
