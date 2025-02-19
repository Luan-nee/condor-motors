import 'package:flutter/material.dart';
import './api.service.dart';

class MovimientosApi {
  final ApiService _api;

  MovimientosApi(this._api);

  // Exponer el ApiService para verificación de estado
  ApiService get api => _api;

  // Estados válidos según documentación
  static const estados = {
    'SOLICITANDO': 'SOLICITANDO', // Movimiento inicial solicitado
    'PREPARADO': 'PREPARADO',     // Productos listos para envío
    'RECIBIDO': 'RECIBIDO',      // Productos recibidos en destino
    'APROBADO': 'APROBADO',      // Movimiento aprobado por administración
  };

  Future<List<Map<String, dynamic>>> getMovements() async {
    try {
      final response = await _api.request(
        endpoint: '/movimientos',
        method: 'GET',
        queryParams: {
          'saltar': '0',
          'limite': '100',
        },
      );

      // Si la respuesta es null, retornar lista vacía
      if (response == null) {
        return [];
      }

      // Si la respuesta es un mapa con una propiedad 'data' o 'movimientos'
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response['movimientos'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }

      // Si la respuesta es directamente una lista
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }

      // Si no es ninguno de los formatos esperados, retornar lista vacía
      debugPrint('Formato de respuesta inesperado: $response');
      return [];

    } catch (e) {
      debugPrint('Error al obtener movimientos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMovement(Map<String, dynamic> data) async {
    try {
      final response = await _api.request(
        endpoint: '/movimientos',
        method: 'POST',
        body: {
          'producto_id': data['producto_id'],
          'usuario_id': data['usuario_id'],
          'local_id': data['local_id'],
          'cantidad': data['cantidad'],
          'fecha_movimiento': DateTime.now().toIso8601String(),
          'sucursal_origen': data['sucursal_origen'],
          'sucursal_destino': data['sucursal_destino'],
          'estado': 'SOLICITANDO',
        },
        queryParams: const {},
      );

      return response;
    } catch (e) {
      debugPrint('Error al crear movimiento: $e');
      rethrow;
    }
  }

  Future<void> updateMovementStatus(String movementId, String newStatus) async {
    try {
      await _api.request(
        endpoint: '/movimientos/$movementId/estado',
        method: 'PUT',
        body: {
          'estado': newStatus,
        },
        queryParams: const {},
      );
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      rethrow;
    }
  }

  Future<void> approveMovement(String movementId, int adminUserId) async {
    try {
      await _api.request(
        endpoint: '/movimientos/$movementId/aprobar',
        method: 'PUT',
        queryParams: const {},
        body: {
          'usuario_aprobador_id': adminUserId,
        },
      );
    } catch (e) {
      debugPrint('Error al aprobar movimiento: $e');
      rethrow;
    }
  }

  // Verificar si el usuario puede crear movimientos
  bool canCreateMovements(String rol) {
    return rol.toUpperCase() == 'COLABORADOR';
  }

  // Verificar si el usuario puede actualizar el estado
  bool canUpdateStatus(String rol, String currentStatus, String newStatus) {
    final rolUpper = rol.toUpperCase();
    
    if (rolUpper == 'ADMINISTRADOR') {
      // Admin solo puede aprobar movimientos en estado RECIBIDO
      return currentStatus == 'RECIBIDO' && newStatus == 'APROBADO';
    }
    
    if (rolUpper == 'COLABORADOR') {
      // Validar secuencia según documentación
      switch (currentStatus) {
        case 'SOLICITANDO':
          return newStatus == 'PREPARADO';
        case 'PREPARADO':
          return newStatus == 'RECIBIDO';
        default:
          return false;
      }
    }

    return false;
  }

  // Verificar si el movimiento puede ser aprobado
  bool canApproveMovement(String rol, String currentStatus) {
    return rol.toUpperCase() == 'ADMINISTRADOR' && currentStatus == 'RECIBIDO';
  }

  // Validar secuencia de estados
  bool isValidStateTransition(String currentStatus, String newStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'SOLICITANDO':
        return newStatus == 'PREPARADO';
      case 'PREPARADO':
        return newStatus == 'RECIBIDO';
      case 'RECIBIDO':
        return newStatus == 'APROBADO';
      default:
        return false;
    }
  }
} 