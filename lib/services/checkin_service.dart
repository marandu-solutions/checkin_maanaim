import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class CheckinService {
  final Dio _dio;
  final AuthService _authService;

  CheckinService(this._authService)
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

  Future<bool> confirmarPresenca(String idEvento, List<String> ids) async {
    try {
      final deviceId = _authService.deviceId;

      if (deviceId.isEmpty || deviceId == 'guest') {
        throw Exception(
          'Usuário não autenticado. X-Device-Id inválido para confirmar presença.',
        );
      }

      // 1. Recuperar a secret_key (essencial para evitar erro 500)
      final secretKey = await _authService.getSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        throw Exception(
          'Secret Key não encontrada. Realize o login novamente.',
        );
      }

      // 2. Obter token CSRF fresco da sessão atual (evita erro 419)
      debugPrint('Solicitando token CSRF fresco...');
      String freshToken = '';
      try {
        final tokenResponse = await _dio.get(
          '/proxy.php',
          queryParameters: {'route': 'getcsrftoken'},
          options: Options(headers: {'X-Device-Id': deviceId}),
        );
        final tokenData = tokenResponse.data;
        if (tokenData is Map &&
            (tokenData.containsKey('_token') ||
                tokenData.containsKey('token'))) {
          freshToken = (tokenData['_token'] ?? tokenData['token']).toString();
        } else {
          freshToken = tokenData.toString().trim();
        }
      } catch (e) {
        debugPrint('Erro ao obter token fresco: $e. Tentando usar cache...');
        freshToken = _authService.csrfToken ?? '';
      }

      if (freshToken.isEmpty || freshToken == 'null') {
        // Fallback final
        freshToken = _authService.csrfToken ?? '';
        if (freshToken.isEmpty) {
          throw Exception('Falha ao obter token CSRF.');
        }
      }
      debugPrint('Token para checkin: $freshToken');

      // 3. Converter IDs para inteiros (conforme app original)
      final listaIds = ids.map((e) => int.tryParse(e) ?? e).toList();

      // 4. Montar o Payload Completo (com secret_key)
      final Map<String, dynamic> payload = {
        "inscricoes": listaIds,
        "max_lido_at": null,
        "_token": freshToken,
        "secret_key": secretKey,
      };

      final route = 'confirmainscricoes/$idEvento';
      debugPrint(
        'Enviando checkin para rota: $route com payload: ${jsonEncode(payload)}',
      );

      final response = await _dio.post(
        '/proxy.php',
        queryParameters: {'route': route},
        data: payload,
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
            'X-Requested-With': 'XMLHttpRequest',
            'Content-Type': 'application/json',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      if (status == 200 || status == 201) {
        return true;
      }

      debugPrint('Resposta inesperada checkin ($status): ${response.data}');
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final responseData = e.response?.data;
      debugPrint('Erro Dio confirmarPresenca ($status): $responseData');

      if (status == 401) {
        throw Exception('Não autorizado (401). Verifique login.');
      }
      if (status != null && status >= 500) {
        throw Exception('Erro Servidor ($status): $responseData');
      }
      throw Exception('Falha na requisição: ${e.message}');
    } catch (e) {
      debugPrint('Erro geral confirmarPresenca: $e');
      rethrow;
    }
  }
}
