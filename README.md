# SmartCart

MVP de carrinho inteligente para supermercado. O cliente usa o celular para vincular um carrinho por QR Code, escanear produtos, acompanhar total e peso esperado, finalizar a compra, simular validacao por balanca e receber um QR Code/token de saida quando aprovado.

## Arquitetura

- `mobile/`: aplicativo Flutter Android com Material 3.
- `backend/`: API REST em Node.js, TypeScript e Express.
- `database/`: schema Prisma e seed do banco.
- `docker-compose.yml`: PostgreSQL real para desenvolvimento local.

## Backend

```bash
cd backend
copy .env.example .env
npm install
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
npm run dev
```

## Deploy no Render

1. Suba este projeto para um repositorio GitHub.
2. No Render, escolha **New +** > **Blueprint**.
3. Conecte o repositorio do SmartCart.
4. Confirme o arquivo `render.yaml`.
5. Aguarde o Render criar:
   - `smartcart-backend`
   - `smartcart-postgres`

Depois do deploy, copie a URL do backend e gere/rode o app Flutter apontando para ela:

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=https://SUA-URL-DO-RENDER
```

Antes das migrations, suba o PostgreSQL:

```bash
docker compose up -d postgres
```

Usuario demo criado pelo seed:

- Email: `demo@smartcart.local`
- Senha: `123456`

## Flutter Android

O app usa `http://10.0.2.2:3333` por padrao, que aponta para o backend local quando roda no emulador Android.

```bash
cd mobile
flutter pub get
flutter run
```

Para usar outro backend:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP:3333
```

## Endpoints principais

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `GET /products`
- `GET /products/barcode/:barcode`
- `POST /carts/link`
- `GET /sessions/current`
- `GET /sessions/history`
- `POST /sessions/:id/items`
- `PATCH /sessions/:id/items/:itemId`
- `DELETE /sessions/:id/items/:itemId`
- `POST /sessions/:id/finish`
- `GET /validations/pending`
- `POST /validations/:sessionId`
- `GET /payment-tokens/:sessionId`
- `POST /exit/validate`

## Testes e verificacoes

Backend:

```bash
cd backend
npm run build
npm test
```

Mobile:

```bash
cd mobile
flutter analyze
flutter test
flutter build apk --debug
```

## Banco de dados

O schema Prisma modela:

- `User`
- `Product`
- `Cart`
- `ShoppingSession`
- `ShoppingItem`
- `Validation`
- `PaymentToken`

O seed cria 30 produtos ficticios, 5 carrinhos `CART-000001` a `CART-000005` e um usuario demo.

## Limitacoes do MVP

- Nao ha pagamento real por cartao, Pix ou gateway.
- A balanca e simulada pela tela "Estacao de Validacao".
- O endpoint administrativo de validacao ainda usa JWT comum; em producao deve haver perfil/permissao de funcionario.
- O token cru de saida e exibido somente no momento da aprovacao; o banco armazena apenas hash.

## Roadmap

- Separar perfis de cliente e funcionario.
- Criar painel web/admin para validacao e cadastro de produtos.
- Integrar balanca fisica via ESP32, Raspberry Pi ou outro dispositivo IoT.
- Expandir testes de API com banco isolado de teste.
- Adicionar pipeline de CI.
