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

  final List<List<String>> _tituloTable = [
    ['nombre de producto'],
    ['stock', 'actual'],
    ['stock', 'mínimo'],
    ['stock', 'máximo'],
    ['acciones'],
  ];

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
          return DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF2D2D2D),
            ),
            columns:
                _tituloTable.map((titulo) => titleColumnTable(titulo)).toList(),
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
