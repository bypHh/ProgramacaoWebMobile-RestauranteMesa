# Sistema de Gerenciamento de Restaurante & Cardápio Digital — UPF (Web & Mobile)

> **Desenvolvido por:** **Pedro Henrique Carniel** e **João Bortoluz**  
> **Disciplina:** Programação Web e Mobile — Universidade de Passo Fundo (UPF)

Este projeto **Full-Stack Web & Mobile** integra o gerenciamento completo das rotinas de atendimento de um restaurante (**Restaurante Mesa**) com um **Cardápio Digital de Autoatendimento** para os clientes fazerem pedidos diretamente das mesas. As três aplicações compartilham a mesma **API REST NestJS** e o mesmo banco de dados **SQLite**, sincronizando alterações em tempo real entre o navegador e o app mobile.

- **Back-end (`/` raiz)**: API REST em **TypeScript** com **NestJS**, **Prisma ORM**, banco **SQLite**, autenticação **JWT** e documentação **Swagger**.
- **Front-end Web (`/frontend`)**: Aplicação Web em **Next.js (App Router)**, **React**, **TypeScript** e **Tailwind CSS**.
- **App Mobile / Multiplataforma (`/mobile`)**: Aplicativo em **Flutter (Dart)** com **Provider**, **http** e **SharedPreferences**, responsivo para **Android, Web e Desktop**.

---

## 📂 Visão Geral da Estrutura do Repositório

```text
web_UPF_2026-02_mobile-main/
├── src/                      # Código-fonte do Back-end NestJS (API REST)
├── prisma/                   # Schema Prisma, migrações SQLite e script de Seed
├── test/                     # Testes E2E (ponta a ponta) do Back-end
├── frontend/                 # Aplicação Front-end Web (Next.js App Router)
├── mobile/                   # Aplicativo Mobile / Multiplataforma (Flutter)
├── .env.example              # Modelo de variáveis de ambiente do Back-end
├── package.json              # Dependências e scripts do Back-end
├── prisma.config.ts          # Configuração do Prisma CLI e seed
├── restaurant.http           # Coleção de requisições HTTP (REST Client VS Code)
└── README.md                 # Documentação principal do projeto
```

---

## ⚙️ 1. Back-end (`/` raiz — NestJS + Prisma + SQLite)

O back-end centraliza todas as regras de negócio, autenticação e persistência de dados em SQLite (`dev.db`). Ele expõe rotas sob o prefixo global `/api`, valida payloads com `class-validator` (`ValidationPipe`), habilita **CORS** e escuta em `0.0.0.0:3000` para aceitar conexões simultâneas do Front-end Web (`localhost:3001`), do Flutter Web (`localhost:3002`), do Emulador Android (`10.0.2.2:3000`) e de celulares físicos na mesma rede Wi-Fi.

### Estrutura de Pastas do Back-end

```text
├── prisma/
│   ├── schema.prisma                         # Modelos User, Table, Reservation, Product, Order, OrderItem
│   ├── seed.ts                               # Seed inicial (2 funcionários, 6 mesas, 6 produtos, reservas e comandas)
│   └── migrations/                           # Histórico de migrações SQLite
├── src/
│   ├── main.ts                               # Bootstrap NestJS, prefixo /api, CORS, ValidationPipe, Swagger e porta 3000
│   ├── app.module.ts                         # Módulo raiz que integra todos os submódulos e ConfigModule
│   ├── auth/                                 # Login JWT, cadastro/listagem de funcionários e JwtAuthGuard global
│   ├── database/                             # PrismaModule e PrismaService (adaptador better-sqlite3)
│   ├── dtos/                                 # DTOs validados com class-validator e documentados com Swagger
│   ├── tables/                               # CRUD de mesas e testes unitários (tables.service.spec.ts)
│   ├── products/                             # CRUD do cardápio de produtos
│   ├── reservations/                         # Criação e listagem de reservas (atualiza mesa para RESERVED)
│   ├── orders/                               # Comandas admin (/api/orders) + autoatendimento público (/api/public)
│   └── generated/prisma/                     # Prisma Client gerado automaticamente
└── test/
    └── app.e2e-spec.ts                       # Testes E2E de autenticação e proteção de rotas
```

