import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/admin_modals.dart';
import '../widgets/brand_widgets.dart';
import 'admin_sections_screen.dart';
import 'customer_menu_screen.dart';
import 'pos_dashboard_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0; // 0 = Atendimento (PDV), 1 = Gestão Completa

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final user = provider.currentUser;
    final width = MediaQuery.of(context).size.width;
    final showInlineActions = width >= 1040;
    final showUserInfo = width >= 1280;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BrandLogoBadge(size: 34, iconSize: 19),
            const SizedBox(width: 10),
            Flexible(
              flex: showInlineActions ? 0 : 1,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurante Mesa',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Sistema de gestão',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (showInlineActions) ...[
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            showAdminCreateModal(context, AdminModalType.table),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Nova mesa'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () => showAdminCreateModal(
                          context,
                          AdminModalType.product,
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Novo produto'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () => showAdminCreateModal(
                          context,
                          AdminModalType.reservation,
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Nova reserva'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () =>
                            showAdminCreateModal(context, AdminModalType.staff),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Funcionário'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.emeraldBg,
                          foregroundColor: AppColors.emeraldText,
                          side: const BorderSide(color: AppColors.emeraldBorder),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CustomerMenuScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu, size: 14),
                        label: const Text('Cardápio Cliente'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          const Center(child: ConnectionStatusPill()),
          IconButton(
            tooltip: 'Sincronizar agora',
            onPressed: () => provider.refreshDashboard(),
            icon: const Icon(Icons.refresh, size: 20),
          ),
          if (!showInlineActions)
            PopupMenuButton<String>(
              tooltip: 'Ações rápidas',
              color: AppColors.card,
              icon: const Icon(Icons.add_circle_outline),
              onSelected: (value) {
                switch (value) {
                  case 'table':
                    showAdminCreateModal(context, AdminModalType.table);
                    break;
                  case 'product':
                    showAdminCreateModal(context, AdminModalType.product);
                    break;
                  case 'reservation':
                    showAdminCreateModal(context, AdminModalType.reservation);
                    break;
                  case 'staff':
                    showAdminCreateModal(context, AdminModalType.staff);
                    break;
                  case 'menu':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CustomerMenuScreen(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'table', child: Text('+ Nova mesa')),
                PopupMenuItem(value: 'product', child: Text('+ Novo produto')),
                PopupMenuItem(
                  value: 'reservation',
                  child: Text('+ Nova reserva'),
                ),
                PopupMenuItem(
                  value: 'staff',
                  child: Text('+ Cadastrar funcionário'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'menu',
                  child: Text('Abrir Cardápio Cliente'),
                ),
              ],
            ),
          if (user != null && showUserInfo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.cardElevated,
                    child: Text(
                      Formatters.getInitials(user.name),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          user.role.value,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => provider.logout(),
            icon: const Icon(Icons.logout, size: 19),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          PosDashboardScreen(),
          AdminSectionsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.header,
        indicatorColor: AppColors.cardElevated,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Atendimento (Salão)',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: 'Gestão Completa',
          ),
        ],
      ),
    );
  }
}
