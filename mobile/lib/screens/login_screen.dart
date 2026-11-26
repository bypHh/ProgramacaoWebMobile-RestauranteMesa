import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_widgets.dart';
import 'customer_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isRegisterMode = false;
  UserRole _role = UserRole.waiter;
  bool _showSeedHelper = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _fillCredentials(String email, String password) {
    setState(() {
      _isRegisterMode = false;
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
      _error = null;
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'A senha deve conter pelo menos 6 caracteres.');
      return;
    }
    if (_isRegisterMode && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome completo.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final provider = context.read<RestaurantProvider>();
    try {
      if (_isRegisterMode) {
        await provider.registerAndLogin(
          name: _nameCtrl.text.trim(),
          email: email,
          password: password,
          role: _role,
        );
      } else {
        await provider.login(email, password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: compact ? 10 : 16,
        title: const Row(
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.emeraldText),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Restaurante Mesa',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          const Center(child: ConnectionStatusPill()),
          const SizedBox(width: 6),
          if (compact)
            IconButton(
              tooltip: 'Abrir Cardápio Digital',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomerMenuScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu, size: 20),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerMenuScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu, size: 15),
                label: const Text('Cardápio'),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogoBadge(size: 52, iconSize: 28)),
                  const SizedBox(height: 18),
                  Text(
                    _isRegisterMode ? 'Criar conta' : 'Bem-vindo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? 'Cadastre um novo membro da equipe no sistema'
                        : 'Acesse o sistema de gestão do seu restaurante',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.redBorder),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.redText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_isRegisterMode) ...[
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        hintText: 'Ex: Maria Recepcionista',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seu@email.com',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (!_isRegisterMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(
                          () => _showSeedHelper = !_showSeedHelper,
                        ),
                        child: const Text(
                          'Credenciais padrão (Seed)?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<UserRole>(
                      initialValue: _role,
                      dropdownColor: AppColors.card,
                      decoration: const InputDecoration(
                        labelText: 'Cargo na equipe',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text('ADMIN (Administrador)'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.manager,
                          child: Text('MANAGER (Gerente)'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.waiter,
                          child: Text('WAITER (Garçom)'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.receptionist,
                          child: Text('RECEPTIONIST (Recepcionista)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _role = v);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_showSeedHelper && !_isRegisterMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credenciais padrão do Seed (senha: admin123):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _fillCredentials(
                                  'admin@restaurant.com',
                                  'admin123',
                                ),
                                child: const Text('Usar Admin'),
                              ),
                              OutlinedButton(
                                onPressed: () => _fillCredentials(
                                  'waiter@restaurant.com',
                                  'admin123',
                                ),
                                child: const Text('Usar Garçom'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    child: Text(
                      _submitting
                          ? 'Autenticando...'
                          : (_isRegisterMode ? 'Cadastrar e Entrar' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode
                            ? 'Já possui uma conta?'
                            : 'Não tem uma conta?',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _error = null;
                          });
                        },
                        child: Text(
                          _isRegisterMode ? 'Fazer login' : 'Cadastre-se',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Text(
                        'É cliente na mesa?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CustomerMenuScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Abrir Cardápio Digital →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}
