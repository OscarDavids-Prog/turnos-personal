import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/empleados_provider.dart';
import 'providers/feriados_provider.dart';
import 'providers/turnos_provider.dart';
import 'screens/tablero_semanal_screen.dart';
import 'screens/resumen_mensual_screen.dart';
import 'screens/feriados_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const TurnosAdminApp());
}

class TurnosAdminApp extends StatelessWidget {
  const TurnosAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmpleadosProvider()),
        ChangeNotifierProvider(create: (_) => TurnosProvider()),
        ChangeNotifierProvider(create: (_) => FeriadosProvider()),
      ],
      child: MaterialApp(
        title: 'Turnos Lavasol – Admin',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) return const _LoginScreen();
        return const _HomeShell();
      },
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FlutterLogo(size: 64),
                const SizedBox(height: 24),
                Text(
                  'Turnos Lavasol',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  decoration:
                      const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  decoration:
                      const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _iniciarSesion,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Ingresar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.grid_view),
      label: Text('Tablero'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart),
      label: Text('Resumen'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event),
      label: Text('Feriados'),
    ),
  ];

  static const _screens = [
    TableroSemanalScreen(),
    ResumenMensualScreen(),
    FeriadosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) =>
                setState(() => _selectedIndex = i),
            destinations: _destinations,
            labelType: NavigationRailLabelType.all,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesión',
                    onPressed: () =>
                        Supabase.instance.client.auth.signOut(),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