### Autenticação e Credenciais Padrão (Seed)
- Um **Guard Global** (`JwtAuthGuard`) exige token `Bearer <JWT>` em todas as rotas administrativas.
- As rotas `POST /api/auth/login` e `/api/public/*` (Cardápio Digital do Cliente) são públicas.
- Usuários criados automaticamente por `npm run seed`:
  - **Administrador**: `admin@restaurant.com` | Senha: `admin123`
  - **Garçom**: `waiter@restaurant.com` | Senha: `admin123`

### Endpoints da API

| Módulo | Método | Rota | Descrição |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/auth/login` | Autentica funcionário e retorna o token JWT + dados do usuário |
| | `POST` | `/api/auth/register` | Cadastra novo funcionário (`ADMIN`, `MANAGER`, `WAITER`, `RECEPTIONIST`) |
| | `GET` | `/api/auth/staff` | Lista todos os funcionários cadastrados |
| **Mesas** | `POST` | `/api/tables` | Cadastra uma nova mesa (`number`, `capacity`) |
| | `GET` | `/api/tables` | Lista todas as mesas e status (`AVAILABLE`, `OCCUPIED`, `RESERVED`) |
| | `GET` | `/api/tables/:id` | Retorna os detalhes de uma mesa |
| **Produtos** | `POST` | `/api/products` | Cadastra um produto no cardápio |
| | `GET` | `/api/products` | Lista todos os produtos ordenados por categoria |
| | `GET` | `/api/products/:id` | Busca um produto pelo ID |
| | `DELETE` | `/api/products/:id` | Remove um produto do cardápio |
| **Reservas** | `POST` | `/api/reservations` | Cria uma reserva e marca a mesa vinculada como `RESERVED` |
| | `GET` | `/api/reservations` | Lista todas as reservas com os dados da mesa |
| | `GET` | `/api/reservations/:id` | Detalha uma reserva pelo ID |
| **Comandas** | `POST` | `/api/orders` | Abre uma comanda para a mesa (altera mesa para `OCCUPIED`) |
| | `POST` | `/api/orders/:id/items` | Adiciona produto ao pedido aberto e soma no total |
| | `PATCH` | `/api/orders/:id/items/:itemId` | Atualiza quantidade de um item e recalcula o total |
| | `DELETE` | `/api/orders/:id/items/:itemId` | Remove um item da comanda aberta e recalcula o total |
| | `PATCH` | `/api/orders/:id/transfer` | Transfere a comanda aberta para outra mesa disponível |
| | `GET` | `/api/orders` | Lista todas as comandas (mesa, garçom e itens) |
| | `GET` | `/api/orders/:id` | Detalha uma comanda completa |
| | `PATCH` | `/api/orders/:id/close` | Fecha a comanda e libera a mesa para `AVAILABLE` |
| **Cardápio Público** | `GET` | `/api/public/menu` | Retorna produtos, mesas e comandas abertas para autoatendimento |
| | `GET` | `/api/public/tables/:tableId/order` | Consulta a comanda aberta de uma mesa específica |
| | `POST` | `/api/public/orders` | Envia pedido do cliente direto para a comanda da mesa (abre comanda se necessário) |

---

## 🖥️ 2. Front-end Web (`/frontend` — Next.js App Router + React)

A aplicação web foi construída com **Next.js 15 (App Router)**, **React 19**, **TypeScript** e **Tailwind CSS**, utilizando:
- **Server Components** para layouts, páginas e leitura de cookies de sessão no servidor (`next/headers`).
- **Client Components (`'use client'`)** para interatividade do PDV (busca rápida `Ctrl+K` / `⌘K`, filtros dinâmicos, modais de cadastro, sacola persistida no `localStorage` e sincronização entre abas via `BroadcastChannel` + polling periódico).
- **Proteção de Rotas (`middleware.ts`)**: exige cookie `restaurant_token` para todas as rotas do grupo `(admin)` e mantém liberadas as rotas públicas (`/login`, `/cardapio`, `/cardapio/[mesa]`).
- **Herança de Layouts por Pastas**: `(public)/layout.tsx` fornece a barra de navegação pública; `(admin)/layout.tsx` mantém fixos o cabeçalho administrativo, modais globais (`+ Nova mesa`, `+ Novo produto`, `+ Nova reserva`, `+ Cadastrar funcionário`) e rodapé.

### Estrutura de Pastas do Front-end

```text
frontend/
├── next.config.mjs                           # Configuração do Next.js
├── package.json                              # Dependências e scripts (roda na porta 3001)
├── tailwind.config.ts                        # Configuração do Tailwind CSS
└── src/
    ├── middleware.ts                         # Proteção de rotas Admin vs Área Pública via Cookies
    ├── types/restaurant.ts                   # Interfaces TypeScript compartilhadas (Table, Product, Order, etc.)
    ├── lib/
    │   ├── api.ts                            # Cliente HTTP para o Back-end NestJS + sincronização BroadcastChannel
    │   ├── auth-cookies.ts                   # Gerenciamento de cookies seguros e localStorage
    │   └── format.ts                         # Formatação BRL (R$), horários e códigos de comanda/mesa
    ├── components/
    │   ├── public/
    │   │   ├── LoginFormClient.tsx           # Tela de Login e Cadastro da equipe com atalhos do Seed
    │   │   └── CustomerMenuClient.tsx        # Cardápio Digital do Cliente (Catálogo, Sacola e Conta da Mesa)
    │   └── admin/
    │       ├── AdminHeader.tsx               # Barra superior de gestão, botões de criação rápida e Logout
    │       ├── AdminModals.tsx               # Modais globais (Mesa, Produto, Reserva e Funcionário)
    │       ├── AdminFooter.tsx               # Rodapé administrativo
    │       ├── PosDashboardClient.tsx        # PDV principal de 3 colunas (Mesas, Catálogo e Pedido Ativo)
    │       └── AdminSectionClient.tsx        # Visões dedicadas para Mesas, Reservas, Produtos, Pedidos e Equipe
    └── app/
        ├── layout.tsx                        # Layout raiz global (tema escuro #09090b)
        ├── page.tsx                          # Redirecionamento inicial (/atendimento ou /login)
        ├── api/auth/
        │   ├── session/route.ts              # Route Handler: salva/lê cookies de sessão
        │   └── logout/route.ts               # Route Handler: encerra sessão
        ├── (public)/                         # Grupo de rotas públicas
        │   ├── layout.tsx
        │   ├── login/page.tsx                # /login
        │   └── cardapio/
        │       ├── page.tsx                  # /cardapio
        │       └── [mesa]/page.tsx           # /cardapio/[mesa] (link direto QR Code por mesa)
        └── (admin)/                          # Grupo de rotas protegidas
            ├── layout.tsx
            ├── atendimento/page.tsx          # /atendimento
            ├── mesas/page.tsx                # /mesas
            ├── reservas/page.tsx             # /reservas
            ├── produtos/page.tsx             # /produtos
            ├── pedidos/page.tsx              # /pedidos
            └── funcionarios/page.tsx         # /funcionarios
