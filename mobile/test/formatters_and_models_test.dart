import 'package:flutter_test/flutter_test.dart';
import 'package:restaurante_mesa_mobile/config/api_config.dart';
import 'package:restaurante_mesa_mobile/models/restaurant_models.dart';
import 'package:restaurante_mesa_mobile/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('formata valores em reais (BRL)', () {
      expect(Formatters.formatCurrency(0), 'R\$ 0,00');
      expect(Formatters.formatCurrency(284), 'R\$ 284,00');
      expect(Formatters.formatCurrency(1234.5), 'R\$ 1.234,50');
      expect(
        Formatters.formatCurrency(89.9, includeSymbol: false),
        '89,90',
      );
    });

    test('formata numero da mesa e codigo do pedido', () {
      expect(Formatters.formatTableNumber(4), '04');
      expect(Formatters.formatTableNumber(12), '12');
      expect(Formatters.formatOrderDisplayNumber(3), '#1042');
      expect(Formatters.formatOrderDisplayNumber(1042), '#1042');
    });

    test('normaliza URL base da API', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://192.168.0.10:3000/'),
        'http://192.168.0.10:3000/api',
      );
      expect(
        ApiConfig.normalizeBaseUrl('10.0.2.2:3000/api/'),
        'http://10.0.2.2:3000/api',
      );
    });
  });

  group('Restaurant Models', () {
    test('desserializa Order e calcula taxa de servico de 10%', () {
      final order = Order.fromJson({
        'id': 3,
        'openedAt': '2026-10-20T18:40:00.000Z',
        'status': 'OPEN',
        'totalAmount': 284.0,
        'tableId': 4,
        'userId': 1,
        'table': {'id': 4, 'number': 4, 'capacity': 4, 'status': 'OCCUPIED'},
        'orderItems': [
          {
            'id': 1,
            'orderId': 3,
            'productId': 4,
            'quantity': 2,
            'unitPrice': 89.0,
            'product': {
              'id': 4,
              'name': 'Bife grelhado',
              'price': 89.0,
              'category': 'Prato principal',
            },
          },
          {
            'id': 2,
            'orderId': 3,
            'productId': 5,
            'quantity': 1,
            'unitPrice': 64.0,
            'product': {
              'id': 5,
              'name': 'Risoto de cogumelos',
              'price': 64.0,
              'category': 'Prato principal',
            },
          },
          {
            'id': 3,
            'orderId': 3,
            'productId': 1,
            'quantity': 2,
            'unitPrice': 8.0,
          },
          {
            'id': 4,
            'orderId': 3,
            'productId': 3,
            'quantity': 1,
            'unitPrice': 26.0,
          },
        ],
      });

      expect(order.totalItemCount, 6);
      expect(order.subtotal, 284.0);
      expect(order.serviceFee, closeTo(28.4, 0.001));
      expect(order.totalWithServiceFee, closeTo(312.4, 0.001));
    });
  });
}
