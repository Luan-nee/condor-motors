import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:condorsmotors/repositories/pedido.repository.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:condorsmotors/screens/colabs/widgets/cliente/busqueda_cliente_form.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FormPedidoWidget extends StatefulWidget {
  final PedidoExclusivo? pedido;
  final VoidCallback onSave;

  const FormPedidoWidget({
    super.key,
    this.pedido,
    required this.onSave,
  });

  @override
  State<FormPedidoWidget> createState() => _FormPedidoWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PedidoExclusivo?>('pedido', pedido))
      ..add(ObjectFlagProperty<VoidCallback>.has('onSave', onSave));
  }
}

class _FormPedidoWidgetState extends State<FormPedidoWidget> {
  final _formKey = GlobalKey<FormState>();
  final PedidoRepository _repository = PedidoRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  final ClienteRepository _clienteRepository = ClienteRepository.instance;

  // Controladores para los campos del pedido
  final _descripcionController = TextEditingController();
  final _montoAdelantadoController = TextEditingController();
  final _fechaRecojoController = TextEditingController();
  final _denominacionController = TextEditingController();
  final _clienteIdController = TextEditingController();
  final _sucursalIdController = TextEditingController();
  final _nombreController = TextEditingController();

  // Lista de detalles de reserva
  List<DetalleReserva> _detallesReserva = [];

  DateTime? _fechaCreacion;
  List<Sucursal> _sucursales = [];
  bool _cargandoSucursales = false;
  List<Cliente> _clientes = [];
  bool _cargandoClientes = false;

