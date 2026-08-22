import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'models/entities.dart';
import 'services/api_client.dart';

void main() => runApp(const SmartCartApp());

final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class AppState extends ChangeNotifier {
  AppState(this.api);

  final ApiClient api;
  AppUser? user;
  ShoppingSession? session;
  String? exitToken;
  bool loading = true;

  Future<void> boot() async {
    try {
      await api.loadToken();
      user = await api.me();
      session = await api.currentSession();
    } catch (_) {
      await api.logout();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    user = await api.login(email, password);
    session = await api.currentSession();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    await api.register(name, email, password);
    await login(email, password);
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
    session = null;
    exitToken = null;
    notifyListeners();
  }

  Future<void> refreshSession() async {
    session = await api.currentSession();
    notifyListeners();
  }

  Future<void> linkCart(String code) async {
    session = await api.linkCart(code);
    notifyListeners();
  }

  Future<Product> findProduct(String barcode) => api.productByBarcode(barcode);

  Future<void> addProduct(Product product, int quantity) async {
    final active = session;
    if (active == null) throw ApiException('Nenhuma compra ativa.');
    session = await api.addItem(active.id, product.id, quantity);
    notifyListeners();
  }

  Future<void> updateItem(ShoppingItem item, int quantity) async {
    final active = session;
    if (active == null) return;
    session = await api.updateItem(active.id, item.id, quantity);
    notifyListeners();
  }

  Future<void> removeItem(ShoppingItem item) async {
    final active = session;
    if (active == null) return;
    session = await api.removeItem(active.id, item.id);
    notifyListeners();
  }

  Future<void> finish() async {
    final active = session;
    if (active == null) return;
    session = await api.finishSession(active.id);
    notifyListeners();
  }

  Future<String?> validate(String sessionId, int measuredWeight) async {
    final result = await api.validateSession(sessionId, measuredWeight);
    exitToken = result['token'];
    session = await api.currentSession();
    notifyListeners();
    return exitToken;
  }
}

class SmartCartApp extends StatefulWidget {
  const SmartCartApp({super.key});

  @override
  State<SmartCartApp> createState() => _SmartCartAppState();
}

class _SmartCartAppState extends State<SmartCartApp> {
  late final AppState state = AppState(ApiClient());

  @override
  void initState() {
    super.initState();
    state.boot();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'SmartCart',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF0F8B6F),
            scaffoldBackgroundColor: const Color(0xFFF6F8F7),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          home: state.loading
              ? const SplashScreen()
              : state.user == null
              ? AuthScreen(state: state)
              : HomeScreen(state: state),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_checkout, size: 72),
            SizedBox(height: 16),
            Text(
              'SmartCart',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Seu carrinho. Seu celular. Sua compra.'),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.state, super.key});
  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController(text: 'demo@smartcart.local');
  final password = TextEditingController(text: '123456');
  final confirm = TextEditingController(text: '123456');
  bool register = false;
  bool busy = false;

  Future<void> submit() async {
    if (register && password.text != confirm.text) {
      showError(context, 'As senhas nao conferem.');
      return;
    }
    setState(() => busy = true);
    try {
      if (register) {
        await widget.state.register(name.text, email.text, password.text);
      } else {
        await widget.state.login(email.text, password.text);
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.local_grocery_store, size: 64),
            const SizedBox(height: 16),
            const Text(
              'SmartCart',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
            const Text('Seu carrinho. Seu celular. Sua compra.'),
            const SizedBox(height: 32),
            if (register)
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            if (register)
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmacao de senha',
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : submit,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(register ? 'Criar conta' : 'Entrar'),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Ja tenho conta' : 'Criar cadastro'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCart'),
        actions: [
          IconButton(
            onPressed: state.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshSession,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Ola, ${state.user!.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            SummaryCard(session: session),
            if (session == null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LinkCartScreen(state: state),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Vincular carrinho'),
              ),
            ] else if (session.status == 'ACTIVE') ...[
              ActionGrid(
                actions: [
                  HomeAction(
                    Icons.document_scanner,
                    'Escanear produto',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductScannerScreen(state: state),
                      ),
                    ),
                  ),
                  HomeAction(
                    Icons.receipt_long,
                    'Minha compra',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(state: state),
                      ),
                    ),
                  ),
                  HomeAction(
                    Icons.history,
                    'Historico',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(state: state),
                      ),
                    ),
                  ),
                  HomeAction(
                    Icons.verified,
                    'Validacao',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ValidationStationScreen(state: state),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ValidationStationScreen(state: state),
                  ),
                ),
                icon: const Icon(Icons.scale),
                label: const Text('Ir para validacao'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.session, super.key});
  final ShoppingSession? session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: session == null
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma compra ativa.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('Vincule um carrinho para comecar.'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${session!.status}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Carrinho: ${session!.cart?.code ?? '-'}'),
                  Text('Itens: ${session!.itemCount}'),
                  Text('Total: ${currency.format(session!.totalAmount)}'),
                  Text('Peso esperado: ${session!.expectedWeightGrams} g'),
                ],
              ),
      ),
    );
  }
}