```

---

## 📱 3. Aplicativo Mobile / Multiplataforma (`/mobile` — Flutter + Dart)

A parte mobile é o porte completo em **Flutter** da interface e de todos os fluxos do sistema **Restaurante Mesa**, consumindo exatamente os mesmos endpoints do **Back-end NestJS** e sincronizando automaticamente a cada **5 segundos** com o Front-end Web:

- **Gerenciamento de Estado (`Provider`)**: `RestaurantProvider` centraliza autenticação JWT, carregamento do PDV/Cardápio, sacola do cliente, polling automático e persistência local com `SharedPreferences` (token, usuário logado, sacola, mesa selecionada, nome do cliente e URL da API).
- **Configuração Inteligente da API (`ApiConfig`)**:
  - **Web / Windows / iOS Simulator**: usa `http://localhost:3000/api` automaticamente.
  - **Emulador Android**: usa `http://10.0.2.2:3000/api` automaticamente.
  - **Celular físico na rede Wi-Fi**: aceita `--dart-define=API_URL=http://SEU_IP:3000/api` ou troca em tempo real pelo botão **`● API Online / Offline`** no topo do app.
- **Layout 100% Responsivo**: adapta-se automaticamente de celulares compactos (`320px`) até tablets (`768px`/`960px`) e desktops (`1280px+`), usando barra de navegação inferior e abas no celular e layout em colunas no tablet/desktop.
- **Permissões Android**: `AndroidManifest.xml` já configurado com `INTERNET` e `usesCleartextTraffic="true"` para comunicação HTTP local com o back-end.

