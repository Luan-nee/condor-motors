import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/stock_list.dart';
import 'widgets/stock_utils.dart';
import '../../api/protected/stocks.api.dart';
import '../../main.dart' show api;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class InventarioAdminScreen extends StatefulWidget {
  const InventarioAdminScreen({super.key});

  @override
  State<InventarioAdminScreen> createState() => _InventarioAdminScreenState();
}

class _InventarioAdminScreenState extends State<InventarioAdminScreen> {
  String _selectedLocalId = '';
  String _selectedLocalNombre = '';
  bool _showCentrales = true;
  late final StocksApi _stocksApi;
  List<Map<String, dynamic>> _locales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Usar la instancia global de API en lugar de crear una nueva
    _stocksApi = api.stocks;
    
    // Cargar datos de sucursales
    _cargarDatos();
  }
  
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar datos de ejemplo desde el archivo JSON
      // En el futuro, esto se reemplazará por una llamada a la API real
      final jsonData = await _cargarDatosJSON();
      
      setState(() {
        _locales = jsonData.map((sucursal) {
          final productos = (sucursal['productos'] as List<dynamic>);
          
          // Calcular estadísticas para cada sucursal
          double valorInventario = 0;
          for (var producto in productos) {
            final stockActual = producto['stock_actual'] as int? ?? 0;
            final precioVenta = producto['precio_venta'] as double? ?? 0;
            valorInventario += stockActual * precioVenta;
          }
          
          return {
            'id': sucursal['id'] as String,
            'nombre': sucursal['nombre'] as String,
            'direccion': 'Av. Principal 123', // Ejemplo, se puede mejorar con datos reales
            'tipo': sucursal['es_central'] == true ? 'central' : 'sucursal',
            'icon': sucursal['es_central'] == true 
                ? FontAwesomeIcons.warehouse 
                : FontAwesomeIcons.store,
            'estado': true,
            'productos': productos.length,
            'valorInventario': valorInventario,
          };
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<List<Map<String, dynamic>>> _cargarDatosJSON() async {
    try {
      String jsonString = await rootBundle
          .loadString('assets/json/inventario_admin/stockProducts.json');
      List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error cargando datos JSON: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
              ),
            )
          : Row(
              children: [
                // Panel principal (75% del ancho)
                Expanded(
                  flex: 75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con nombre del local
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.boxesStacked,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'INVENTARIO',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_selectedLocalNombre.isNotEmpty) ...[
                                  const Text(
                                    ' / ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Text(
                                    _selectedLocalNombre,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                if (_selectedLocalId.isNotEmpty) ...[
                                  ElevatedButton.icon(
                                    icon: const FaIcon(FontAwesomeIcons.fileExport,
                                        size: 16, color: Colors.white),
                                    label: const Text('Exportar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D2D2D),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      // TODO: Implementar exportar inventario
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                ElevatedButton.icon(
                                  icon: const FaIcon(FontAwesomeIcons.plus,
                                      size: 16, color: Colors.white),
                                  label: const Text('Nuevo Producto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE31E24),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _selectedLocalId.isEmpty
                                      ? null // Deshabilitar si no hay sucursal seleccionada
                                      : () {
                                          // TODO: Implementar agregar producto
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tabla de inventario
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Mostrar resumen si hay una sucursal seleccionada
                              if (_selectedLocalId.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: InventarioResumen(
                                    sucursalId: _selectedLocalId,
                                    sucursalNombre: _selectedLocalNombre,
                                  ),
                                ),
                              ],
                              
                              // Tabla de productos
                              Expanded(
                                child: SingleChildScrollView(
                                  child: TableProducts(
                                    selectedSucursalId: _selectedLocalId,
                                    stocksApi: _stocksApi,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Panel lateral derecho (25% del ancho)
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título del panel
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Control de Locales',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.circlePlus,
                                color: Color(0xFFE31E24),
                                size: 18,
                              ),
                              onPressed: () {
                                // TODO: Implementar agregar local
                              },
                              tooltip: 'Agregar nuevo local',
                            ),
                          ],
                        ),
                      ),

                      // Tabs de Centrales y Sucursales
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildTab(true, 'Centrales', () {
                              setState(() => _showCentrales = true);
                            }),
                            const SizedBox(width: 8),
                            _buildTab(false, 'Sucursales', () {
                              setState(() => _showCentrales = false);
                            }),
                          ],
                        ),
                      ),

                      // Lista de locales
                      Expanded(
                        child: _locales.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay locales disponibles',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _locales.length,
                                itemBuilder: (context, index) {
                                  final local = _locales[index];
                                  if (_showCentrales && local['tipo'] != 'central') {
                                    return const SizedBox.shrink();
                                  }
                                  if (!_showCentrales && local['tipo'] != 'sucursal') {
                                    return const SizedBox.shrink();
                                  }

                                  final isSelected = _selectedLocalId == local['id'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE31E24).withOpacity(0.1)
                                          : const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFE31E24)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedLocalId = local['id'] as String;
                                          _selectedLocalNombre = local['nombre'] as String;
                                        });
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              FaIcon(
                                                local['icon'] as IconData,
                                                color: isSelected
                                                    ? const Color(0xFFE31E24)
                                                    : Colors.white54,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  local['nombre'] as String,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? const Color(0xFFE31E24)
                                                        : Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            local['direccion'] as String,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStat(
                                                'Productos',
                                                local['productos'].toString(),
                                              ),
                                              _buildStat(
                                                'Valor',
                                                StockUtils.formatCurrency(local['valorInventario'] as double),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(bool isSelected, String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFFE31E24)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
