import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BusquedaClienteForm extends StatefulWidget {
  final Function(Cliente) onClienteCreado;
  final VoidCallback onCancel;
  final VoidCallback? onRefrescarClientes;

  const BusquedaClienteForm({
    super.key,
    required this.onClienteCreado,
    required this.onCancel,
    this.onRefrescarClientes,
  });

  @override
  State<BusquedaClienteForm> createState() => _BusquedaClienteFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<Function(Cliente p1)>.has(
          'onClienteCreado', onClienteCreado))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel))
      ..add(ObjectFlagProperty<VoidCallback?>.has(
          'onRefrescarClientes', onRefrescarClientes));
  }
}

class _BusquedaClienteFormState extends State<BusquedaClienteForm> {
  late final ClienteRepository _repository;
  final TextEditingController denominacionController = TextEditingController();
  final TextEditingController numeroDocumentoController =
      TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int tipoDocumentoSeleccionado = 2; // Por defecto DNI
  bool _buscandoDatos = false;

  // Mapa de tipos de documento
  final Map<int, String> tiposDocumento = {
    1: 'RUC',
    2: 'DNI',
    3: 'Carnet de Extranjería',
    4: 'Pasaporte',
    5: 'Cédula Diplomática',
    6: 'Otro Documento',
    7: 'PTP',
    8: 'Carnet de Identidad',
  };

  // Obtener el tipo de documento por defecto basado en la longitud

  @override
  void initState() {
    super.initState();
    _repository = ClienteRepository(api.clientes);
  }

  @override
  void dispose() {
    denominacionController.dispose();
    numeroDocumentoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    correoController.dispose();
    super.dispose();
  }

