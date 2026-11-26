import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurante_mesa_mobile/main.dart';
import 'package:restaurante_mesa_mobile/models/restaurant_models.dart';
import 'package:restaurante_mesa_mobile/providers/restaurant_provider.dart';
import 'package:restaurante_mesa_mobile/screens/admin_shell_screen.dart';
import 'package:restaurante_mesa_mobile/screens/customer_menu_screen.dart';
import 'package:restaurante_mesa_mobile/services/api_service.dart';
import 'package:restaurante_mesa_mobile/theme/app_theme.dart';

class _FakeApiService extends ApiService {
  static final _tables = [
    const RestaurantTable(
      id: 1,
      number: 1,
      capacity: 2,
      status: TableStatus.available,
    ),
    const RestaurantTable(
      id: 2,
      number: 2,
      capacity: 4,
      status: TableStatus.occupied,
    ),
    const RestaurantTable(
      id: 3,
      number: 3,
      capacity: 4,
      status: TableStatus.reserved,
    ),
    const RestaurantTable(
      id: 4,
      number: 4,
      capacity: 4,
      status: TableStatus.occupied,
    ),
  ];

  static final _products = [
    const Product(
      id: 1,
      name: 'Água com gás',
      description:
          'Garrafa 350ml naturalmente gaseificada com rodela de limão siciliano',
      price: 8.0,
      category: 'Bebida',
    ),
    const Product(
      id: 2,
      name: 'Limonada natural',
      description: 'Limões taiti e siciliano espremidos na hora com hortelã',
      price: 16.0,
      category: 'Bebida',
    ),
    const Product(
      id: 4,
      name: 'Bife grelhado',
      description:
          'Corte nobre de ancho grelhado na brasa com manteiga de ervas e batatas rústicas',
      price: 89.0,
      category: 'Prato principal',
    ),
  ];

  static final _reservations = [
    Reservation(
      id: 1,
      customerName: 'Ana Martins',
      customerPhone: '(54) 99912-3456',
      dateTime: '2026-10-20T19:30:00.000Z',
      guestCount: 4,
      status: ReservationStatus.confirmed,
      tableId: 3,
      table: _tables[2],
    ),
  ];

  static final _staff = [
    const StaffUser(
      id: 1,
      name: 'Administrador Geral',
      email: 'admin@restaurant.com',
      role: UserRole.admin,
    ),
    const StaffUser(
      id: 2,
      name: 'Garçom João',
      email: 'waiter@restaurant.com',
      role: UserRole.waiter,
    ),
  ];

  static final _orders = [
    Order(
      id: 3,
      openedAt: '2026-10-20T18:40:00.000Z',
      status: OrderStatus.open,
      totalAmount: 194.0,
      tableId: 4,
      userId: 1,
      table: _tables[3],
      user: _staff[0],
      orderItems: [
        OrderItem(
          id: 1,
          quantity: 2,
          notes: '[Cliente: Ana] Ao ponto',
          unitPrice: 89.0,
          orderId: 3,
          productId: 4,
          product: _products[2],
        ),
        OrderItem(
          id: 2,
          quantity: 1,
          unitPrice: 16.0,
          orderId: 3,
          productId: 2,
          product: _products[1],
        ),
      ],
    ),
  ];

  @override
  Future<AuthResponse> login(String email, String password) async {
    return AuthResponse(accessToken: 'fake-token', user: _staff[0]);
  }

  @override
  Future<PublicMenuData> fetchPublicMenu() async {
    return PublicMenuData(
      products: _products,
      tables: _tables,
      openOrders: _orders,
    );
  }

  @override
  Future<DashboardData> fetchDashboardData() async {
    return DashboardData(
      tables: _tables,
      products: _products,
      reservations: _reservations,
      orders: _orders,
      staff: _staff,
    );
  }
}

const _viewports = <String, Size>{
  'celular compacto (320x640)': Size(320, 640),
  'celular padrão (390x844)': Size(390, 844),
  'tablet (768x1024)': Size(768, 1024),
  'tela média (960x720)': Size(960, 720),
  'desktop (1280x800)': Size(1280, 800),
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renderiza tela de Login e preenche credenciais do Seed',
      (WidgetTester tester) async {
    final provider = RestaurantProvider(
      apiService: _FakeApiService(),
      enableAutoPolling: false,
    );

    await tester.pumpWidget(RestauranteMesaApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Abrir Cardápio Digital →'), findsOneWidget);

    await tester.tap(find.text('Credenciais padrão (Seed)?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar Admin'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'admin@restaurant.com'),
      findsOneWidget,
    );
  });

  for (final entry in _viewports.entries) {
    testWidgets('LoginScreen sem overflow em ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = RestaurantProvider(
        apiService: _FakeApiService(),
        enableAutoPolling: false,
      );
      await tester.pumpWidget(RestauranteMesaApp(provider: provider));
      await tester.pumpAndSettle();
      
    });

    testWidgets('CustomerMenuScreen sem overflow em ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = RestaurantProvider(
        apiService: _FakeApiService(),
        enableAutoPolling: false,
      );
      await provider.initialize();
      await provider.refreshPublicMenu();
      await provider.addToCustomerCart(
        _FakeApiService._products[0],
        quantity: 2,
        notes: 'sem gelo',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<RestaurantProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CustomerMenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      

      // Troca para aba Conta da Mesa / Conta
      if (entry.value.width >= 960) {
        await tester.tap(find.text('Conta da Mesa'));
      } else {
        await tester.tap(find.text('Sacola'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Conta'));
      }
      await tester.pumpAndSettle();
      
    });

    testWidgets('AdminShellScreen (PDV e Gestão) sem overflow em ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = RestaurantProvider(
        apiService: _FakeApiService(),
        enableAutoPolling: false,
      );
      await provider.initialize();
      await provider.login('admin@restaurant.com', 'admin123');

      await tester.pumpWidget(
        ChangeNotifierProvider<RestaurantProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdminShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      

      // No modo mobile/tablet, alterna entre as 3 sub-abas do PDV
      if (entry.value.width < 1180) {
        await tester.tap(find.text('Catálogo'));
        await tester.pumpAndSettle();
        

        await tester.tap(find.textContaining('Mesa 04').first);
        await tester.pumpAndSettle();
        
      }

      // Alterna para Gestão Completa e navega pelas abas
      await tester.tap(find.text('Gestão Completa'));
      await tester.pumpAndSettle();
      

      for (final tabPrefix in [
        'Reservas (',
        'Produtos (',
        'Pedidos (',
        'Funcionários (',
      ]) {
        final tabFinder = find.textContaining(tabPrefix);
        await tester.ensureVisible(tabFinder);
        await tester.pumpAndSettle();
        await tester.tap(tabFinder);
        await tester.pumpAndSettle();
      }
    });
  }
}
