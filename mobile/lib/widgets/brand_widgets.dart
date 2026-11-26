import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BrandLogoBadge extends StatelessWidget {
  final double size;
  final double iconSize;

  const BrandLogoBadge({
    super.key,
    this.size = 40,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryButtonBg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.restaurant,
        color: AppColors.primaryButtonFg,
        size: iconSize,
      ),
    );
  }
}

class TableStatusBadge extends StatelessWidget {
  final TableStatus status;

  const TableStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case TableStatus.available:
        bg = AppColors.emeraldBg;
        border = AppColors.emeraldBorder;
        text = AppColors.emeraldText;
        break;
      case TableStatus.occupied:
        bg = AppColors.amberBg;
        border = AppColors.amberBorder;
        text = AppColors.amberText;
        break;
      case TableStatus.reserved:
        bg = AppColors.indigoBg;
        border = AppColors.indigoBorder;
        text = AppColors.indigoText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        status.ptLabel,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class ConnectionStatusPill extends StatelessWidget {
  final VoidCallback? onTap;

  const ConnectionStatusPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final online = provider.isBackendOnline;
    final compact = MediaQuery.of(context).size.width < 400;

    return InkWell(
      onTap: onTap ?? () => showApiSettingsDialog(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: online ? AppColors.emeraldBg : AppColors.redBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: online ? AppColors.emeraldBorder : AppColors.redBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: online ? AppColors.emeraldText : AppColors.redText,
                shape: BoxShape.circle,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                online ? 'API Online' : 'API Offline',
                style: TextStyle(
                  color: online ? AppColors.emeraldText : AppColors.redText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.settings,
              size: 13,
              color: online ? AppColors.emeraldText : AppColors.redText,
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: Text(
                  '−',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showApiSettingsDialog(BuildContext context) async {
  final provider = context.read<RestaurantProvider>();
  final controller = TextEditingController(text: provider.apiBaseUrl);

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text(
          'Configurar Servidor da API',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe a URL do Back-end NestJS compartilhado com o Front-end Next.js:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL Base da API',
                  hintText: 'http://localhost:3000/api',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Localhost (Web/Desktop)', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'http://localhost:3000/api',
                  ),
                  ActionChip(
                    label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'http://10.0.2.2:3000/api',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.resetApiBaseUrl();
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: const Text('Padrão', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateApiBaseUrl(controller.text);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: const Text('Salvar e reconectar'),
          ),
        ],
      );
    },
  );
  controller.dispose();
}

Future<void> showReceiptPreviewDialog(
  BuildContext context, {
  required Order order,
  required RestaurantTable table,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RESTAURANTE MESA',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mesa ${Formatters.formatTableNumber(table.number)} · Pedido ${Formatters.formatOrderDisplayNumber(order.id)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Divider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.orderItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, idx) {
                    final item = order.orderItems[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.product?.name ?? 'Produto #${item.productId}'}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatCurrency(item.lineTotal),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(),
              const SizedBox(height: 6),
              _ReceiptLine(
                label: 'Subtotal',
                value: Formatters.formatCurrency(order.subtotal),
              ),
              const SizedBox(height: 4),
              _ReceiptLine(
                label: 'Taxa de serviço (10%)',
                value: Formatters.formatCurrency(order.serviceFee),
              ),
              const SizedBox(height: 8),
              _ReceiptLine(
                label: 'TOTAL',
                value: Formatters.formatCurrency(order.totalWithServiceFee),
                bold: true,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar cupom'),
          ),
        ],
      );
    },
  );
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

Future<void> showTransferTableDialog(
  BuildContext context, {
  required Order order,
}) async {
  final provider = context.read<RestaurantProvider>();
  final availableTables = provider.tables
      .where((t) => t.status != TableStatus.occupied && t.id != order.tableId)
      .toList();

  int? selectedTargetId = availableTables.isNotEmpty ? availableTables.first.id : null;
  bool submitting = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(
              'Transferir Comanda ${Formatters.formatOrderDisplayNumber(order.id)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.redBorder),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppColors.redText, fontSize: 12),
                      ),
                    ),
                  if (availableTables.isEmpty)
                    const Text(
                      'Não há mesas disponíveis para transferência no momento.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedTargetId,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      decoration: const InputDecoration(
                        labelText: 'Mesa de destino',
                      ),
                      items: availableTables
                          .map(
                            (t) => DropdownMenuItem<int>(
                              value: t.id,
                              child: Text(
                                'Mesa ${Formatters.formatTableNumber(t.number)} (${t.capacity} lugares)',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedTargetId = val),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
              ),
              if (availableTables.isNotEmpty)
                ElevatedButton(
                  onPressed: submitting || selectedTargetId == null
                      ? null
                      : () async {
                          setState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            await provider.transferOrder(order.id, selectedTargetId!);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Comanda transferida de mesa com sucesso!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              error = e.toString();
                              submitting = false;
                            });
                          }
                        },
                  child: Text(submitting ? 'Transferindo...' : 'Confirmar'),
                ),
            ],
          );
        },
      );
    },
  );
}