  // Función para formatear el número de teléfono
  String? formatearTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    // Mantener solo números y el símbolo +
    String numero = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!numero.startsWith('+')) {
      numero = '+51$numero';
    }
    return numero;
  }

  // Función para buscar datos del cliente
  Future<void> buscarDatosCliente(String numeroDocumento) async {
    try {
      setState(() => _buscandoDatos = true);

      final datos = await _repository.buscarClientePorDoc(numeroDocumento);

      if (datos != null) {
        setState(() {
          // Actualizar tipo de documento según lo que viene del servidor
          tipoDocumentoSeleccionado = datos['tipoDocumentoId'];
          denominacionController.text = datos['denominacion'] ?? '';
          direccionController.text = datos['direccion'] ?? '';
        });

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos del cliente encontrados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar datos: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buscandoDatos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Encabezado con título e icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nuevo Cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector de tipo de documento actualizado
            DropdownButtonFormField<int>(
              initialValue: tipoDocumentoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Documento *',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.badge, color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: 'Campo obligatorio',
                helperStyle: TextStyle(color: Colors.white38),
              ),
              dropdownColor: const Color(0xFF2D2D2D),
              style: const TextStyle(color: Colors.white),
              items: tiposDocumento.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    tipoDocumentoSeleccionado = value;
                    // Limpiar el campo de número de documento
                    numeroDocumentoController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Campo de número de documento
            TextFormField(
              controller: numeroDocumentoController,
              decoration: InputDecoration(
                labelText: 'Número de Documento *',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.pin, color: Colors.white70),
                suffixIcon: _buscandoDatos
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: tipoDocumentoSeleccionado == 2
                    ? 'DNI: 8 dígitos numéricos'
                    : tipoDocumentoSeleccionado == 1
                        ? 'RUC: 11 dígitos, debe empezar con 10 o 20'
                        : tipoDocumentoSeleccionado == 3
                            ? 'CE: 8-12 caracteres alfanuméricos'
                            : 'Pasaporte: 6-12 caracteres alfanuméricos',
                helperStyle: const TextStyle(color: Colors.white38),
                counterText: '',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: tipoDocumentoSeleccionado == 4 ||
                      tipoDocumentoSeleccionado == 3
                  ? TextInputType.text
                  : TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(tipoDocumentoSeleccionado == 1
                    ? 11
                    : tipoDocumentoSeleccionado == 2
                        ? 8
                        : tipoDocumentoSeleccionado == 3
                            ? 12
                            : 12),
              ],
              textCapitalization: tipoDocumentoSeleccionado == 4 ||
                      tipoDocumentoSeleccionado == 3
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              onChanged: (value) {
                // Buscar datos automáticamente cuando se completa el número
                if ((tipoDocumentoSeleccionado == 1 && value.length == 11) ||
                    (tipoDocumentoSeleccionado == 2 && value.length == 8)) {
                  buscarDatosCliente(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }

                switch (tipoDocumentoSeleccionado) {
                  case 1: // RUC
                    if (value.length != 11) {
                      return 'El RUC debe tener 11 dígitos';
                    }
                    if (!RegExp(r'^[12][0]\d{9}$').hasMatch(value)) {
                      return 'El RUC debe comenzar con 10 o 20';
                    }
                  case 2: // DNI
                    if (value.length != 8) {
                      return 'El DNI debe tener 8 dígitos';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'El DNI solo debe contener números';
                    }
                  case 3: // Carnet de Extranjería
                    if (value.length < 8 || value.length > 12) {
                      return 'El CE debe tener entre 8 y 12 caracteres';
                    }
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
                      return 'El CE solo debe contener números y letras';
                    }
                  case 4: // Pasaporte
                    if (value.length < 6 || value.length > 12) {
                      return 'El Pasaporte debe tener entre 6 y 12 caracteres';
                    }
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
                      return 'El Pasaporte solo debe contener números y letras';
                    }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de nombre/razón social
            TextFormField(
              controller: denominacionController,
              decoration: const InputDecoration(
                labelText: 'Nombre/Razón Social *',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person, color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: 'Campo obligatorio - Mínimo 3 caracteres',
                helperStyle: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                if (value.length < 3) {
                  return 'Debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de teléfono modificado
            TextFormField(
              controller: telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (Opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.phone, color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: 'Formato: +51 999999999 (Opcional)',
                helperStyle: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final String numero = value.replaceAll(RegExp(r'\s+'), '');
                  if (!RegExp(r'^\+?51\d{9}$')
                      .hasMatch(numero.replaceAll(RegExp(r'\s+'), ''))) {
                    return 'Ingrese un número peruano válido o deje el campo vacío';
                  }
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty && !value.startsWith('+51')) {
                  // Solo formatear si el usuario está ingresando un número
                  final String numeroLimpio =
                      value.replaceAll(RegExp(r'[^\d]'), '');
                  if (numeroLimpio.isNotEmpty) {
                    telefonoController
                      ..text = '+51 ${numeroLimpio.replaceAll('+51', '')}'
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: telefonoController.text.length),
                      );
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Campo de dirección
            TextFormField(
              controller: direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección (Opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.location_on, color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: 'Campo opcional - Máximo 100 caracteres',
                helperStyle: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),

            // Campo de correo electrónico
            TextFormField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico (Opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.email, color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                helperText: 'Campo opcional - ejemplo@dominio.com',
                helperStyle: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Ingrese un correo válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // Crear el mapa de datos del cliente solo con campos requeridos
                        final Map<String, dynamic> clienteData = {
                          'tipoDocumentoId': tipoDocumentoSeleccionado,
                          'numeroDocumento':
                              numeroDocumentoController.text.toUpperCase(),
                          'denominacion': denominacionController.text.trim(),
                        };

                        // Agregar campos opcionales solo si tienen valor
                        final String telefono = telefonoController.text.trim();
                        if (telefono.isNotEmpty) {
                          final String? telefonoFormateado =
                              formatearTelefono(telefono);
                          if (telefonoFormateado != null) {
                            clienteData['telefono'] = telefonoFormateado;
                          }
                        }

                        final String direccion =
                            direccionController.text.trim();
                        if (direccion.isNotEmpty) {
                          clienteData['direccion'] = direccion;
                        }

                        final String correo = correoController.text.trim();
                        if (correo.isNotEmpty) {
                          clienteData['correo'] = correo;
                        }

                        // Crear cliente usando el repositorio
                        final nuevoCliente =
                            await _repository.crearCliente(clienteData);

                        // Notificar al padre sobre el cliente creado
                        widget.onClienteCreado(nuevoCliente);

                        // Si se provee, refresca la lista global de clientes
                        widget.onRefrescarClientes?.call();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al crear cliente: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextEditingController>(
          'denominacionController', denominacionController))
      ..add(DiagnosticsProperty<TextEditingController>(
          'numeroDocumentoController', numeroDocumentoController))
      ..add(DiagnosticsProperty<TextEditingController>(
          'telefonoController', telefonoController))
      ..add(DiagnosticsProperty<TextEditingController>(
          'direccionController', direccionController))
      ..add(DiagnosticsProperty<TextEditingController>(
          'correoController', correoController))
      ..add(DiagnosticsProperty<GlobalKey<FormState>>('formKey', formKey))
      ..add(IntProperty('tipoDocumentoSeleccionado', tipoDocumentoSeleccionado))
      ..add(DiagnosticsProperty<Map<int, String>>(
          'tiposDocumento', tiposDocumento));
  }
}
