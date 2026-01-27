import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String baseUrl = 'https://checkin.marandusolutions.com.br';

  String? _csrfToken;
  User? _currentUser;
  String _deviceId = 'guest';

  User? get currentUser => _currentUser;
  String get deviceId => _deviceId;
  String? get csrfToken => _csrfToken;

  Future<String?> getSecretKey() async {
    final savedKey = await _storage.read(key: 'secret_key');
    return savedKey ?? _currentUser?.secretKey;
  }

  AuthService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    _dio.options.headers = {
      'User-Agent': 'okhttp/3.12.1',
      'Accept': 'application/json',
    };

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('--- INÍCIO DA REQUISIÇÃO ---');
          debugPrint('Rota: ${options.method} ${options.path}');

          options.headers ??= <String, dynamic>{};
          options.headers['X-Device-Id'] = _deviceId;
          debugPrint('Header X-Device-Id: $_deviceId');

          Map<String, dynamic> data = {};

          if (options.data is Map<String, dynamic>) {
            data = Map<String, dynamic>.from(options.data);
          } else if (options.data is Map) {
            data = Map<String, dynamic>.from(options.data);
          }

          if (_csrfToken != null) {
            data['_token'] = _csrfToken;
            debugPrint('Injetando _token: $_csrfToken');
          }

          final path = options.path;
          if (!path.contains('login') && !path.contains('getcsrftoken')) {
            final savedKey = await _storage.read(key: 'secret_key');
            if (savedKey != null) {
              data['secret_key'] = savedKey;
              debugPrint('Injetando secret_key: $savedKey');
            } else if (_currentUser?.secretKey != null) {
              data['secret_key'] = _currentUser!.secretKey;
            }
          }

          options.data = data;
          debugPrint('Payload Final: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint('Erro na API: ${e.response?.statusCode} - ${e.message}');
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            await logout();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> getCsrfToken() async {
    try {
      final response = await _dio.get('/proxy.php?route=getcsrftoken');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String? token;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('_token')) {
            token = data['_token']?.toString();
          } else if (data.containsKey('token')) {
            token = data['token']?.toString();
          }
        } else if (data is String) {
          token = data.trim();
        }

        if (token != null && token.isNotEmpty) {
          _csrfToken = token;
          debugPrint('CSRF Token Validado: $_csrfToken');
        } else {
          debugPrint('Resposta de CSRF sem token válido: $data');
        }
      } else {
        debugPrint('Falha ao obter CSRF, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar CSRF: $e');
      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    try {
      _deviceId = email;
      debugPrint('Atualizando X-Device-Id para email do usuário: $_deviceId');

      await getCsrfToken();

      final response = await _dio.post(
        '/proxy.php?route=login',
        data: {'email': email, 'password': password},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        debugPrint('Resposta bruta do login: $data');

        if (data is String) {
          try {
            data = jsonDecode(data);
            debugPrint('Resposta decodificada do login: $data');
          } catch (e) {
            debugPrint('Falha ao fazer jsonDecode da resposta de login: $e');
          }
        }

        if (data is List && data.isNotEmpty) {
          debugPrint(
            'Resposta de login é uma lista, usando o primeiro elemento.',
          );
          data = data.first;
        }

        if (data is Map) {
          final mapData = Map<String, dynamic>.from(data);

          if (mapData.containsKey('user')) {
            debugPrint(
              'Encontrada chave "user" na resposta, usando seu conteúdo.',
            );
            data = mapData['user'];
          } else if (mapData.containsKey('data')) {
            debugPrint(
              'Encontrada chave "data" na resposta, usando seu conteúdo.',
            );
            data = mapData['data'];
          } else {
            data = mapData;
          }
        }

        if (data is Map<String, dynamic>) {
          try {
            final user = User.fromJson(data);
            _currentUser = user;

            if (user.secretKey != null) {
              await _storage.write(key: 'secret_key', value: user.secretKey);
            }
            return user;
          } catch (e) {
            debugPrint('Erro ao converter User.fromJson: $e');

            final dynamic raw = data;
            if (raw is Map) {
              final map = Map<String, dynamic>.from(raw);
              final campos = map.keys.toList();
              debugPrint('Campos presentes na resposta de usuário: $campos');

              final tipos = <String, String>{};
              map.forEach((key, value) {
                tipos[key] = value?.runtimeType.toString() ?? 'null';
              });
              debugPrint('Tipos dos campos na resposta de usuário: $tipos');

              final problemas = <String>[];

              void verificaCampo(
                String nome,
                bool Function(dynamic) validacao,
                String tipoEsperado,
              ) {
                if (!map.containsKey(nome)) {
                  problemas.add(
                    'Campo "$nome" ausente (esperado tipo $tipoEsperado).',
                  );
                  return;
                }
                final valor = map[nome];
                if (!validacao(valor)) {
                  problemas.add(
                    'Campo "$nome" com tipo inválido: ${valor.runtimeType} (esperado $tipoEsperado).',
                  );
                }
              }

              verificaCampo('name', (v) => v == null || v is String, 'String?');
              verificaCampo(
                'email',
                (v) => v == null || v is String,
                'String?',
              );
              verificaCampo(
                'secret_key',
                (v) => v == null || v is String,
                'String?',
              );

              if (problemas.isNotEmpty) {
                for (final p in problemas) {
                  debugPrint(p);
                }
              } else {
                debugPrint(
                  'Estrutura de dados parece compatível, erro inesperado em User.fromJson.',
                );
              }
            } else {
              debugPrint(
                'Resposta de usuário não é um Map após o parse flexível. Tipo: ${raw.runtimeType}',
              );
            }

            throw Exception('Falha ao parsear usuário: $e');
          }
        }
        throw Exception('Dados de usuário inválidos na resposta.');
      }
      throw Exception('Falha na autenticação.');
    } catch (e) {
      debugPrint('Erro no processo de Login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _currentUser = null;
    _csrfToken = null;
    _deviceId = 'guest';
    debugPrint('Sessão encerrada e storage limpo.');
  }
}
