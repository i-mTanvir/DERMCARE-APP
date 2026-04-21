import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';

void main() {
  // Required before any async calls in main()
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DermCareBootstrap());
}

class DermCareBootstrap extends StatefulWidget {
  const DermCareBootstrap({super.key});

  @override
  State<DermCareBootstrap> createState() => _DermCareBootstrapState();
}

class _DermCareBootstrapState extends State<DermCareBootstrap> {
  late final Future<void> _backendInit = _initBackend();

  Future<void> _initBackend() async {
    SupabaseConfig.validate();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _backendInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text(
                        'Supabase failed to initialize.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const DermCareApp();
      },
    );
  }
}

class DermCareApp extends StatelessWidget {
  const DermCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthService is available anywhere in the app via Provider.of<AuthService>(context)
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
        title: 'DermCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        // GoRouter handles all navigation
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
