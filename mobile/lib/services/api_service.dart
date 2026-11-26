import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/restaurant_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente HTTP oficial para a API NestJS (/api).
/// Compartilha o mesmo banco SQLite e regras de negócio com o Front-end Next.js.
class ApiService {
  String _baseUrl;
  String? _token;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = ApiConfig.normalizeBaseUrl(baseUrl ?? ApiConfig.defaultBaseUrl),
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;
  String? get token => _token;

  void setBaseUrl(String url) {
    _baseUrl = ApiConfig.normalizeBaseUrl(url);
  }

  void setToken(String? token) {
    _token = (token != null && token.trim().isNotEmpty) ? token.trim() : null;
  }

  Map<String, String> _headers({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;

    try {
      final headers = _headers(includeAuth: includeAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 12));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 12));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 12));
          break;
        default:
          throw ApiException('Método HTTP não suportado: $method');
      }
    } on TimeoutException {
      throw ApiException(
        'Tempo esgotado ao conectar com $_baseUrl. Verifique se o back-end NestJS está rodando na porta 3000.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Não foi possível conectar à API ($_baseUrl). Verifique se o back-end está ativo e acessível.',
      );
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Erro HTTP ${response.statusCode}';
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        final rawMsg = decoded['message'];
        if (rawMsg is List) {
          message = rawMsg.join(', ');
        } else {
          message = rawMsg.toString();
        }
      }
      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }

  // ===========================================================================
  // 1. AUTENTICAÇÃO E EQUIPE (/api/auth)
  // ===========================================================================

  Future<AuthResponse> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/auth/login',
      includeAuth: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<StaffUser> registerStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await _request(
      'POST',
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.value,
      },
    );
    return StaffUser.fromJson(data as Map<String, dynamic>);
  }

  Future<List<StaffUser>> fetchStaff() async {
    final data = await _request('GET', '/auth/staff');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(StaffUser.fromJson)
        .toList();
  }

  // ===========================================================================
  // 2. MESAS (/api/tables)
  // ===========================================================================

  Future<List<RestaurantTable>> fetchTables() async {
    final data = await _request('GET', '/tables');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RestaurantTable.fromJson)
        .toList();
  }

  Future<RestaurantTable> createTable({
    required int number,
    required int capacity,
  }) async {
    final data = await _request(
      'POST',
      '/tables',
      body: {
        'number': number,
        'capacity': capacity,
      },
    );
    return RestaurantTable.fromJson(data as Map<String, dynamic>);
  }

  // ===========================================================================
  // 3. PRODUTOS (/api/products)
  // ===========================================================================

  Future<List<Product>> fetchProducts() async {
    final data = await _request('GET', '/products');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    required String category,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'price': price,
      'category': category.trim(),
    };
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    final data = await _request('POST', '/products', body: payload);
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await _request('DELETE', '/products/$id');
  }

  // ===========================================================================
  // 4. RESERVAS (/api/reservations)
  // ===========================================================================

  Future<List<Reservation>> fetchReservations() async {
    final data = await _request('GET', '/reservations');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Reservation.fromJson)
        .toList();
  }

  Future<Reservation> createReservation({
    required String customerName,
    required String customerPhone,
    required String dateTimeIso,
    required int guestCount,
    int? tableId,
  }) async {
    final payload = <String, dynamic>{
      'customerName': customerName.trim(),
      'customerPhone': customerPhone.trim(),
      'dateTime': dateTimeIso,
      'guestCount': guestCount,
    };
    if (tableId != null) {
      payload['tableId'] = tableId;
    }
    final data = await _request('POST', '/reservations', body: payload);
    return Reservation.fromJson(data as Map<String, dynamic>);
  }

  // ===========================================================================
  // 5. PEDIDOS / COMANDAS (/api/orders)
  // ===========================================================================

  Future<List<Order>> fetchOrders() async {
    final data = await _request('GET', '/orders');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();
  }

  Future<Order> openOrder({
    required int tableId,
    required int userId,
  }) async {
    final data = await _request(
      'POST',
      '/orders',
      body: {
        'tableId': tableId,
        'userId': userId,
      },
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<void> addOrderItem({
    required int orderId,
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }
    await _request('POST', '/orders/$orderId/items', body: payload);
  }

  Future<void> updateOrderItemQuantity({
    required int orderId,
    required int itemId,
    required int quantity,
  }) async {
    await _request(
      'PATCH',
      '/orders/$orderId/items/$itemId',
      body: {'quantity': quantity},
    );
  }

  Future<void> removeOrderItem({
    required int orderId,
    required int itemId,
  }) async {
    await _request('DELETE', '/orders/$orderId/items/$itemId');
  }

  Future<void> transferOrder({
    required int orderId,
    required int targetTableId,
  }) async {
    await _request(
      'PATCH',
      '/orders/$orderId/transfer',
      body: {'targetTableId': targetTableId},
    );
  }

  Future<void> closeOrder(int orderId) async {
    await _request('PATCH', '/orders/$orderId/close');
  }

  Future<DashboardData> fetchDashboardData() async {
    final results = await Future.wait<dynamic>([
      fetchTables(),
      fetchProducts(),
      fetchReservations(),
      fetchOrders(),
      fetchStaff().catchError((_) => <StaffUser>[]),
    ]);

    return DashboardData(
      tables: results[0] as List<RestaurantTable>,
      products: results[1] as List<Product>,
      reservations: results[2] as List<Reservation>,
      orders: results[3] as List<Order>,
      staff: results[4] as List<StaffUser>,
    );
  }

  // ===========================================================================
  // 6. CARDÁPIO PÚBLICO DO CLIENTE (/api/public)
  // ===========================================================================

  Future<PublicMenuData> fetchPublicMenu() async {
    final data = await _request(
      'GET',
      '/public/menu',
      includeAuth: false,
    ) as Map<String, dynamic>;

    final products = (data['products'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();

    final tables = (data['tables'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RestaurantTable.fromJson)
        .toList();

    final openOrders = (data['openOrders'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();

    return PublicMenuData(
      products: products,
      tables: tables,
      openOrders: openOrders,
    );
  }

  Future<Order> submitCustomerOrder({
    required int tableId,
    String? customerName,
    required List<CustomerCartItem> items,
  }) async {
    final payload = <String, dynamic>{
      'tableId': tableId,
      if (customerName != null && customerName.trim().isNotEmpty)
        'customerName': customerName.trim(),
      'items': items
          .map(
            (i) => {
              'productId': i.product.id,
              'quantity': i.quantity,
              if (i.notes.trim().isNotEmpty) 'notes': i.notes.trim(),
            },
          )
          .toList(),
    };

    final data = await _request(
      'POST',
      '/public/orders',
      includeAuth: false,
      body: payload,
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }
}
