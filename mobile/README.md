# Restaurante Mesa — App Flutter (`/mobile`)

Porte completo em **Flutter** do Sistema de Gerenciamento de Restaurante & Cardápio Digital, integrado em tempo real com o **Back-end NestJS (`http://localhost:3000/api`)** e com o **Front-end Web Next.js (`http://localhost:3001`)**.

## Funcionalidades Portadas

- **Área Pública**
  - **Login & Cadastro da Equipe** com atalho rápido para credenciais do Seed (`admin@restaurant.com` / `waiter@restaurant.com`, senha `admin123`)
  - **Cardápio Digital de Autoatendimento**: seleção de mesa, nome do cliente, busca, filtro por categorias, observações por item, sacola persistida em `SharedPreferences`, envio via `POST /api/public/orders` e acompanhamento da **Conta da Mesa** (+10% de serviço)
- **Área Administrativa (Protegida por JWT)**
  - **Atendimento (PDV)**: visualização de mesas (`TODAS`, `DISPONÍVEIS`, `OCUPADAS`, `RESERVADAS`), próximas reservas, catálogo de produtos com busca/exclusão, pedido ativo com ajuste de quantidade, remoção, observações, fechamento de conta, prévia de cupom e transferência de mesa
  - **Gestão Completa**: abas dedicadas para Mesas (com atalho para o Cardápio da Mesa), Reservas, Produtos, Pedidos e Funcionários
  - **Modais de Cadastro**: `+ Nova mesa`, `+ Novo produto`, `+ Nova reserva`, `+ Cadastrar funcionário`
  - **Configuração de Servidor da API**: botão `API Online / Offline` no topo permite alterar a URL da API em tempo real (ideal para Emulador Android `10.0.2.2:3000/api` ou celular físico na rede Wi-Fi)

## Como Preparar e Rodar

> Certifique-se de ter o **Flutter SDK** instalado (`flutter --version`).

```powershell
cd mobile

# 1. Gerar os arquivos nativos de plataforma (Web, Android, Windows, iOS) preservando lib/ e pubspec.yaml
flutter create . --platforms=web,android,windows

# 2. Baixar as dependências do pubspec.yaml
flutter pub get

# 3. Rodar os testes unitários e de widget
flutter test

# 4. Executar no navegador Edge (funciona direto no Windows sem precisar de Android Studio!)
flutter run -d edge --web-port=3002

# OU executar no Emulador Android (usa automaticamente http://10.0.2.2:3000/api)
flutter run -d android

# OU executar em celular físico na mesma rede Wi-Fi (substitua pelo IP da sua máquina)
flutter run --dart-define=API_URL=http://192.168.0.10:3000/api
```

### Permissão de HTTP local no Android (após `flutter create .`)
Se rodar no Android (emulador ou aparelho físico), garanta no arquivo `mobile/android/app/src/main/AndroidManifest.xml`:
1. `<uses-permission android:name="android.permission.INTERNET" />` dentro de `<manifest>`
2. `android:usesCleartextTraffic="true"` dentro da tag `<application ...>`
