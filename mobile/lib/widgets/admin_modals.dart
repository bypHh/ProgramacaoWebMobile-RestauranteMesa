import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum AdminModalType { table, product, reservation, staff }

Future<void> showAdminCreateModal(
  BuildContext context,
  AdminModalType type,
) async {
  final provider = context.read<RestaurantProvider>();
  final nextTableNum = provider.tables.isEmpty
      ? 1
      : provider.tables.map((t) => t.number).reduce((a, b) => a > b ? a : b) + 1;

  // Controllers
  final tableNumberCtrl = TextEditingController(text: '$nextTableNum');
  final tableCapacityCtrl = TextEditingController(text: '4');

  final prodNameCtrl = TextEditingController();
  final prodPriceCtrl = TextEditingController();
  final prodDescCtrl = TextEditingController();
  String prodCategory = 'Prato principal';

  final resNameCtrl = TextEditingController();
  final resPhoneCtrl = TextEditingController();
  final resGuestsCtrl = TextEditingController(text: '2');
  DateTime resDateTime = DateTime.now().add(const Duration(hours: 2));
  int? resTableId;

  final staffNameCtrl = TextEditingController();
  final staffEmailCtrl = TextEditingController();
  final staffPassCtrl = TextEditingController();
  UserRole staffRole = UserRole.waiter;

  bool submitting = false;
  String? error;

  final title = switch (type) {
    AdminModalType.table => 'Cadastrar Nova Mesa',
    AdminModalType.product => 'Cadastrar Novo Produto',
    AdminModalType.reservation => 'Registrar Nova Reserva',
    AdminModalType.staff => 'Cadastrar Funcionário',
  };

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (dialogCtx, setState) {
          Future<void> submit() async {
            setState(() {
              submitting = true;
              error = null;
            });

            try {
              String successMessage;
              switch (type) {
                case AdminModalType.table:
                  final num = int.tryParse(tableNumberCtrl.text.trim());
                  final cap = int.tryParse(tableCapacityCtrl.text.trim());
                  if (num == null || num <= 0 || cap == null || cap <= 0) {
                    throw Exception('Informe número e capacidade válidos.');
                  }
                  final created = await provider.createTable(
                    number: num,
                    capacity: cap,
                  );
                  successMessage =
                      'Mesa ${Formatters.formatTableNumber(created.number)} (${created.capacity} lugares) criada!';
                  break;

                case AdminModalType.product:
                  final price = double.tryParse(
                    prodPriceCtrl.text.trim().replaceAll(',', '.'),
                  );
                  if (prodNameCtrl.text.trim().isEmpty ||
                      price == null ||
                      price < 0) {
                    throw Exception('Informe um nome e preço válidos.');
                  }
                  final created = await provider.createProduct(
                    name: prodNameCtrl.text.trim(),
                    description: prodDescCtrl.text.trim(),
                    price: price,
                    category: prodCategory,
                  );
                  successMessage =
                      'Produto "${created.name}" adicionado ao catálogo!';
                  break;

                case AdminModalType.reservation:
                  final guests = int.tryParse(resGuestsCtrl.text.trim());
                  if (resNameCtrl.text.trim().isEmpty ||
                      resPhoneCtrl.text.trim().isEmpty ||
                      guests == null ||
                      guests <= 0) {
                    throw Exception('Preencha nome, telefone e convidados.');
                  }
                  final created = await provider.createReservation(
                    customerName: resNameCtrl.text.trim(),
                    customerPhone: resPhoneCtrl.text.trim(),
                    dateTimeIso: resDateTime.toUtc().toIso8601String(),
                    guestCount: guests,
                    tableId: resTableId,
                  );
                  successMessage =
                      'Reserva confirmada para ${created.customerName}!';
                  break;

                case AdminModalType.staff:
                  if (staffNameCtrl.text.trim().isEmpty ||
                      staffEmailCtrl.text.trim().isEmpty ||
                      staffPassCtrl.text.length < 6) {
                    throw Exception(
                      'Preencha nome, e-mail válido e senha (mín. 6 caracteres).',
                    );
                  }
                  final created = await provider.registerStaff(
                    name: staffNameCtrl.text.trim(),
                    email: staffEmailCtrl.text.trim(),
                    password: staffPassCtrl.text,
                    role: staffRole,
                  );
                  successMessage =
                      'Funcionário ${created.name} (${created.role.value}) cadastrado!';
                  break;
              }

              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successMessage)),
                );
              }
            } catch (e) {
              setState(() {
                error = e.toString().replaceFirst('Exception: ', '');
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogCtx).pop(),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.redBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.redBorder),
                        ),
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: AppColors.redText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (type == AdminModalType.table) ...[
                      TextField(
                        controller: tableNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número da Mesa',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tableCapacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Capacidade (lugares)',
                        ),
                      ),
                    ],
                    if (type == AdminModalType.product) ...[
                      TextField(
                        controller: prodNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome do produto',
                          hintText: 'Ex: Filé à Parmegiana',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: prodPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Preço (R\$)',
                                hintText: '68.00',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: prodCategory,
                              isExpanded: true,
                              dropdownColor: AppColors.card,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Prato principal',
                                  child: Text('Prato principal'),
                                ),
                                DropdownMenuItem(
                                  value: 'Entrada',
                                  child: Text('Entrada'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bebida',
                                  child: Text('Bebida'),
                                ),
                                DropdownMenuItem(
                                  value: 'Sobremesa',
                                  child: Text('Sobremesa'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => prodCategory = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: prodDescCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (exibida no Cardápio)',
                          hintText: 'Ingredientes e modo de preparo...',
                        ),
                      ),
                    ],
                    if (type == AdminModalType.reservation) ...[
                      TextField(
                        controller: resNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome do cliente',
                          hintText: 'Ex: Ana Martins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: resPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                hintText: '(54) 99988-7766',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: resGuestsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Convidados',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogCtx,
                            initialDate: resDateTime,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate == null || !dialogCtx.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: dialogCtx,
                            initialTime: TimeOfDay.fromDateTime(resDateTime),
                          );
                          if (pickedTime == null) return;
                          setState(() {
                            resDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: Text(
                          'Data/Hora: ${Formatters.formatShortDate(resDateTime.toIso8601String())} às ${Formatters.formatTimeHHMM(resDateTime.toIso8601String())}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: resTableId,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        decoration: const InputDecoration(
                          labelText: 'Mesa (opcional)',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sem mesa fixa'),
                          ),
                          ...provider.tables.map(
                            (t) => DropdownMenuItem<int?>(
                              value: t.id,
                              child: Text(
                                'Mesa ${Formatters.formatTableNumber(t.number)} (${t.capacity} lug.)',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => resTableId = v),
                      ),
                    ],
                    if (type == AdminModalType.staff) ...[
                      TextField(
                        controller: staffNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          hintText: 'Ex: Carlos Garçom',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: staffEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail corporativo',
                          hintText: 'carlos@restaurant.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: staffPassCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Senha (mín. 6)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<UserRole>(
                              initialValue: staffRole,
                              isExpanded: true,
                              dropdownColor: AppColors.card,
                              decoration: const InputDecoration(
                                labelText: 'Cargo',
                              ),
                              items: UserRole.values
                                  .map(
                                    (r) => DropdownMenuItem<UserRole>(
                                      value: r,
                                      child: Text(r.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => staffRole = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                child: Text(submitting ? 'Salvando...' : 'Salvar registro'),
              ),
            ],
          );
        },
      );
    },
  );

  tableNumberCtrl.dispose();
  tableCapacityCtrl.dispose();
  prodNameCtrl.dispose();
  prodPriceCtrl.dispose();
  prodDescCtrl.dispose();
  resNameCtrl.dispose();
  resPhoneCtrl.dispose();
  resGuestsCtrl.dispose();
  staffNameCtrl.dispose();
  staffEmailCtrl.dispose();
  staffPassCtrl.dispose();
}
