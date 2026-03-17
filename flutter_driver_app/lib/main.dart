import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/offline_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline queue
  await Hive.initFlutter();
  await OfflineService().init();

  runApp(const ProviderScope(child: KavyaTransportsApp()));
}

class KavyaTransportsApp extends ConsumerWidget {
  const KavyaTransportsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Kavya Transports',
      debugShowCheckedModeBanner: false,
      theme: KTTheme.lightTheme,
      darkTheme: KTTheme.darkTheme,
      routerConfig: router,
    );
  }
}
