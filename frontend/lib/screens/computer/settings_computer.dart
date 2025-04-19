import 'package:condorsmotors/providers/computer/ventas.computer.provider.dart';
import 'package:condorsmotors/providers/print.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SettingsComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const SettingsComputerScreen({
    super.key,
    this.sucursalId,
    this.nombreSucursal = 'Todas las sucursales',
  });

  @override
  State<SettingsComputerScreen> createState() => _SettingsComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('sucursalId', sucursalId))
      ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _SettingsComputerScreenState extends State<SettingsComputerScreen> {
  late VentasComputerProvider _ventasProvider;

  @override
  void initState() {
    super.initState();
    _ventasProvider =
        Provider.of<VentasComputerProvider>(context, listen: false);
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    await _ventasProvider.cargarConfiguracionImpresion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VentasComputerProvider>(
        builder: (context, ventasProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImpresionSettings(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.gear,
            color: Color(0xFFE31E24),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.nombreSucursal != 'Todas las sucursales') ...[
            const SizedBox(width: 12),
            Text(
              '- ${widget.nombreSucursal}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpresionSettings() {
    // Usar PrintProvider directamente
    final printProvider = PrintProvider.instance;

    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                FaIcon(
                  FontAwesomeIcons.print,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
                SizedBox(width: 12),
                Text(
                  'Configuración de Impresión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text(
                'Imprimir en formato A4',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: printProvider.imprimirFormatoA4,
                onChanged: (value) {
                  printProvider.guardarConfiguracion(
                    imprimirFormatoA4: value,
                    imprimirFormatoTicket: !value,
                  );
                },
              ),
            ),
            ListTile(
              title: const Text(
                'Imprimir en formato Ticket',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: printProvider.imprimirFormatoTicket,
                onChanged: (value) {
                  printProvider.guardarConfiguracion(
                    imprimirFormatoTicket: value,
                    imprimirFormatoA4: !value,
                  );
                },
              ),
            ),
            ListTile(
              title: const Text(
                'Abrir PDF después de imprimir',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: printProvider.abrirPdfDespuesDeImprimir,
                onChanged: (value) {
                  printProvider.guardarConfiguracion(
                    abrirPdfDespuesDeImprimir: value,
                  );
                },
              ),
            ),
            ListTile(
              title: const Text(
                'Impresión directa (sin diálogo)',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Envía directamente a la impresora predeterminada',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: Switch(
                value: printProvider.impresionDirecta,
                onChanged: (value) {
                  printProvider.guardarConfiguracion(
                    impresionDirecta: value,
                  );
                },
              ),
            ),
            if (printProvider.impresionDirecta) ...[
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Divider(color: Colors.white24),
              ),
              ListTile(
                title: const Text(
                  'Seleccionar Impresora',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  printProvider.impresoraSeleccionada ??
                      'No hay impresora seleccionada',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () => printProvider.cargarImpresoras(),
                  tooltip: 'Actualizar lista de impresoras',
                ),
                onTap: () async {
                  // Mostrar diálogo de selección de impresora
                  final impresoras = printProvider.impresorasDisponibles;
                  if (impresoras.isEmpty) {
                    if (mounted) {
                      printProvider.mostrarMensaje(
                        mensaje: 'No se encontraron impresoras disponibles',
                        backgroundColor: Colors.red,
                      );
                    }
                    return;
                  }

                  if (!mounted) {
                    return;
                  }

                  final impresora = await showDialog<String>(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: const Color(0xFF1A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seleccionar Impresora',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...impresoras.map((printer) => ListTile(
                                  title: Text(
                                    printer.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    printer.isDefault ? 'Predeterminada' : '',
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                      fontSize: 12,
                                    ),
                                  ),
                                  leading: Icon(
                                    Icons.print,
                                    color: printer.isDefault
                                        ? const Color(0xFFE31E24)
                                        : Colors.white70,
                                  ),
                                  selected: printer.name ==
                                      printProvider.impresoraSeleccionada,
                                  selectedTileColor: const Color(0xFF2D2D2D),
                                  onTap: () {
                                    Navigator.of(context).pop(printer.name);
                                  },
                                )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (impresora != null) {
                    printProvider.guardarConfiguracion(
                      impresoraSeleccionada: impresora,
                    );
                  }
                },
              ),
            ],
            // --- Configuración avanzada de impresión ---
            ExpansionTile(
              title: const Text(
                'Configuración avanzada',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Márgenes, ancho y opciones avanzadas',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              collapsedIconColor: Colors.white70,
              iconColor: Color(0xFFE31E24),
              children: [
                _buildAdvancedPrintConfig(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedPrintConfig() {
    // Usar PrintProvider directamente
    final printProvider = PrintProvider.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSlider(
          label: 'Margen Izquierdo (mm)',
          value: printProvider.margenIzquierdo,
          min: 0,
          max: 20,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(margenIzquierdo: v);
          }),
        ),
        _buildSlider(
          label: 'Margen Derecho (mm)',
          value: printProvider.margenDerecho,
          min: 0,
          max: 20,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(margenDerecho: v);
          }),
        ),
        _buildSlider(
          label: 'Margen Superior (mm)',
          value: printProvider.margenSuperior,
          min: 0,
          max: 20,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(margenSuperior: v);
          }),
        ),
        _buildSlider(
          label: 'Margen Inferior (mm)',
          value: printProvider.margenInferior,
          min: 0,
          max: 20,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(margenInferior: v);
          }),
        ),
        _buildSlider(
          label: 'Ancho Ticket (mm)',
          value: printProvider.anchoTicket,
          min: 50,
          max: 120,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(anchoTicket: v);
          }),
        ),
        _buildSlider(
          label: 'Escala Ticket',
          value: printProvider.escalaTicket,
          min: 0.5,
          max: 2.0,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(escalaTicket: v);
          }),
        ),
        SwitchListTile(
          title: const Text('Rotación automática',
              style: TextStyle(color: Colors.white)),
          value: printProvider.rotacionAutomatica,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(rotacionAutomatica: v);
          }),
          activeColor: Color(0xFFE31E24),
        ),
        SwitchListTile(
          title: const Text('Ajuste automático',
              style: TextStyle(color: Colors.white)),
          value: printProvider.ajusteAutomatico,
          onChanged: (v) => setState(() {
            printProvider.guardarConfiguracion(ajusteAutomatico: v);
          }),
          activeColor: Color(0xFFE31E24),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Center(
            child: OutlinedButton.icon(
              icon:
                  const Icon(Icons.restore, size: 18, color: Color(0xFFE31E24)),
              label: const Text('Restaurar valores predeterminados',
                  style: TextStyle(color: Color(0xFFE31E24))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE31E24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                await printProvider.restaurarConfiguracionPorDefecto();
                setState(() {}); // Forzar reconstrucción

                // Mostrar mensaje de confirmación
                if (mounted) {
                  printProvider.mostrarMensaje(
                    mensaje:
                        'Configuración restaurada a valores predeterminados',
                    backgroundColor: Colors.green,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
          activeColor: const Color(0xFFE31E24),
          inactiveColor: Colors.white24,
        ),
      ],
    );
  }
}
