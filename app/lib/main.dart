import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables based on flavor
  // For now, default to development
  await dotenv.load(fileName: '.env.development');
  
  runApp(
    const ProviderScope(
      child: KycApp(),
    ),
  );
}
