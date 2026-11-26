import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand_widgets.dart';

/// Tela pública de Cardápio Digital de Autoatendimento para clientes na mesa.
/// Envia pedidos diretamente para POST /api/public/orders, sincronizando em tempo real
/// com a Área de Atendimento do app Flutter e do Front-end Next.js (/atendimento).
class CustomerMenuScreen extends StatefulWidget {
  final int? initialTableNumber;

  const CustomerMenuScreen({super.key, this.initialTableNumber});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final _searchCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();

  String _selectedCategory = 'ALL';
  int _sideTabIndex = 0; // 0 = Sacola, 1 = Conta da Mesa
  int _mobileTabIndex = 0; // 0 = Cardápio, 1 = Sacola, 2 = Conta da Mesa

  final Map<int, int> _cardQuantities = {};
  final Map<int, TextEditingController> _cardNoteControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RestaurantProvider>();
      _customerNameCtrl.text = provider.customerName;
      await provider.refreshPublicMenu();
      if (widget.initialTableNumber != null) {
        await provider.setCustomerTableByNumber(widget.initialTableNumber!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customerNameCtrl.dispose();
    for (final ctrl in _cardNoteControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteControllerFor(int productId) {
    return _cardNoteControllers.putIfAbsent(
      productId,
      () => TextEditingController(),
    );
  }

  int _qtyFor(int productId) => _cardQuantities[productId] ?? 1;

  void _changeQty(int productId, int delta) {
    setState(() {
      final next = (_cardQuantities[productId] ?? 1) + delta;
      _cardQuantities[productId] = next < 1 ? 1 : next;
    });
  }

  Future<void> _addToCart(Product product) async {
    final provider = context.read<RestaurantProvider>();
    final qty = _qtyFor(product.id);
    final noteCtrl = _noteControllerFor(product.id);
    final notes = noteCtrl.text.trim();

    await provider.addToCustomerCart(product, quantity: qty, notes: notes);

    setState(() {
      _cardQuantities[product.id] = 1;
      noteCtrl.clear();
      _sideTabIndex = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${qty}x ${product.name} adicionado à sua sacola!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendOrderToKitchen() async {
    final provider = context.read<RestaurantProvider>();
    try {
      await provider.setCustomerName(_customerNameCtrl.text.trim());
      final order = await provider.submitCustomerCartOrder();
      final table = provider.selectedCustomerTable;

      setState(() {
        _sideTabIndex = 1;
        _mobileTabIndex = 2;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido enviado para a Mesa ${table != null ? Formatters.formatTableNumber(table.number) : ''} (${Formatters.formatOrderDisplayNumber(order.id)})!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redBorder,
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 960;
    final sidePanelWidth = screenWidth >= 1280 ? 390.0 : 340.0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const Row(
          children: [
            BrandLogoBadge(size: 32, iconSize: 18),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cardápio Digital · Restaurante Mesa',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Autoatendimento integrado ao salão',
                    style: TextStyle(fontSize: 11, color: AppColors.emeraldText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const Center(child: ConnectionStatusPill()),
          IconButton(
            tooltip: 'Atualizar cardápio',
            onPressed: () => provider.refreshPublicMenu(),
            icon: const Icon(Icons.refresh, size: 20),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildTableAndCustomerBar(provider),
          Expanded(
            child: provider.loading && provider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : isWide
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildCatalogPanel(provider),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: sidePanelWidth,
                              child: _buildSidePanel(provider),
                            ),
                          ],
                        ),
                      )
                    : IndexedStack(
                        index: _mobileTabIndex,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildCatalogPanel(provider),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildCartView(provider),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildBillView(provider),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              backgroundColor: AppColors.header,
              indicatorColor: AppColors.cardElevated,
              selectedIndex: _mobileTabIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _mobileTabIndex = idx),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu),
                  label: 'Cardápio',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: provider.customerCartItemCount > 0,
                    label: Text('${provider.customerCartItemCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: provider.customerCartItemCount > 0,
                    label: Text('${provider.customerCartItemCount}'),
                    child: const Icon(Icons.shopping_bag),
                  ),
                  label: 'Sacola',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: provider.activeCustomerTableOrder != null,
                    backgroundColor: AppColors.amberText,
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: 'Conta',
                ),
              ],
            ),
    );
  }

  Widget _buildTableAndCustomerBar(RestaurantProvider provider) {
    final selectedTable = provider.selectedCustomerTable;
    final isCompact = MediaQuery.of(context).size.width < 600;

    final tableDropdown = DropdownButtonFormField<int>(
      key: ValueKey<int?>(selectedTable?.id),
      initialValue: selectedTable?.id,
      dropdownColor: AppColors.card,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sua Mesa',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: provider.tables
          .map(
            (t) => DropdownMenuItem<int>(
              value: t.id,
              child: Text(
                isCompact
                    ? 'Mesa ${Formatters.formatTableNumber(t.number)} · ${t.status == TableStatus.occupied ? 'Aberta' : t.status.ptLabel}'
                    : 'Mesa ${Formatters.formatTableNumber(t.number)} (${t.capacity} lug.) · ${t.status == TableStatus.occupied ? 'Comanda Aberta' : t.status.ptLabel}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) provider.setCustomerTable(val);
      },
    );

    final nameInput = TextField(
      controller: _customerNameCtrl,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        labelText: 'Seu Nome (opcional)',
        hintText: 'Ex: Ana',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: (val) => provider.setCustomerName(val),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: isCompact
          ? Row(
              children: [
                Expanded(flex: 6, child: tableDropdown),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: nameInput),
              ],
            )
          : Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 260, child: tableDropdown),
                SizedBox(width: 220, child: nameInput),
              ],
            ),
    );
  }

  Widget _buildCatalogPanel(RestaurantProvider provider) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = provider.products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.description ?? '').toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchesCat = _selectedCategory == 'ALL' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCat;
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
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Catálogo do Cardápio',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} produtos',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Buscar pratos, entradas, bebidas ou sobremesas...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Todos os produtos',
                  selected: _selectedCategory == 'ALL',
                  onTap: () => setState(() => _selectedCategory = 'ALL'),
                ),
                ...provider.categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
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
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum produto encontrado.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : LayoutBuilder(
                    builder: (_, constraints) {
                      final useTwoColumns = constraints.maxWidth >= 520;
                      if (useTwoColumns) {
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 274,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) =>
                              _buildCustomerProductCard(filtered[idx]),
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, idx) =>
                            _buildCustomerProductCard(filtered[idx]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerProductCard(Product product) {
    final qty = _qtyFor(product.id);
    final noteCtrl = _noteControllerFor(product.id);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      Formatters.formatCurrency(product.price),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  QuantityStepper(
                    value: qty,
                    onDecrement: () => _changeQty(product.id, -1),
                    onIncrement: () => _changeQty(product.id, 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Observação (ex: sem gelo, ao ponto)...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(product),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar ao pedido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(RestaurantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
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
                  child: _SegmentButton(
                    label:
                        'Sacola${provider.customerCartItemCount > 0 ? ' (${provider.customerCartItemCount})' : ''}',
                    selected: _sideTabIndex == 0,
                    onTap: () => setState(() => _sideTabIndex = 0),
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    label: 'Conta da Mesa',
                    selected: _sideTabIndex == 1,
                    onTap: () => setState(() => _sideTabIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _sideTabIndex == 0
                ? _buildCartView(provider)
                : _buildBillView(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCartView(RestaurantProvider provider) {
    final table = provider.selectedCustomerTable;
    final cart = provider.customerCart;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      Text(
                        'Mesa ${table != null ? Formatters.formatTableNumber(table.number) : '--'}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        provider.customerName.isNotEmpty
                            ? 'Cliente: ${provider.customerName}'
                            : 'Novo envio para a comanda',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.emeraldBorder),
                  ),
                  child: const Text(
                    'PRONTO P/ ENVIAR',
                    style: TextStyle(
                      color: AppColors.emeraldText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sua sacola está vazia',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Adicione itens do cardápio para enviar seu pedido diretamente para a mesa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, idx) {
                      final item = cart[idx];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${Formatters.formatCurrency(item.product.price)} cada',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (item.notes.isNotEmpty)
                                  Text(
                                    'Obs: ${item.notes}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.amberText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            value: item.quantity,
                            onDecrement: () =>
                                provider.updateCustomerCartQuantity(idx, -1),
                            onIncrement: () =>
                                provider.updateCustomerCartQuantity(idx, 1),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              InkWell(
                                onTap: () =>
                                    provider.removeCustomerCartItem(idx),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Total do envio',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.formatCurrency(provider.customerCartSubtotal),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.busy ? null : _sendOrderToKitchen,
              child: Text(
                provider.busy
                    ? 'Enviando para o salão...'
                    : 'Confirmar e Enviar para Mesa ${table != null ? Formatters.formatTableNumber(table.number) : ''}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillView(RestaurantProvider provider) {
    final table = provider.selectedCustomerTable;
    final order = provider.activeCustomerTableOrder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: order == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma comanda aberta na Mesa ${table != null ? Formatters.formatTableNumber(table.number) : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assim que você enviar seu primeiro pedido pela sacola, a comanda será aberta automaticamente!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                            Text(
                              'Mesa ${table != null ? Formatters.formatTableNumber(table.number) : ''} · ${Formatters.formatOrderDisplayNumber(order.id)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Aberto às ${Formatters.formatTimeHHMM(order.openedAt)} · ${order.totalItemCount} itens',
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.amberBorder),
                        ),
                        child: const Text(
                          'ABERTO',
                          style: TextStyle(
                            color: AppColors.amberText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: order.orderItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 14),
                    itemBuilder: (_, idx) {
                      final item = order.orderItems[idx];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.product?.name ?? 'Produto #${item.productId}'}',
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
                                if (item.notes != null &&
                                    item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.emeraldText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(
                              item.lineTotal,
                              includeSymbol: false,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Subtotal',
                  value: Formatters.formatCurrency(order.subtotal),
                ),
                const SizedBox(height: 4),
                _SummaryRow(
                  label: 'Taxa de serviço (10%)',
                  value: Formatters.formatCurrency(order.serviceFee),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Total parcial da mesa',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatCurrency(order.totalWithServiceFee),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