class HomeAction {
  HomeAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class ActionGrid extends StatelessWidget {
  const ActionGrid({required this.actions, super.key});
  final List<HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((action) {
        return FilledButton.tonalIcon(
          onPressed: action.onTap,
          icon: Icon(action.icon),
          label: Text(action.label, textAlign: TextAlign.center),
        );
      }).toList(),
    );
  }
}

class LinkCartScreen extends StatelessWidget {
  const LinkCartScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ScannerScreen(
      title: 'Vincular carrinho',
      onCode: (code) async {
        await state.linkCart(code);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class ProductScannerScreen extends StatelessWidget {
  const ProductScannerScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ScannerScreen(
      title: 'Escanear produto',
      onCode: (code) async {
        final product = await state.findProduct(code);
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(state: state, product: product),
          ),
        );
      },
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.title, required this.onCode, super.key});
  final String title;
  final Future<void> Function(String code) onCode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (locked) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code == null) return;
              setState(() => locked = true);
              try {
                await widget.onCode(code);
              } catch (error) {
                if (context.mounted) showError(context, error.toString());
              } finally {
                if (mounted) setState(() => locked = false);
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.black.withValues(alpha: 0.65),
              child: const Text(
                'Aponte a camera para o codigo.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    required this.state,
    required this.product,
    super.key,
  });
  final AppState state;
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool busy = false;

  Future<void> add() async {
    setState(() => busy = true);
    try {
      await widget.state.addProduct(widget.product, quantity);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(product.brand),
                  const SizedBox(height: 12),
                  Text('Categoria: ${product.category}'),
                  Text('Preco: ${currency.format(product.price)}'),
                  Text('Peso: ${product.weightGrams} g'),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: quantity == 1
                    ? null
                    : () => setState(() => quantity--),
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$quantity', style: const TextStyle(fontSize: 20)),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: busy ? null : add,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar ao carrinho'),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Minha compra')),
      body: session == null
          ? const Center(child: Text('Nenhuma compra ativa.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...session.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        'Qtd: ${item.quantity} | ${currency.format(item.totalPrice)} | ${item.totalWeightGrams} g',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: item.quantity == 1
                                ? null
                                : () =>
                                      state.updateItem(item, item.quantity - 1),
                            icon: const Icon(Icons.remove),
                          ),
                          IconButton(
                            onPressed: () =>
                                state.updateItem(item, item.quantity + 1),
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            onPressed: () => state.removeItem(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SummaryCard(session: session),
                FilledButton.icon(
                  onPressed: state.finish,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar compra'),
                ),
              ],
            ),
    );
  }
}

class ValidationStationScreen extends StatefulWidget {
  const ValidationStationScreen({required this.state, super.key});
  final AppState state;

  @override
  State<ValidationStationScreen> createState() =>
      _ValidationStationScreenState();
}

class _ValidationStationScreenState extends State<ValidationStationScreen> {
  final measured = TextEditingController();
  List<ShoppingSession> pending = [];
  ShoppingSession? selected;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      pending = await widget.state.api.pendingValidations();
      selected = pending.firstOrNull;
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> validate() async {
    final session = selected;
    if (session == null) return;
    try {
      final token = await widget.state.validate(
        session.id,
        int.parse(measured.text),
      );
      if (!mounted) return;
      if (token == null) {
        showError(
          context,
          'Foi encontrada uma divergencia. Procure um funcionario.',
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExitTokenScreen(token: token)),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estacao de Validacao')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<ShoppingSession>(
                  initialValue: selected,
                  items: pending.map((session) {
                    return DropdownMenuItem(
                      value: session,
                      child: Text(
                        '${session.cart?.code ?? session.id} - ${currency.format(session.totalAmount)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selected = value),
                  decoration: const InputDecoration(
                    labelText: 'Compra pendente',
                  ),
                ),
                const SizedBox(height: 16),
                if (selected != null)
                  Text('Peso esperado: ${selected!.expectedWeightGrams} g'),
                TextField(
                  controller: measured,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso medido em gramas',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: validate,
                  icon: const Icon(Icons.scale),
                  label: const Text('Validar'),
                ),
              ],
            ),
    );
  }
}

class ExitTokenScreen extends StatelessWidget {
  const ExitTokenScreen({required this.token, super.key});
  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compra aprovada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Compra validada com sucesso.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Apresente este QR Code na saida.'),
            const SizedBox(height: 24),
            QrImageView(data: token, size: 220),
            const SizedBox(height: 12),
            Text(
              token,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.state, super.key});
  final AppState state;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ShoppingSession>> future = widget.state.api.history();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas compras')),
      body: FutureBuilder<List<ShoppingSession>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('Nenhuma compra no historico.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: sessions.map((session) {
              return Card(
                child: ListTile(
                  title: Text(currency.format(session.totalAmount)),
                  subtitle: Text(
                    '${session.itemCount} itens | ${session.expectedWeightGrams} g | ${session.status}',
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
  );
}
