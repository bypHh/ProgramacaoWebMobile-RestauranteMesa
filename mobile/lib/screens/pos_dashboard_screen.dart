import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand_widgets.dart';

/// Área de Atendimento (PDV) — porte completo de PosDashboardClient.tsx:
/// - Coluna 1: Mesas e reservas (filtros TODAS / DISPONÍVEIS / OCUPADAS / RESERVADAS + Próximas reservas)
/// - Coluna 2: Catálogo de produtos (busca, categorias, quantidade, exclusão e adição à mesa selecionada)
/// - Coluna 3: Pedido ativo (itens, +/- quantidade, remover, observação, subtotal + 10%, fechar conta, imprimir e transferir mesa)
class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  final _searchCtrl = TextEditingController();
  final _orderNoteCtrl = TextEditingController();

  int _leftTabIndex = 0; // 0 = Mesas, 1 = Reservas
  TableStatus? _tableFilter; // null = TODAS
  bool _showUpcomingReservations = true;

  String _selectedCategory = 'ALL';
  final Map<int, int> _productQuantities = {};

  int _mobileSubTab = 0; // 0 = Mesas, 1 = Catálogo, 2 = Pedido Ativo

  @override
  void dispose() {
    _searchCtrl.dispose();
    _orderNoteCtrl.dispose();
    super.dispose();
  }

  int _qtyFor(int productId) => _productQuantities[productId] ?? 1;

  void _changeProductQty(int productId, int delta) {
    setState(() {
      final next = (_productQuantities[productId] ?? 1) + delta;
      _productQuantities[productId] = next < 1 ? 1 : next;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? AppColors.redBorder : AppColors.primaryButtonBg,
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : AppColors.primaryButtonFg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openOrderForTable(RestaurantTable table) async {
    final provider = context.read<RestaurantProvider>();
    try {
      final order = await provider.openOrderForTable(table.id);
      _showSnack(
        'Comanda ${Formatters.formatOrderDisplayNumber(order.id)} aberta na Mesa ${Formatters.formatTableNumber(table.number)}!',
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _addProduct(Product product) async {
    final provider = context.read<RestaurantProvider>();
    final qty = _qtyFor(product.id);
    try {
      await provider.addProductToSelectedTable(
        product: product,
        quantity: qty,
        notes: _orderNoteCtrl.text.trim(),
      );
      setState(() => _productQuantities[product.id] = 1);
      final table = provider.selectedAdminTable;
      _showSnack(
        '${qty}x ${product.name} adicionado à Mesa ${table != null ? Formatters.formatTableNumber(table.number) : ''}!',
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final provider = context.read<RestaurantProvider>();
    try {
      await provider.deleteProduct(product.id);
      _showSnack('Produto "${product.name}" removido.');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _closeActiveOrder(Order order, RestaurantTable table) async {
    final provider = context.read<RestaurantProvider>();
    try {
      await provider.closeOrder(order.id);
      _showSnack(
        'Conta ${Formatters.formatOrderDisplayNumber(order.id)} da Mesa ${Formatters.formatTableNumber(table.number)} fechada com sucesso!',
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1180;

    if (provider.loading && provider.tables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width >= 1400 ? 330 : 295,
              child: _buildTablesColumn(provider),
            ),
            const SizedBox(width: 14),
            Expanded(child: _buildCatalogColumn(provider)),
            const SizedBox(width: 14),
            SizedBox(
              width: width >= 1400 ? 390 : 345,
              child: _buildActiveOrderColumn(provider),
            ),
          ],
        ),
      );
    }

    final activeOrder = provider.activeAdminOrder;
    final selectedTable = provider.selectedAdminTable;

    return Column(
      children: [
        Container(
          color: AppColors.panel,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _MobileTabChip(
                  label: 'Mesas (${provider.tables.length})',
                  selected: _mobileSubTab == 0,
                  onTap: () => setState(() => _mobileSubTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTabChip(
                  label: 'Catálogo',
                  selected: _mobileSubTab == 1,
                  onTap: () => setState(() => _mobileSubTab = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileTabChip(
                  label: selectedTable != null
                      ? 'Mesa ${Formatters.formatTableNumber(selectedTable.number)}${activeOrder != null ? ' (${activeOrder.totalItemCount})' : ''}'
                      : 'Pedido',
                  selected: _mobileSubTab == 2,
                  onTap: () => setState(() => _mobileSubTab = 2),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IndexedStack(
              index: _mobileSubTab,
              children: [
                _buildTablesColumn(provider, onTableSelected: () {
                  setState(() => _mobileSubTab = 2);
                }),
                _buildCatalogColumn(provider),
                _buildActiveOrderColumn(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COLUNA 1: MESAS E RESERVAS
  // ===========================================================================
  Widget _buildTablesColumn(
    RestaurantProvider provider, {
    VoidCallback? onTableSelected,
  }) {
    final filteredTables = _tableFilter == null
        ? provider.tables
        : provider.tables.where((t) => t.status == _tableFilter).toList();
    final selectedTable = provider.selectedAdminTable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Mesas e reservas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.tables.length} mesas',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniToggle(
                    label: 'Mesas',
                    selected: _leftTabIndex == 0,
                    onTap: () => setState(() => _leftTabIndex = 0),
                  ),
                ),
                Expanded(
                  child: _MiniToggle(
                    label: 'Reservas',
                    selected: _leftTabIndex == 1,
                    onTap: () => setState(() => _leftTabIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_leftTabIndex == 0) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'TODAS',
                    selected: _tableFilter == null,
                    onTap: () => setState(() => _tableFilter = null),
                  ),
                  const SizedBox(width: 6),
                  _FilterPill(
                    label: 'DISPONÍVEIS',
                    selected: _tableFilter == TableStatus.available,
                    onTap: () =>
                        setState(() => _tableFilter = TableStatus.available),
                  ),
                  const SizedBox(width: 6),
                  _FilterPill(
                    label: 'OCUPADAS',
                    selected: _tableFilter == TableStatus.occupied,
                    onTap: () =>
                        setState(() => _tableFilter = TableStatus.occupied),
                  ),
                  const SizedBox(width: 6),
                  _FilterPill(
                    label: 'RESERVADAS',
                    selected: _tableFilter == TableStatus.reserved,
                    onTap: () =>
                        setState(() => _tableFilter = TableStatus.reserved),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 122,
                    ),
                    itemCount: filteredTables.length,
                    itemBuilder: (_, idx) {
                      final table = filteredTables[idx];
                      final isSelected = selectedTable?.id == table.id;

                      Order? tableOrder;
                      for (final o in provider.orders) {
                        if (o.tableId == table.id &&
                            o.status == OrderStatus.open) {
                          tableOrder = o;
                          break;
                        }
                      }

                      Reservation? tableRes;
                      for (final r in provider.reservations) {
                        if (r.tableId == table.id) {
                          tableRes = r;
                          break;
                        }
                      }

                      return InkWell(
                        onTap: () {
                          provider.selectAdminTable(table.id);
                          onTableSelected?.call();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.cardElevated
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.borderActive
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mesa ${Formatters.formatTableNumber(table.number)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isSelected)
                                    const CircleAvatar(
                                      radius: 8,
                                      backgroundColor:
                                          AppColors.primaryButtonBg,
                                      child: Icon(
                                        Icons.check,
                                        size: 11,
                                        color: AppColors.primaryButtonFg,
                                      ),
                                    )
                                  else
                                    Text(
                                      '${table.capacity} lug.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              TableStatusBadge(status: table.status),
                              if (table.status == TableStatus.available)
                                InkWell(
                                  onTap: () => _openOrderForTable(table),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Abrir pedido',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.add,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                )
                              else if (table.status == TableStatus.occupied)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Pedido ${tableOrder != null ? Formatters.formatOrderDisplayNumber(tableOrder.id) : '#${1038 + table.number}'}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '↗',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tableRes != null
                                            ? '${tableRes.customerName.split(' ').first} · ${Formatters.formatTimeHHMM(tableRes.dateTime)}'
                                            : 'Reservada',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '↗',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildUpcomingReservationsCard(provider),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.separated(
                itemCount: provider.reservations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final res = provider.reservations[idx];
                  return InkWell(
                    onTap: () {
                      if (res.tableId != null) {
                        provider.selectAdminTable(res.tableId!);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  res.customerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                res.table != null
                                    ? 'Mesa ${Formatters.formatTableNumber(res.table!.number)} ↗'
                                    : (res.tableId != null
                                        ? 'Mesa ${Formatters.formatTableNumber(res.tableId!)} ↗'
                                        : 'A definir'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.indigoText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Formatters.formatShortDate(res.dateTime)} · ${Formatters.formatTimeHHMM(res.dateTime)} · ${res.guestCount} convidados',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'Tel: ${res.customerPhone}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingReservationsCard(RestaurantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _showUpcomingReservations = !_showUpcomingReservations,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Próximas reservas',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.reservations.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showUpcomingReservations
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          if (_showUpcomingReservations && provider.reservations.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...provider.reservations.map((res) {
              final tableNum = res.table?.number ?? res.tableId ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    if (res.tableId != null) {
                      provider.selectAdminTable(res.tableId!);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.customerName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${Formatters.formatShortDate(res.dateTime)} · ${Formatters.formatTimeHHMM(res.dateTime)} · ${res.guestCount} conv.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Mesa ${Formatters.formatTableNumber(tableNum)} ↗',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.indigoText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // COLUNA 2: CATÁLOGO DE PRODUTOS
  // ===========================================================================
  Widget _buildCatalogColumn(RestaurantProvider provider) {
    final selectedTable = provider.selectedAdminTable;
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = provider.products.where((p) {
      final matchesQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.description ?? '').toLowerCase().contains(q);
      final matchesCat = _selectedCategory == 'ALL' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesQ && matchesCat;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Catálogo de produtos',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${provider.products.length} produtos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (selectedTable != null)
                Text(
                  'Adicionando à Mesa ${Formatters.formatTableNumber(selectedTable.number)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Buscar produtos...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'Todos os produtos',
                  selected: _selectedCategory == 'ALL',
                  onTap: () => setState(() => _selectedCategory = 'ALL'),
                ),
                ...provider.categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _FilterPill(
                      label: Formatters.categoryPluralLabel(cat),
                      selected: _selectedCategory.toLowerCase() ==
                          cat.toLowerCase(),
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final useTwoColumns = constraints.maxWidth >= 460;
                if (useTwoColumns) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 204,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) =>
                        _buildPosProductCard(provider, filtered[idx]),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) =>
                      _buildPosProductCard(provider, filtered[idx]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosProductCard(RestaurantProvider provider, Product product) {
    final qty = _qtyFor(product.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: provider.busy ? null : () => _deleteProduct(product),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatCurrency(product.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  QuantityStepper(
                    value: qty,
                    onDecrement: () => _changeProductQty(product.id, -1),
                    onIncrement: () => _changeProductQty(product.id, 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.busy ? null : () => _addProduct(product),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text(
                    'Adicionar ao pedido',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COLUNA 3: PEDIDO ATIVO
  // ===========================================================================
  Widget _buildActiveOrderColumn(RestaurantProvider provider) {
    final table = provider.selectedAdminTable;
    final order = provider.activeAdminOrder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useFullScroll = constraints.maxHeight < 470;

          final headerWidgets = <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Pedido ativo',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: order != null
                        ? AppColors.amberBg
                        : AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: order != null
                          ? AppColors.amberBorder
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    order != null ? 'ABERTO' : 'SEM COMANDA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: order != null
                          ? AppColors.amberText
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (table != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Mesa ${Formatters.formatTableNumber(table.number)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (order != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.formatOrderDisplayNumber(order.id),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order != null
                                ? '${table.capacity} convidados · Aberto ${Formatters.formatTimeHHMM(order.openedAt)} · ${Formatters.formatElapsedMinutes(order.openedAt)}'
                                : '${table.capacity} convidados · Aguardando abertura',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order != null)
                      IconButton(
                        tooltip: 'Prévia do cupom',
                        onPressed: () => showReceiptPreviewDialog(
                          context,
                          order: order,
                          table: table,
                        ),
                        icon: const Icon(Icons.more_horiz, size: 18),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ];

          if (order == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...headerWidgets,
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nenhum pedido aberto na ${table != null ? 'Mesa ${Formatters.formatTableNumber(table.number)}' : 'mesa selecionada'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Abra uma comanda abaixo ou adicione qualquer produto do catálogo diretamente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (table != null)
                            ElevatedButton.icon(
                              onPressed: provider.busy
                                  ? null
                                  : () => _openOrderForTable(table),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Abrir pedido nesta mesa'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          Widget buildItemsList({required bool shrinkWrap}) {
            if (order.orderItems.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Comanda aberta. Adicione produtos pelo catálogo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: shrinkWrap,
              physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
              itemCount: order.orderItems.length,
              separatorBuilder: (_, __) => const Divider(height: 14),
              itemBuilder: (_, idx) {
                final item = order.orderItems[idx];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product?.name ?? 'Produto #${item.productId}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(item.unitPrice)} cada',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.emeraldText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    QuantityStepper(
                      value: item.quantity,
                      onDecrement: () => provider.updateOrderItemQuantity(
                        order.id,
                        item.id,
                        item.quantity - 1,
                      ),
                      onIncrement: () => provider.updateOrderItemQuantity(
                        order.id,
                        item.id,
                        item.quantity + 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(
                            item.lineTotal,
                            includeSymbol: false,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          onTap: () => provider.removeOrderItem(
                            order.id,
                            item.id,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          }

          final itemsHeader = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Itens neste pedido · ${order.totalItemCount} itens',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'BRL / R\$',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          );

          final footerWidgets = <Widget>[
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: TextField(
                controller: _orderNoteCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.edit_note, size: 17),
                  hintText: 'Observação para próximos itens...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal',
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatCurrency(order.subtotal),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Taxa de serviço (10%)',
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatCurrency(order.serviceFee),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Total a pagar',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatCurrency(order.totalWithServiceFee),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: provider.busy || table == null
                  ? null
                  : () => _closeActiveOrder(order, table),
              icon: const Icon(Icons.credit_card, size: 16),
              label: const Text('Fechar conta e receber'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: table == null
                        ? null
                        : () => showReceiptPreviewDialog(
                              context,
                              order: order,
                              table: table,
                            ),
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const Text(
                      'Imprimir',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => showTransferTableDialog(
                      context,
                      order: order,
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text(
                      'Transferir',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ];

          if (useFullScroll) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...headerWidgets,
                  itemsHeader,
                  const SizedBox(height: 8),
                  buildItemsList(shrinkWrap: true),
                  ...footerWidgets,
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...headerWidgets,
              itemsHeader,
              const SizedBox(height: 8),
              Expanded(child: buildItemsList(shrinkWrap: false)),
              ...footerWidgets,
            ],
          );
        },
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardElevated : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.borderActive : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MobileTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryButtonBg : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  selected ? AppColors.primaryButtonFg : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
