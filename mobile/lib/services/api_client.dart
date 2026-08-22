import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/entities.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3333',
  );

  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> loadToken() async {
    _token = await _storage.read(key: 'jwt');
    return _token;
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'jwt');
  }

  Future<AppUser> register(String name, String email, String password) async {
    final body = await _request(
      'POST',
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    return AppUser.fromJson(body);
  }

  Future<AppUser> login(String email, String password) async {
    final body = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    _token = body['token'];
    await _storage.write(key: 'jwt', value: _token);
    return AppUser.fromJson(body['user']);
  }

  Future<AppUser> me() async =>
      AppUser.fromJson(await _request('GET', '/auth/me'));

  Future<ShoppingSession?> currentSession() async {
    final body = await _request('GET', '/sessions/current');
    return body == null ? null : ShoppingSession.fromJson(body);
  }

  Future<ShoppingSession> linkCart(String cartCode) async {
    return ShoppingSession.fromJson(
      await _request('POST', '/carts/link', body: {'cart_code': cartCode}),
    );
  }

  Future<Product> productByBarcode(String barcode) async {
    return Product.fromJson(
      await _request('GET', '/products/barcode/$barcode'),
    );
  }

  Future<ShoppingSession> addItem(
    String sessionId,
    String productId,
    int quantity,
  ) async {
    return ShoppingSession.fromJson(
      await _request(
        'POST',
        '/sessions/$sessionId/items',
        body: {'product_id': productId, 'quantity': quantity},
      ),
    );
  }

  Future<ShoppingSession> updateItem(
    String sessionId,
    String itemId,
    int quantity,
  ) async {
    return ShoppingSession.fromJson(
      await _request(
        'PATCH',
        '/sessions/$sessionId/items/$itemId',
        body: {'quantity': quantity},
      ),
    );
  }

  Future<ShoppingSession> removeItem(String sessionId, String itemId) async {
    return ShoppingSession.fromJson(
      await _request('DELETE', '/sessions/$sessionId/items/$itemId'),
    );
  }

  Future<ShoppingSession> finishSession(String sessionId) async {
    return ShoppingSession.fromJson(
      await _request('POST', '/sessions/$sessionId/finish'),
    );
  }

  Future<List<ShoppingSession>> history() async {
    final body = await _request('GET', '/sessions/history') as List;
    return body.map((item) => ShoppingSession.fromJson(item)).toList();
  }

  Future<List<ShoppingSession>> pendingValidations() async {
    final body = await _request('GET', '/validations/pending') as List;
    return body.map((item) => ShoppingSession.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> validateSession(
    String sessionId,
    int measuredWeightGrams,
  ) async {
    return await _request(
      'POST',
      '/validations/$sessionId',
      body: {'measured_weight_grams': measuredWeightGrams},
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'PATCH' => await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      'DELETE' => await _client.delete(uri, headers: headers),
      _ => throw ApiException('Metodo HTTP invalido.'),
    };

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded?['message'] ?? 'Falha de comunicacao.');
    }
    return decoded;
  }
}
