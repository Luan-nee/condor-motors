/*
Este widget solo servirá para mostrar una tabla con los productos que se encuentran
dentro del la variable "_productos", por lo tanto no se necesita de ninguna lógica
adicional para su funcionamiento.
*/

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<Map<String, dynamic>>> loadJsonData() async {
  String jsonString = await rootBundle
      .loadString('assets/json/inventario_admin/stockProducts.json');
  List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.map((e) => e as Map<String, dynamic>).toList();
}

class TableProducts extends StatelessWidget {
  TableProducts({super.key});

  // final String _selectedLocal = 'Central Principal';
  // final bool _showCentrales = true;

  final List<List<String>> _tituloTable = [
    ['nombre de producto'],
    ['stock', 'actual'],
    ['stock', 'mínimo'],
    ['stock', 'máximo'],
    ['acciones'],
  ];
/*
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'nombre': 'Casco MT Thunder',
      'icon': FontAwesomeIcons.helmetSafety,
      'stock': {
        'Central Principal': 15,
        'Sucursal San Miguel': 8,
        'Sucursal Los Olivos': 5,
      },
      'precio': 299.99,
      'marca': 'MT Helmets',
      'minimo': 10,
      'maximo': 50,
    },
    {
      'id': 2,
      'nombre': 'Aceite Motul 5100',
      'categoria': 'Lubricantes',
      'icon': FontAwesomeIcons.oilCan,
      'stock': {
        'Central Principal': 45,
        'Sucursal San Miguel': 20,
        'Sucursal Los Olivos': 15,
      },
      'precio': 89.99,
      'marca': 'Motul',
      'minimo': 30,
      'maximo': 100,
    },
    {
      'id': 3,
      'nombre': 'Llanta Michelin Pilot',
      'categoria': 'Llantas',
      'icon': FontAwesomeIcons.ring,
      'stock': {
        'Central Principal': 12,
        'Sucursal San Miguel': 6,
        'Sucursal Los Olivos': 4,
      },
      'precio': 459.99,
      'marca': 'Michelin',
      'minimo': 8,
      'maximo': 24,
    },
  ];
  final List<List<String>> _testData = [
    [
      'Casco MT Thunder',
      'Aceite Motul 5100',
      'Llanta Michelin Pilot',
      'Casco MT Thunder',
      'Casco MT Thunder',
    ],
    [
      'Casco MT Thunder',
      'Aceite Motul 5100',
      'Llanta Michelin Pilot',
      'Casco MT Thunder',
      'Casco MT Thunder',
    ],
    [
      'Casco MT Thunder',
      'Aceite Motul 5100',
      'Llanta Michelin Pilot',
      'Casco MT Thunder',
      'Casco MT Thunder',
    ],
    [
      'Casco MT Thunder',
      'Aceite Motul 5100',
      'Llanta Michelin Pilot',
      'Casco MT Thunder',
      'Casco MT Thunder',
    ],
  ];
*/
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadJsonData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF2D2D2D),
              ),
              columns: _tituloTable
                  .map((titulo) => titleColumnTable(titulo))
                  .toList(),
              rows: snapshot.data!.expand((listProduct) {
                return (listProduct["productos"] as List<dynamic>)
                    .map((infoProduct) {
                  var product = infoProduct as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(Text(product["nombre"].toString(),
                          style: const TextStyle(color: Colors.white))),
                      DataCell(Text(product["stock_actual"].toString(),
                          style: const TextStyle(color: Colors.white))),
                      DataCell(Text(product["stock_minimo"].toString(),
                          style: const TextStyle(color: Colors.white))),
                      DataCell(Text(product["stock_maximo"].toString(),
                          style: const TextStyle(color: Colors.white))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.penToSquare,
                                  color: Colors.white54, size: 16),
                              onPressed: () {
                                // TODO: Implementar edición
                              },
                            ),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.rightLeft,
                                  color: Color(0xFFE31E24), size: 16),
                              onPressed: () {
                                // TODO: Implementar transferencia
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList();
              }).toList(),
            ),
          );
        }
      },
    );
  }

  DataColumn titleColumnTable(List<String> nameHeader) {
    return DataColumn(
      label: SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
          children: nameHeader
              .map(
                (name) => Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