### Estrutura de Pastas do Mobile (Flutter)

```text
mobile/
├── pubspec.yaml                              # Dependências Flutter (http, provider, shared_preferences, cupertino_icons)
├── analysis_options.yaml                     # Regras de lint Dart/Flutter
├── android/                                  # Projeto nativo Android (inclui AndroidManifest.xml com permissão HTTP)
├── web/                                      # Runner Flutter Web (index.html, manifest.json e ícones)
├── windows/                                  # Runner Flutter Desktop Windows
├── lib/
│   ├── main.dart                             # Entrypoint, ChangeNotifierProvider e gate de autenticação
│   ├── config/
│   │   └── api_config.dart                   # Resolução automática de URL da API por plataforma + normalização
│   ├── theme/
│   │   └── app_theme.dart                    # Paleta escura "Restaurante Mesa" (#09090b) e estilos Material
│   ├── utils/
│   │   └── formatters.dart                   # Formatação BRL (R$), mesas (01..99), comandas (#1042) e horários
│   ├── models/
│   │   └── restaurant_models.dart            # Enums e modelos (StaffUser, RestaurantTable, Product, Reservation, Order...)
│   ├── services/
│   │   └── api_service.dart                  # Cliente HTTP completo para todas as rotas /api/* do NestJS
│   ├── providers/
│   │   └── restaurant_provider.dart          # Estado global, persistência SharedPreferences e polling de 5s
│   ├── widgets/
│   │   ├── brand_widgets.dart                # Logo, badges de status, seletor de quantidade, config API, cupom e transferência
│   │   └── admin_modals.dart                 # Modais de cadastro (+ Mesa, + Produto, + Reserva, + Funcionário)
│   └── screens/
│       ├── login_screen.dart                 # Login/Cadastro da equipe, atalho Seed e acesso ao Cardápio Digital
│       ├── customer_menu_screen.dart         # Cardápio Digital do Cliente (Catálogo, Sacola e Conta da Mesa)
│       ├── admin_shell_screen.dart           # Shell administrativo (AppBar responsiva, ações rápidas e navegação)
│       ├── pos_dashboard_screen.dart         # PDV de atendimento (Mesas/Reservas, Catálogo e Pedido Ativo)
│       └── admin_sections_screen.dart        # Abas de Gestão (Mesas + QR, Reservas, Produtos, Pedidos, Funcionários)
└── test/
    ├── formatters_and_models_test.dart       # Testes unitários de formatação, URL da API e cálculos de comanda (+10%)
    └── widget_test.dart                      # Testes de widget e responsividade sem overflow em 5 resoluções
```

---

## 📋 Pré-requisitos

