import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/inscrito_model.dart';
import 'auth_service.dart';

class EventoService {
  final Dio _dio;
  final AuthService _authService;

  // Cache em memória: ID do evento -> Dados
  final Map<String, EventoInscritos> _cache = {};

  EventoService(this._authService)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AuthService.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'User-Agent': 'okhttp/3.12.1',
            'Accept': 'application/json',
          },
        ),
      );

  Future<EventoInscritos> getInscritos(
    String idEvento, {
    bool forceRefresh = false,
  }) async {
    // Se já tiver em cache e não for forçado, retorna do cache
    if (!forceRefresh && _cache.containsKey(idEvento)) {
      debugPrint('Retornando inscritos do cache para o evento $idEvento');
      return _cache[idEvento]!;
    }

    try {
      final deviceId = _authService.deviceId;

      if (deviceId.isEmpty || deviceId == 'guest') {
        throw Exception(
          'Usuário não autenticado. X-Device-Id inválido para buscar inscritos.',
        );
      }

      final response = await _dio.get(
        '/proxy.php?route=eventoinscritos/$idEvento',
        options: Options(headers: {'X-Device-Id': deviceId}),
      );

      debugPrint(
        'Resposta bruta de inscritos do evento $idEvento: ${response.data}',
      );

      final status = response.statusCode ?? 0;
      if (status == 401) {
        throw Exception('Não autorizado ao listar inscritos do evento.');
      }
      if (status >= 500) {
        throw Exception('Erro no servidor ao listar inscritos do evento.');
      }

      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          debugPrint('Falha ao fazer jsonDecode da resposta de inscritos: $e');
          throw Exception('Resposta inválida ao listar inscritos do evento.');
        }
      }

      if (data is Map<String, dynamic>) {
        final result = EventoInscritos.fromJson(data);
        _cache[idEvento] = result; // Salva no cache
        return result;
      }

      throw Exception('Formato inesperado de resposta ao listar inscritos.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 401) {
        throw Exception('Não autorizado ao listar inscritos do evento.');
      }
      if (status != null && status >= 500) {
        throw Exception('Erro no servidor ao listar inscritos do evento.');
      }

      throw Exception('Falha de conexão ao buscar inscritos: ${e.message}');
    } catch (e) {
      debugPrint('Erro inesperado em getInscritos: $e');
      rethrow;
    }
  }

  void updateInscritoPresenteLocal(String idEvento, String idInscrito) {
    if (_cache.containsKey(idEvento)) {
      final dados = _cache[idEvento]!;
      final index = dados.inscritos.indexWhere((i) => i.id == idInscrito);

      if (index != -1) {
        final inscrito = dados.inscritos[index];
        // Atualiza apenas se ainda não estiver presente
        if (!inscrito.presente) {
          dados.inscritos[index] = inscrito.copyWith(
            participou: '1',
            lidoAt: DateTime.now().toString(), // Atualiza timestamp localmente
          );
          debugPrint('Inscrito $idInscrito marcado como presente localmente.');
        }
      }
    }
  }
}
