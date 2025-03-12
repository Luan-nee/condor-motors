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

  final List<String> _columnHeaders = [
    'nombre de producto',
    'stock actual',
    'stock mínimo',
    'stock máximo',
    'acciones',
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
          // Obtener todos los productos
          final allProducts = snapshot.data!.expand((listProduct) {
            return (listProduct["productos"] as List<dynamic>).map((infoProduct) {
              return infoProduct as Map<String, dynamic>;
            });
          }).toList();

          return Container(
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado de la tabla
                Container(
                  color: const Color(0xFF2D2D2D),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // Nombre de producto (40% del ancho)
                      Expanded(
                        flex: 40,
                        child: Text(
                          _columnHeaders[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock actual (15% del ancho)
                      Expanded(
                        flex: 15,
                        child: Text(
                          _columnHeaders[1],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock mínimo (15% del ancho)
                      Expanded(
                        flex: 15,
                        child: Text(
                          _columnHeaders[2],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Stock máximo (15% del ancho)
                      Expanded(
                        flex: 15,
                        child: Text(
                          _columnHeaders[3],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Acciones (15% del ancho)
                      Expanded(
                        flex: 15,
                        child: Text(
                          _columnHeaders[4],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filas de productos
                ...allProducts.map((product) => Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // Nombre del producto
                      Expanded(
                        flex: 40,
                        child: Text(
                          product["nombre"].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Stock actual
                      Expanded(
                        flex: 15,
                        child: Text(
                          product["stock_actual"].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Stock mínimo
                      Expanded(
                        flex: 15,
                        child: Text(
                          product["stock_minimo"].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Stock máximo
                      Expanded(
                        flex: 15,
                        child: Text(
                          product["stock_maximo"].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Acciones
                      Expanded(
                        flex: 15,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.penToSquare,
                                color: Colors.white54,
                                size: 16,
                              ),
                              onPressed: () {
                                // Implementar edición
                              },
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.rightLeft,
                                color: Color(0xFFE31E24),
                                size: 16,
                              ),
                              onPressed: () {
                                // Implementar transferencia
                              },
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          );
        }
      },
    );
  }
}