- **Node.js** 18+ e **npm** ([https://nodejs.org](https://nodejs.org) ou `winget install OpenJS.NodeJS.LTS`)
- **Flutter SDK** 3.19+ / **Dart** 3.3+ ([https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows))
- **Navegador Edge ou Chrome** (para testar o Front-end Web e o Flutter Web) e, opcionalmente, **Android Studio / aparelho Android via USB** para rodar o app Flutter no Android.

> **💡 Dica para Windows PowerShell**: Se o terminal do editor não reconhecer `npm` ou `flutter` após a instalação, execute antes:
> ```powershell
> $env:Path += ";C:\Program Files\nodejs;C:\src\flutter\bin"
> ```

---

## 🚀 Como Rodar o Projeto Completo (Back-end + Front-end + Mobile)

Para usar os três projetos integrados, abra **3 terminais** e siga os passos abaixo na ordem:

### Terminal 1 — Back-end NestJS (Porta `3000`)

Na pasta raiz do projeto:

```powershell
# 1. Instalar dependências do back-end
npm.cmd install

# 2. Criar arquivo .env a partir do exemplo (apenas na primeira vez)
Copy-Item .env.example .env

# 3. Aplicar migrações SQLite e gerar o Prisma Client
npx.cmd prisma migrate deploy
npx.cmd prisma generate

# 4. Popular o banco com os dados iniciais (Funcionários, Mesas, Produtos, Reservas e Comandas)
npm.cmd run seed

# 5. Iniciar a API em modo desenvolvimento
npm.cmd run start:dev
```

- **API Back-end**: `http://localhost:3000/api`
- **Documentação Swagger**: `http://localhost:3000/api/docs`

---

### Terminal 2 — Front-end Web Next.js (Porta `3001`)

Com o back-end rodando, abra um **segundo terminal**:

```powershell
cd frontend
npm.cmd install
npm.cmd run dev
```

Telas disponíveis no navegador:
- **Login / Cadastro da Equipe**: `http://localhost:3001/login`
  - Admin: `admin@restaurant.com` | Senha: `admin123`
  - Garçom: `waiter@restaurant.com` | Senha: `admin123`
- **Área de Atendimento (Gestão/PDV)**: `http://localhost:3001/atendimento`
- **Cardápio Digital do Cliente**: `http://localhost:3001/cardapio`
- **Cardápio Digital direto por Mesa (QR Code)**: `http://localhost:3001/cardapio/4`

---

### Terminal 3 — App Mobile Flutter (Porta `3002` no Edge ou Android)

Com o back-end (`3000`) e o front-end (`3001`) rodando, abra um **terceiro terminal**:

```powershell
cd mobile

# 1. Baixar dependências Flutter
flutter pub get

# 2. Rodar no Microsoft Edge (porta 3002 — não conflita com 3000 nem 3001)
flutter run -d edge --web-port=3002

# OU rodar no Emulador Android (conecta automaticamente em http://10.0.2.2:3000/api)
# flutter run -d android

# OU rodar em celular físico na mesma rede Wi-Fi (substitua pelo IP do seu PC)
# flutter run --dart-define=API_URL=http://192.168.0.10:3000/api
```

> **💡 Dica para testar modo celular no navegador**: com o Flutter aberto em `http://localhost:3002`, pressione **`F12`** → **`Ctrl + Shift + M`** (*Emulação de dispositivo*) para visualizar o layout mobile com barra inferior (`Cardápio` · `Sacola` · `Conta`).

---

## 🧪 Como Testar o Projeto

### 1. Teste Integrado em Tempo Real (Web + Mobile + Back-end)
1. No **Front-end Next.js**, acesse `http://localhost:3001/login`, entre como administrador (`admin@restaurant.com` / `admin123`) e selecione a **Mesa 04** em `/atendimento`.
2. No **App Flutter** (`http://localhost:3002` ou Android), verifique se o selo no canto superior direito está verde (**`● API Online`**), clique em **Abrir Cardápio Digital →**, selecione a **Mesa 04**, adicione itens com observação (ex.: *"sem gelo"*) e clique em **Confirmar e Enviar para Mesa 04**.
3. Em até **5 segundos**, o pedido aparece automaticamente no painel **Pedido ativo** da Mesa 04 no Front-end Next.js com subtotal e taxa de 10% recalculados.
4. Faça o fluxo inverso: entre como administrador no **App Flutter**, cadastre um novo produto/mesa/reserva ou feche a conta de uma mesa e confirme a atualização imediata no **Front-end Next.js** e no **Swagger**.

### 2. Testes pelo Swagger ou `restaurant.http`
- **Swagger UI**: acesse `http://localhost:3000/api/docs`, faça login em `POST /api/auth/login`, copie o `access_token` e cole em **Authorize**.
- **REST Client (VS Code)**: abra [restaurant.http](./restaurant.http) e execute as requisições em sequência a partir do login.

### 3. Testes Automatizados, Lint e Build

```powershell
# Back-end (na pasta raiz)
npm.cmd run lint        # Verificação estática (oxlint)
npm.cmd test            # Testes unitários (Vitest)
npm.cmd run test:e2e    # Testes de ponta a ponta (E2E)
npm.cmd run build       # Build de produção NestJS

# Front-end Web (em /frontend)
cd frontend
npm.cmd run build       # Compilação e checagem de tipos Next.js

# App Mobile Flutter (em /mobile)
cd mobile
flutter analyze         # Análise estática Dart/Flutter
flutter test            # Testes unitários, de widget e responsividade (320px a 1280px)
flutter build web       # Build de produção Web do Flutter
```
