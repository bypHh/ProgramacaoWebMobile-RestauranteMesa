enum UserRole {
  admin('ADMIN'),
  manager('MANAGER'),
  waiter('WAITER'),
  receptionist('RECEPTIONIST');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'MANAGER':
        return UserRole.manager;
      case 'RECEPTIONIST':
        return UserRole.receptionist;
      case 'WAITER':
      default:
        return UserRole.waiter;
    }
  }
}

enum TableStatus {
  available('AVAILABLE'),
  occupied('OCCUPIED'),
  reserved('RESERVED');

  final String value;
  const TableStatus(this.value);

  static TableStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'OCCUPIED':
        return TableStatus.occupied;
      case 'RESERVED':
        return TableStatus.reserved;
      case 'AVAILABLE':
      default:
        return TableStatus.available;
    }
  }

  String get ptLabel {
    switch (this) {
      case TableStatus.available:
        return 'DISPONÍVEL';
      case TableStatus.occupied:
        return 'OCUPADA';
      case TableStatus.reserved:
        return 'RESERVADA';
    }
  }
}

enum ReservationStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  cancelled('CANCELLED');

  final String value;
  const ReservationStatus(this.value);

  static ReservationStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      case 'PENDING':
      default:
        return ReservationStatus.pending;
    }
  }
}

enum OrderStatus {
  open('OPEN'),
  closed('CLOSED'),
  cancelled('CANCELLED');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'CLOSED':
        return OrderStatus.closed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'OPEN':
      default:
        return OrderStatus.open;
    }
  }
}

class StaffUser {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? createdAt;

  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: UserRole.fromString(json['role'] as String?),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.value,
        if (createdAt != null) 'createdAt': createdAt,
      };
}

class AuthResponse {
  final String accessToken;
  final StaffUser user;

  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: (json['access_token'] as String?) ?? '',
      user: StaffUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class RestaurantTable {
  final int id;
  final int number;
  final int capacity;
  final TableStatus status;
  final String? createdAt;
  final String? updatedAt;

  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: (json['id'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      status: TableStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'capacity': capacity,
        'status': status.value,
      };
}

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] as String?) ?? 'Outros',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
      };
}

class Reservation {
  final int id;
  final String customerName;
  final String customerPhone;
  final String dateTime;
  final int guestCount;
  final ReservationStatus status;
  final int? tableId;
  final RestaurantTable? table;

  const Reservation({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.dateTime,
    required this.guestCount,
    required this.status,
    this.tableId,
    this.table,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: (json['id'] as num).toInt(),
      customerName: (json['customerName'] as String?) ?? '',
      customerPhone: (json['customerPhone'] as String?) ?? '',
      dateTime: (json['dateTime'] as String?) ?? '',
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 1,
      status: ReservationStatus.fromString(json['status'] as String?),
      tableId: (json['tableId'] as num?)?.toInt(),
      table: json['table'] is Map<String, dynamic>
          ? RestaurantTable.fromJson(json['table'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int quantity;
  final String? notes;
  final double unitPrice;
  final int orderId;
  final int productId;
  final Product? product;

  const OrderItem({
    required this.id,
    required this.quantity,
    this.notes,
    required this.unitPrice,
    required this.orderId,
    required this.productId,
    this.product,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      product: json['product'] is Map<String, dynamic>
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Order {
  final int id;
  final String openedAt;
  final OrderStatus status;
  final double totalAmount;
  final int tableId;
  final int userId;
  final RestaurantTable? table;
  final StaffUser? user;
  final List<OrderItem> orderItems;

  const Order({
    required this.id,
    required this.openedAt,
    required this.status,
    required this.totalAmount,
    required this.tableId,
    required this.userId,
    this.table,
    this.user,
    required this.orderItems,
  });

  int get totalItemCount =>
      orderItems.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => orderItems.isNotEmpty
      ? orderItems.fold<double>(0.0, (sum, item) => sum + item.lineTotal)
      : totalAmount;

  double get serviceFee => subtotal * 0.10;

  double get totalWithServiceFee => subtotal + serviceFee;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['orderItems'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromJson)
            .toList()
        : <OrderItem>[];

    return Order(
      id: (json['id'] as num).toInt(),
      openedAt: (json['openedAt'] as String?) ?? '',
      status: OrderStatus.fromString(json['status'] as String?),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      tableId: (json['tableId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      table: json['table'] is Map<String, dynamic>
          ? RestaurantTable.fromJson(json['table'] as Map<String, dynamic>)
          : null,
      user: json['user'] is Map<String, dynamic>
          ? StaffUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      orderItems: items,
    );
  }
}

class CustomerCartItem {
  final Product product;
  final int quantity;
  final String notes;

  const CustomerCartItem({
    required this.product,
    required this.quantity,
    this.notes = '',
  });

  double get lineTotal => product.price * quantity;

  CustomerCartItem copyWith({
    Product? product,
    int? quantity,
    String? notes,
  }) {
    return CustomerCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  factory CustomerCartItem.fromJson(Map<String, dynamic> json) {
    return CustomerCartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'notes': notes,
      };
}

class PublicMenuData {
  final List<Product> products;
  final List<RestaurantTable> tables;
  final List<Order> openOrders;

  const PublicMenuData({
    required this.products,
    required this.tables,
    required this.openOrders,
  });
}

class DashboardData {
  final List<RestaurantTable> tables;
  final List<Product> products;
  final List<Reservation> reservations;
  final List<Order> orders;
  final List<StaffUser> staff;

  const DashboardData({
    required this.tables,
    required this.products,
    required this.reservations,
    required this.orders,
    required this.staff,
  });
}
