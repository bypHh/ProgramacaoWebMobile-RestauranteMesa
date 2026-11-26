import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/admin_modals.dart';
import '../widgets/brand_widgets.dart';
import 'customer_menu_screen.dart';

/// Visões administrativas dedicadas (porte das rotas /mesas, /reservas, /produtos, /pedidos, /funcionarios).
class AdminSectionsScreen extends StatefulWidget {
  const AdminSectionsScreen({super.key});

  @override
  State<AdminSectionsScreen> createState() => _AdminSectionsScreenState();
}

class _AdminSectionsScreenState extends State<AdminSectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();

    return Column(
      children: [
        Container(
          color: AppColors.panel,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primaryButtonBg,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Mesas (${provider.tables.length})'),
              Tab(text: 'Reservas (${provider.reservations.length})'),
              Tab(text: 'Produtos (${provider.products.length})'),
              Tab(text: 'Pedidos (${provider.orders.length})'),
              Tab(text: 'Funcionários (${provider.staff.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTablesTab(context, provider),
              _buildReservationsTab(context, provider),
              _buildProductsTab(context, provider),
              _buildOrdersTab(context, provider),
              _buildStaffTab(context, provider),
            ],
          ),
        ),
      ],
    );
  }

  double _responsiveCardWidth(double maxWidth) {
    if (maxWidth >= 960) return (maxWidth - 24) / 3;
    if (maxWidth >= 560) return (maxWidth - 12) / 2;
    return maxWidth;
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? buttonLabel,
    AdminModalType? modalType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (buttonLabel != null && modalType != null)
            ElevatedButton.icon(
              onPressed: () => showAdminCreateModal(context, modalType),
              icon: const Icon(Icons.add, size: 16),
              label: Text(buttonLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildTablesTab(BuildContext context, RestaurantProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Gestão de Mesas do Salão',
          buttonLabel: 'Nova mesa',
          modalType: AdminModalType.table,
        ),
        LayoutBuilder(
          builder: (_, constraints) {
            final cardWidth = _responsiveCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: provider.tables.map((t) {
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(16),
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
                                'Mesa ${Formatters.formatTableNumber(t.number)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${t.capacity} lugares',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            TableStatusBadge(status: t.status),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CustomerMenuScreen(
                                      initialTableNumber: t.number,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'QR Cardápio →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReservationsTab(
    BuildContext context,
    RestaurantProvider provider,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Controle de Reservas',
          buttonLabel: 'Nova reserva',
          modalType: AdminModalType.reservation,
        ),
        ...provider.reservations.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.formatShortDate(r.dateTime)} às ${Formatters.formatTimeHHMM(r.dateTime)} · ${r.guestCount} convidados · Tel: ${r.customerPhone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigoBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.indigoBorder),
                  ),
                  child: Text(
                    r.table != null
                        ? 'Mesa ${Formatters.formatTableNumber(r.table!.number)}'
                        : (r.tableId != null
                            ? 'Mesa ${Formatters.formatTableNumber(r.tableId!)}'
                            : 'Salão'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.indigoText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTab(BuildContext context, RestaurantProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Catálogo de Produtos do Cardápio',
          buttonLabel: 'Novo produto',
          modalType: AdminModalType.product,
        ),
        LayoutBuilder(
          builder: (_, constraints) {
            final cardWidth = _responsiveCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: provider.products.map((p) {
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.category,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Excluir produto',
                              onPressed: () async {
                                try {
                                  await provider.deleteProduct(p.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Produto "${p.name}" excluído.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (p.description != null &&
                            p.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          Formatters.formatCurrency(p.price),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrdersTab(BuildContext context, RestaurantProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Histórico e Comandas Abertas',
        ),
        ...provider.orders.map((o) {
          final isOpen = o.status == OrderStatus.open;
          final itemsSummary = o.orderItems.isEmpty
              ? 'Sem itens'
              : o.orderItems
                  .map((i) =>
                      '${i.quantity}x ${i.product?.name ?? 'Item #${i.productId}'}')
                  .join(' · ');

          final isCompact = MediaQuery.of(context).size.width < 480;
          final orderSummary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Mesa ${Formatters.formatTableNumber(o.table?.number ?? o.tableId)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatters.formatOrderDisplayNumber(o.id),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.amberBg : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isOpen ? 'ABERTO' : 'FECHADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isOpen ? AppColors.amberText : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                itemsSummary,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          final closeAction = ElevatedButton(
            onPressed: provider.busy
                ? null
                : () async {
                    await provider.closeOrder(o.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Comanda ${Formatters.formatOrderDisplayNumber(o.id)} fechada!',
                          ),
                        ),
                      );
                    }
                  },
            child: const Text('Fechar conta'),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      orderSummary,
                      const Divider(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total (+10%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(
                                  o.totalWithServiceFee,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          if (isOpen) closeAction,
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: orderSummary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total (+10%)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(o.totalWithServiceFee),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isOpen) ...[
                            const SizedBox(height: 8),
                            closeAction,
                          ],
                        ],
                      ),
                    ],
                  ),
          );
        }),
      ],
    );
  }

  Widget _buildStaffTab(BuildContext context, RestaurantProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Equipe e Funcionários',
          buttonLabel: 'Cadastrar',
          modalType: AdminModalType.staff,
        ),
        LayoutBuilder(
          builder: (_, constraints) {
            final cardWidth = _responsiveCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: provider.staff.map((u) {
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u.email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
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
                            color: AppColors.cardElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            u.role.value,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
