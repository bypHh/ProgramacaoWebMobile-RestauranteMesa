import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/restaurant_models.dart';
import '../services/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  static const _kTokenKey = 'restaurant_token';
  static const _kUserKey = 'restaurant_user';
  static const _kApiUrlKey = 'restaurant_api_url';
  static const _kCartKey = 'restaurant_customer_cart';
  static const _kCustomerTableKey = 'restaurant_customer_table';
  static const _kCustomerNameKey = 'restaurant_customer_name';

  final ApiService _api;
  final bool enableAutoPolling;
  Timer? _pollingTimer;

  bool _initialized = false;
  bool _loading = false;
  bool _busy = false;
  bool _isBackendOnline = false;
  String? _lastError;

  String? _token;
  StaffUser? _currentUser;

  List<RestaurantTable> _tables = [];
  List<Product> _products = [];
  List<Reservation> _reservations = [];
  List<Order> _orders = [];
  List<StaffUser> _staff = [];

  int? _selectedAdminTableId;

  // Estado do Cardápio Digital do Cliente
  List<CustomerCartItem> _customerCart = [];
  int? _selectedCustomerTableId;
  String _customerName = '';

  RestaurantProvider({
    ApiService? apiService,
    this.enableAutoPolling = true,
  }) : _api = apiService ?? ApiService();

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get busy => _busy;
  bool get isBackendOnline => _isBackendOnline;
  String? get lastError => _lastError;

  String get apiBaseUrl => _api.baseUrl;
  String? get token => _token;
  StaffUser? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  List<RestaurantTable> get tables => _tables;
  List<Product> get products => _products;
  List<Reservation> get reservations => _reservations;
  List<Order> get orders => _orders;
  List<StaffUser> get staff => _staff;

  List<Order> get openOrders =>
      _orders.where((o) => o.status == OrderStatus.open).toList();

  RestaurantTable? get selectedAdminTable {
    if (_tables.isEmpty) return null;
    if (_selectedAdminTableId != null) {
      for (final t in _tables) {
        if (t.id == _selectedAdminTableId) return t;
      }
    }
    for (final t in _tables) {
      if (t.number == 4) return t;
    }
    return _tables.first;
  }

  Order? get activeAdminOrder {
    final table = selectedAdminTable;
    if (table == null) return null;
    for (final o in _orders) {
      if (o.tableId == table.id && o.status == OrderStatus.open) {
        return o;
      }
    }
    return null;
  }

  List<CustomerCartItem> get customerCart => _customerCart;
  String get customerName => _customerName;

  int get customerCartItemCount =>
      _customerCart.fold<int>(0, (sum, i) => sum + i.quantity);

  double get customerCartSubtotal =>
      _customerCart.fold<double>(0.0, (sum, i) => sum + i.lineTotal);

  RestaurantTable? get selectedCustomerTable {
    if (_tables.isEmpty) return null;
    if (_selectedCustomerTableId != null) {
      for (final t in _tables) {
        if (t.id == _selectedCustomerTableId) return t;
      }
    }
    for (final t in _tables) {
      if (t.number == 4) return t;
    }
    return _tables.first;
  }

  Order? get activeCustomerTableOrder {
    final table = selectedCustomerTable;
    if (table == null) return null;
    for (final o in _orders) {
      if (o.tableId == table.id && o.status == OrderStatus.open) {
        return o;
      }
    }
    return null;
  }

  List<String> get categories {
    const base = ['Bebida', 'Sobremesa', 'Prato principal', 'Entrada'];
    final seen = <String>{...base};
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        seen.add(p.category.trim());
      }
    }
    return seen.toList();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    final savedUrl = prefs.getString(_kApiUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _api.setBaseUrl(savedUrl);
    }

    _token = prefs.getString(_kTokenKey);
    _api.setToken(_token);

    final rawUser = prefs.getString(_kUserKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _currentUser =
            StaffUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    }

    _selectedCustomerTableId = prefs.getInt(_kCustomerTableKey);
    _customerName = prefs.getString(_kCustomerNameKey) ?? '';

    final rawCart = prefs.getString(_kCartKey);
    if (rawCart != null && rawCart.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCart) as List<dynamic>;
        _customerCart = decoded
            .whereType<Map<String, dynamic>>()
            .map(CustomerCartItem.fromJson)
            .toList();
      } catch (_) {
        _customerCart = [];
      }
    }

    _initialized = true;
    notifyListeners();

    if (enableAutoPolling) {
      if (isAuthenticated) {
        await refreshDashboard(silent: true);
      } else {
        await refreshPublicMenu(silent: true);
      }
      _startAutoPolling();
    }
  }

  void _startAutoPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_busy) return;
      if (isAuthenticated) {
        refreshDashboard(silent: true);
      } else {
        refreshPublicMenu(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> updateApiBaseUrl(String newUrl) async {
    final normalized = ApiConfig.normalizeBaseUrl(newUrl);
    _api.setBaseUrl(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiUrlKey, normalized);
    notifyListeners();

    if (isAuthenticated) {
      await refreshDashboard();
    } else {
      await refreshPublicMenu();
    }
  }

  Future<void> resetApiBaseUrl() async {
    final defaultUrl = ApiConfig.defaultBaseUrl;
    _api.setBaseUrl(defaultUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiUrlKey);
    notifyListeners();

    if (isAuthenticated) {
      await refreshDashboard();
    } else {
      await refreshPublicMenu();
    }
  }

  // ===========================================================================
  // AUTENTICAÇÃO
  // ===========================================================================

  Future<void> login(String email, String password) async {
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      final auth = await _api.login(email, password);
      _token = auth.accessToken;
      _currentUser = auth.user;
      _api.setToken(_token);
      _isBackendOnline = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, auth.accessToken);
      await prefs.setString(_kUserKey, jsonEncode(auth.user.toJson()));

      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> registerAndLogin({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      await _api.registerStaff(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      final auth = await _api.login(email, password);
      _token = auth.accessToken;
      _currentUser = auth.user;
      _api.setToken(_token);
      _isBackendOnline = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, auth.accessToken);
      await prefs.setString(_kUserKey, jsonEncode(auth.user.toJson()));

      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
    notifyListeners();
  }

  // ===========================================================================
  // SINCRONIZAÇÃO COM O BACK-END NESTJS
  // ===========================================================================

  Future<void> refreshDashboard({bool silent = false}) async {
    if (!isAuthenticated) return;
    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      final data = await _api.fetchDashboardData();
      _tables = data.tables;
      _products = data.products;
      _reservations = data.reservations;
      _orders = data.orders;
      _staff = data.staff;
      _isBackendOnline = true;
      _lastError = null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        _lastError = 'Sessão expirada. Faça login novamente.';
      } else {
        _isBackendOnline = false;
        _lastError = e.message;
      }
    } catch (e) {
      _isBackendOnline = false;
      _lastError = e.toString();
    } finally {
      if (!silent) _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPublicMenu({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      final data = await _api.fetchPublicMenu();
      _products = data.products;
      _tables = data.tables;
      if (!isAuthenticated) {
        _orders = data.openOrders;
      } else {
        // Mantém comandas fechadas se admin estiver autenticado, atualizando as abertas
        final closed =
            _orders.where((o) => o.status != OrderStatus.open).toList();
        _orders = [...data.openOrders, ...closed];
      }
      _isBackendOnline = true;
      _lastError = null;
    } catch (e) {
      _isBackendOnline = false;
      _lastError = e.toString();
    } finally {
      if (!silent) _loading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // AÇÕES DO ATENDIMENTO / ADMIN
  // ===========================================================================

  void selectAdminTable(int tableId) {
    _selectedAdminTableId = tableId;
    notifyListeners();
  }

  Future<Order> openOrderForTable(int tableId) async {
    _busy = true;
    notifyListeners();
    try {
      final created = await _api.openOrder(
        tableId: tableId,
        userId: _currentUser?.id ?? 1,
      );
      _selectedAdminTableId = tableId;
      await refreshDashboard(silent: true);
      return created;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> addProductToSelectedTable({
    required Product product,
    required int quantity,
    String? notes,
  }) async {
    final table = selectedAdminTable;
    if (table == null) return;

    _busy = true;
    notifyListeners();
    try {
      var targetOrder = activeAdminOrder;
      targetOrder ??= await _api.openOrder(
        tableId: table.id,
        userId: _currentUser?.id ?? 1,
      );

      await _api.addOrderItem(
        orderId: targetOrder.id,
        productId: product.id,
        quantity: quantity,
        notes: notes,
      );
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderItemQuantity(int orderId, int itemId, int qty) async {
    _busy = true;
    notifyListeners();
    try {
      await _api.updateOrderItemQuantity(
        orderId: orderId,
        itemId: itemId,
        quantity: qty,
      );
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> removeOrderItem(int orderId, int itemId) async {
    _busy = true;
    notifyListeners();
    try {
      await _api.removeOrderItem(orderId: orderId, itemId: itemId);
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> transferOrder(int orderId, int targetTableId) async {
    _busy = true;
    notifyListeners();
    try {
      await _api.transferOrder(orderId: orderId, targetTableId: targetTableId);
      _selectedAdminTableId = targetTableId;
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> closeOrder(int orderId) async {
    _busy = true;
    notifyListeners();
    try {
      await _api.closeOrder(orderId);
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<RestaurantTable> createTable({
    required int number,
    required int capacity,
  }) async {
    final created = await _api.createTable(number: number, capacity: capacity);
    await refreshDashboard(silent: true);
    return created;
  }

  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    required String category,
  }) async {
    final created = await _api.createProduct(
      name: name,
      description: description,
      price: price,
      category: category,
    );
    await refreshDashboard(silent: true);
    return created;
  }

  Future<void> deleteProduct(int productId) async {
    _busy = true;
    notifyListeners();
    try {
      await _api.deleteProduct(productId);
      await refreshDashboard(silent: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Reservation> createReservation({
    required String customerName,
    required String customerPhone,
    required String dateTimeIso,
    required int guestCount,
    int? tableId,
  }) async {
    final created = await _api.createReservation(
      customerName: customerName,
      customerPhone: customerPhone,
      dateTimeIso: dateTimeIso,
      guestCount: guestCount,
      tableId: tableId,
    );
    await refreshDashboard(silent: true);
    return created;
  }

  Future<StaffUser> registerStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final created = await _api.registerStaff(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    await refreshDashboard(silent: true);
    return created;
  }

  // ===========================================================================
  // AÇÕES DO CARDÁPIO DIGITAL DO CLIENTE (AUTOATENDIMENTO)
  // ===========================================================================

  Future<void> setCustomerTable(int tableId) async {
    _selectedCustomerTableId = tableId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCustomerTableKey, tableId);
  }

  Future<void> setCustomerTableByNumber(int tableNumber) async {
    for (final t in _tables) {
      if (t.number == tableNumber) {
        await setCustomerTable(t.id);
        return;
      }
    }
  }

  Future<void> setCustomerName(String name) async {
    _customerName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustomerNameKey, name.trim());
  }

  Future<void> addToCustomerCart(
    Product product, {
    int quantity = 1,
    String notes = '',
  }) async {
    final cleanNotes = notes.trim();
    final idx = _customerCart.indexWhere(
      (item) => item.product.id == product.id && item.notes == cleanNotes,
    );
    if (idx >= 0) {
      final existing = _customerCart[idx];
      _customerCart[idx] =
          existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _customerCart.add(
        CustomerCartItem(
          product: product,
          quantity: quantity,
          notes: cleanNotes,
        ),
      );
    }
    notifyListeners();
    await _persistCart();
  }

  Future<void> updateCustomerCartQuantity(int index, int delta) async {
    if (index < 0 || index >= _customerCart.length) return;
    final nextQty = _customerCart[index].quantity + delta;
    if (nextQty <= 0) {
      _customerCart.removeAt(index);
    } else {
      _customerCart[index] = _customerCart[index].copyWith(quantity: nextQty);
    }
    notifyListeners();
    await _persistCart();
  }

  Future<void> removeCustomerCartItem(int index) async {
    if (index < 0 || index >= _customerCart.length) return;
    _customerCart.removeAt(index);
    notifyListeners();
    await _persistCart();
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCartKey,
      jsonEncode(_customerCart.map((e) => e.toJson()).toList()),
    );
  }

  Future<Order> submitCustomerCartOrder() async {
    final table = selectedCustomerTable;
    if (table == null) {
      throw const ApiException('Selecione uma mesa antes de enviar o pedido.');
    }
    if (_customerCart.isEmpty) {
      throw const ApiException('Sua sacola está vazia.');
    }

    _busy = true;
    notifyListeners();
    try {
      final order = await _api.submitCustomerOrder(
        tableId: table.id,
        customerName: _customerName.trim().isEmpty ? null : _customerName.trim(),
        items: List<CustomerCartItem>.from(_customerCart),
      );
      _customerCart = [];
      await _persistCart();

      if (isAuthenticated) {
        await refreshDashboard(silent: true);
      } else {
        await refreshPublicMenu(silent: true);
      }
      return order;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
