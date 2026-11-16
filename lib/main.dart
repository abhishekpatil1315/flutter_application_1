import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/progress_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressController.initialize();
  runApp(const ProviderScope(child: MathQuestApp()));
}
