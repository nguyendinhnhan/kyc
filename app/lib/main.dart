import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  if (!['development', 'staging', 'production'].contains(environment)) {
    throw ArgumentError('Unsupported APP_ENV');
  }
  await dotenv.load(fileName: '.env.$environment');

  runApp(const ProviderScope(child: KycApp()));
}
