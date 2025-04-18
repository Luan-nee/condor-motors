import 'package:condorsmotors/providers/computer/ventas.computer.provider.dart';
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
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.print,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
                const SizedBox(width: 12),
                const Text(
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
                value: _ventasProvider.imprimirFormatoA4,
                onChanged: (value) {
                  _ventasProvider.guardarConfiguracionImpresion(
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
                value: _ventasProvider.imprimirFormatoTicket,
                onChanged: (value) {
                  _ventasProvider.guardarConfiguracionImpresion(
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
                value: _ventasProvider.abrirPdfDespuesDeImprimir,
                onChanged: (value) {
                  _ventasProvider.guardarConfiguracionImpresion(
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
                value: _ventasProvider.impresionDirecta,
                onChanged: (value) {
                  _ventasProvider.guardarConfiguracionImpresion(
                    impresionDirecta: value,
                  );
                },
              ),
            ),
            if (_ventasProvider.impresionDirecta) ...[
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
                  _ventasProvider.impresoraSeleccionada ??
                      'No hay impresora seleccionada',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () => _ventasProvider.cargarImpresoras(),
                  tooltip: 'Actualizar lista de impresoras',
                ),
                onTap: () async {
                  // Mostrar diálogo de selección de impresora
                  final impresoras = _ventasProvider.impresorasDisponibles;
                  if (impresoras.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('No se encontraron impresoras disponibles'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  if (!mounted) return;

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
                                      _ventasProvider.impresoraSeleccionada,
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
                    _ventasProvider.guardarConfiguracionImpresion(
                      impresoraSeleccionada: impresora,
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
