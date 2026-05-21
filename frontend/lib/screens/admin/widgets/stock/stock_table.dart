import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/screens/admin/widgets/stock/stock_table_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TableProducts extends StatelessWidget {
  final String selectedSucursalId;
  final List<Producto>? productos;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Function(Producto)? onEditProducto;
  final Function(Producto)? onVerDetalles;
  final Function(Producto)? onVerStockDetalles;
  final Function(String)? onSort;
  final String? sortBy;
  final String? sortOrder;
  final bool filtrosActivos;

  const TableProducts({
    super.key,
    required this.selectedSucursalId,
    this.productos,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onEditProducto,
    this.onVerDetalles,
    this.onVerStockDetalles,
    this.onSort,
    this.sortBy,
    this.sortOrder,
    this.filtrosActivos = false,
  });

  final List<String> _columnHeaders = const <String>[
    'Producto',
    'Categoría',
    'Marca',
    'Stock',
    'Mínimo',
    'Estado',
    'Acciones',
  ];

  @override
  Widget build(BuildContext context) {
    final bool hasProducts = productos != null && productos!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Encabezado de la tabla (Siempre Estático y Persistente)
          Container(
            color: const Color(0xFF2D2D2D),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: _buildStandardHeaders(),
            ),
          ),
          
          // Barra de progreso lineal roja de 2px cuando está cargando pero ya hay datos en pantalla
          SizedBox(
            height: 2,
            child: (isLoading && hasProducts)
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    color: Color(0xFFE31E24),
                    minHeight: 2,
                  )
                : const SizedBox.shrink(),
          ),

          // Cuerpo dinámico condicional
          Expanded(
            child: _buildTableBody(context, hasProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(BuildContext context, bool hasProducts) {
    // 1. Si está cargando y no hay datos previos
    if (isLoading && !hasProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              color: Color(0xFFE31E24),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando inventario...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // 2. Si ocurrió un error
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE31E24),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos: $error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 3. Si no hay sucursal seleccionada
    if (selectedSucursalId.isEmpty) {
      return const Center(
        child: Text(
          'Seleccione una sucursal para ver su inventario',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // 4. Si la lista está vacía
    if (!hasProducts) {
      return _buildNoProductosMessage(hayFiltrosAplicados: filtrosActivos);
    }

    // 5. Renderizado normal de la lista con micro-animación de opacidad
    return AnimatedOpacity(
      opacity: isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ListView.builder(
        itemCount: productos!.length,
        itemBuilder: (context, index) {
          final producto = productos![index];
          return StockTableRow(
            producto: producto,
            onVerStockDetalles: onVerStockDetalles,
            onVerDetalles: onVerDetalles,
          );
        },
      ),
    );
  }

  Widget _buildNoProductosMessage({required bool hayFiltrosAplicados}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FaIcon(
            hayFiltrosAplicados
                ? FontAwesomeIcons.filter
                : FontAwesomeIcons.boxOpen,
            color: hayFiltrosAplicados ? Colors.amber : Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            hayFiltrosAplicados
                ? 'No se encontraron productos'
                : 'No hay productos en esta sucursal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hayFiltrosAplicados
                ? 'Ningún producto coincide con los filtros o criterios de búsqueda aplicados'
                : 'Considera agregar productos a esta sucursal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (hayFiltrosAplicados) ...<Widget>[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry ??
                  () {
                    debugPrint(
                        'No se configuró un manejador para reiniciar filtros');
                  },
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Reiniciar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStandardHeaders() {
    return <Widget>[
      Expanded(
        flex: 30,
        child: Text(
          _columnHeaders[0],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[1],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[2],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 10,
        child: Text(
          _columnHeaders[3],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 10,
        child: Text(
          _columnHeaders[4],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[5],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 15,
        child: Text(
          _columnHeaders[6],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('selectedSucursalId', selectedSucursalId))
      ..add(IterableProperty<Producto>('productos', productos))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('error', error))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRetry', onRetry))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onEditProducto', onEditProducto))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onVerDetalles', onVerDetalles))
      ..add(ObjectFlagProperty<Function(Producto)?>.has(
          'onVerStockDetalles', onVerStockDetalles))
      ..add(ObjectFlagProperty<Function(String)?>.has('onSort', onSort))
      ..add(StringProperty('sortBy', sortBy))
      ..add(StringProperty('sortOrder', sortOrder))
      ..add(DiagnosticsProperty<bool>('filtrosActivos', filtrosActivos));
  }
}