  final ScrollController _detallesReservaScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
    _cargarSucursales();
    _cargarClientes();
  }

  void _inicializarFormulario() {
    if (widget.pedido != null) {
      _descripcionController.text = widget.pedido!.descripcion;
      _montoAdelantadoController.text =
          widget.pedido!.montoAdelantado.toString();
      _fechaRecojoController.text = widget.pedido!.fechaRecojo;
      _denominacionController.text = widget.pedido!.denominacion;
      _clienteIdController.text = widget.pedido!.clienteId.toString();
      _sucursalIdController.text = widget.pedido!.sucursalId.toString();
      _nombreController.text = widget.pedido!.nombre;
      _fechaCreacion = widget.pedido!.fechaCreacion;
      _detallesReserva = List.from(widget.pedido!.detallesReserva);
    } else {
      _fechaCreacion = DateTime.now();
      _detallesReserva = [
        const DetalleReserva(
          total: 0,
          cantidad: 1,
          precioVenta: 0,
          precioCompra: 0,
          nombreProducto: '',
        ),
      ];
    }
  }

  Future<void> _cargarSucursales() async {
    setState(() => _cargandoSucursales = true);
    try {
      final sucursales = await _sucursalRepository.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _cargandoSucursales = false;
      });
    } catch (e) {
      setState(() => _cargandoSucursales = false);
    }
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargandoClientes = true);
    try {
      final clientes = await _clienteRepository.getClientes(
          pageSize: 100, sortBy: 'denominacion');
      setState(() {
        _clientes = clientes;
        _cargandoClientes = false;
      });
    } catch (e) {
      setState(() => _cargandoClientes = false);
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoAdelantadoController.dispose();
    _fechaRecojoController.dispose();
    _denominacionController.dispose();
    _clienteIdController.dispose();
    _sucursalIdController.dispose();
    _nombreController.dispose();
    _detallesReservaScrollController.dispose();
    super.dispose();
  }

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar detalles de reserva
    for (var detalle in _detallesReserva) {
      if (detalle.nombreProducto.isEmpty || detalle.cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Complete todos los campos de los detalles de reserva'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {});

    try {
      final pedido = PedidoExclusivo(
        id: widget.pedido?.id,
        descripcion: _descripcionController.text,
        detallesReserva: _detallesReserva,
        montoAdelantado: double.tryParse(_montoAdelantadoController.text) ?? 0,
        fechaRecojo: _fechaRecojoController.text,
        denominacion: _denominacionController.text,
        clienteId: int.tryParse(_clienteIdController.text) ?? 0,
        sucursalId: int.tryParse(_sucursalIdController.text) ?? 0,
        nombre: _nombreController.text,
        fechaCreacion: _fechaCreacion ?? DateTime.now(),
      );

      if (widget.pedido == null) {
        await _repository.createPedidoExclusivo(pedido);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido exclusivo creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (widget.pedido!.id != null) {
          await _repository.updatePedidoExclusivo(
            widget.pedido!.id!,
            pedido,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pedido exclusivo actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      logError('Error al guardar pedido exclusivo', e);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _agregarDetalle() {
    setState(() {
      _detallesReserva.add(
        const DetalleReserva(
          total: 0,
          cantidad: 1,
          precioVenta: 0,
          precioCompra: 0,
          nombreProducto: '',
        ),
      );
    });
  }

  void _eliminarDetalle(int index) {
    setState(() {
      _detallesReserva.removeAt(index);
    });
  }

  void _actualizarDetalle(int index, DetalleReserva detalle) {
    setState(() {
      _detallesReserva[index] = detalle;
    });
  }

  Future<void> _abrirDialogoAgregarCliente() async {
    final nuevoCliente = await showDialog<Cliente>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF232323),
        child: SizedBox(
          width: 500,
          child: BusquedaClienteForm(
            onClienteCreado: (cliente) {
              Navigator.of(context).pop(cliente);
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
    if (nuevoCliente != null) {
      setState(() {
        _clientes.add(nuevoCliente);
        _clienteIdController.text = nuevoCliente.id.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        padding: EdgeInsets.zero,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF232323),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.boxOpen,
                        color: Colors.red, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      widget.pedido == null
                          ? 'NUEVO PEDIDO EXCLUSIVO'
                          : 'EDITAR PEDIDO EXCLUSIVO',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // TabBar
              Container(
                color: const Color(0xFF232323),
                child: const TabBar(
                  indicatorColor: Color(0xFFE31E24),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(
                        icon: FaIcon(FontAwesomeIcons.circleInfo),
                        text: 'Datos Generales'),
                    Tab(
                        icon: FaIcon(FontAwesomeIcons.list),
                        text: 'Detalles Reserva'),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: TabBarView(
                      children: [
                        // Pestaña 1: Datos Generales
                        if (isWide) Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildInfoBasica(context)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildFechasMonto(context)),
                                ],
                              ) else Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoBasica(context),
                                  const SizedBox(height: 24),
                                  _buildFechasMonto(context),
                                ],
                              ),
                        // Pestaña 2: Detalles de la Reserva
                        _buildDetallesReservaSection(context),
                      ],
                    ),
                  ),
                ),
              ),
              // Acciones
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCELAR',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      onPressed: _guardarPedido,
                      child: Text(
                          widget.pedido == null ? 'GUARDAR' : 'ACTUALIZAR'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBasica(BuildContext context) {
    return Card(
      color: const Color(0xFF232323),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.circleInfo,
                    color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Información Básica',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Descripción', Icons.description),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingrese la descripción'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _denominacionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Denominación', Icons.label),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingrese la denominación'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _cargandoClientes
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _clienteIdController.text.isNotEmpty
                              ? _clienteIdController.text
                              : null,
                          items: _clientes.map((cliente) {
                            return DropdownMenuItem<String>(
                              value: cliente.id.toString(),
                              child: Text(
                                '${cliente.denominacion} (${cliente.numeroDocumento})',
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _clienteIdController.text = value ?? '';
                            });
                          },
                          decoration: _inputDecoration('Cliente', Icons.person),
                          dropdownColor: const Color(0xFF232323),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Seleccione un cliente'
                              : null,
                        ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.red),
                    tooltip: 'Agregar cliente',
                    onPressed: _abrirDialogoAgregarCliente,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cargandoSucursales) const Center(child: CircularProgressIndicator()) else DropdownButtonFormField<String>(
                    value: _sucursalIdController.text.isNotEmpty
                        ? _sucursalIdController.text
                        : null,
                    items: _sucursales.map((sucursal) {
                      return DropdownMenuItem<String>(
                        value: sucursal.id,
                        child: Text(sucursal.nombre,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sucursalIdController.text = value ?? '';
                      });
                    },
                    decoration: _inputDecoration('Sucursal', Icons.store),
                    dropdownColor: const Color(0xFF232323),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Seleccione una sucursal'
                        : null,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechasMonto(BuildContext context) {
    return Card(
      color: const Color(0xFF232323),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.calendarDays,
                    color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Fechas y Monto',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaRecojoController.text.isNotEmpty
                      ? DateTime.tryParse(_fechaRecojoController.text) ??
                          DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFE31E24),
                          onPrimary: Colors.white,
                          surface: Color(0xFF232323),
                        ),
                        dialogTheme: const DialogThemeData(
                            backgroundColor: Color(0xFF1A1A1A)),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _fechaRecojoController.text =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _fechaRecojoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                      'Fecha de Recojo (YYYY-MM-DD)', Icons.calendar_today),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingrese la fecha de recojo'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoAdelantadoController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  _inputDecoration('Monto Adelantado', Icons.attach_money)
                      .copyWith(
                          prefixText: 'S/ ',
                          prefixStyle: const TextStyle(color: Colors.white)),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingrese el monto adelantado'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesReservaSection(BuildContext context) {
    return Card(
      color: const Color(0xFF232323),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.list, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Detalles de la Reserva',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            // La tabla ahora es scrollable y ocupa el espacio disponible
            Expanded(child: _buildDetallesReservaTable(context)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                ),
                onPressed: _agregarDetalle,
                icon: const Icon(Icons.add),
                label: const Text('Agregar ítem'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesReservaTable(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Scrollbar(
        controller: _detallesReservaScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _detallesReservaScrollController,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A1A)),
            dataRowColor: WidgetStateProperty.all(const Color(0xFF232323)),
            columnSpacing: 16,
            columns: const [
              DataColumn(
                  label:
                      Text('Producto', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label:
                      Text('Cantidad', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Precio Venta',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Precio Compra',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Total', style: TextStyle(color: Colors.white))),
              DataColumn(
                  label:
                      Text('Acciones', style: TextStyle(color: Colors.white))),
            ],
            rows: List.generate(_detallesReserva.length, (index) {
              final detalle = _detallesReserva[index];
              return DataRow(
                cells: [
                  DataCell(
                    TextFormField(
                      initialValue: detalle.nombreProducto,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (value) => _actualizarDetalle(
                          index, detalle.copyWith(nombreProducto: value)),
                    ),
                  ),
                  DataCell(
                    TextFormField(
                      initialValue: detalle.cantidad.toString(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _actualizarDetalle(index,
                          detalle.copyWith(cantidad: int.tryParse(value) ?? 1)),
                    ),
                  ),
                  DataCell(
                    TextFormField(
                      initialValue: detalle.precioVenta.toString(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        prefixText: 'S/ ',
                        prefixStyle: TextStyle(color: Colors.white70),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _actualizarDetalle(
                          index,
                          detalle.copyWith(
                              precioVenta: double.tryParse(value) ?? 0)),
                    ),
                  ),
                  DataCell(
                    TextFormField(
                      initialValue: detalle.precioCompra.toString(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        prefixText: 'S/ ',
                        prefixStyle: TextStyle(color: Colors.white70),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _actualizarDetalle(
                          index,
                          detalle.copyWith(
                              precioCompra: double.tryParse(value) ?? 0)),
                    ),
                  ),
                  DataCell(
                    TextFormField(
                      initialValue: detalle.total.toString(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        prefixText: 'S/ ',
                        prefixStyle: TextStyle(color: Colors.white70),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _actualizarDetalle(index,
                          detalle.copyWith(total: double.tryParse(value) ?? 0)),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _detallesReserva.length > 1
                          ? () => _eliminarDetalle(index)
                          : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE31E24), width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF232323),
    );
  }
}
