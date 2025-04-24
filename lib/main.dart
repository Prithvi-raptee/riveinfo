import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'rive_controller.dart';
import 'rive_forge_page.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {

    await RiveFile.initialize();
  } catch (e) {
    debugPrint("Failed to initialize Rive: $e");

  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => RiveController(),
      child: const RiveForgeApp(),
    ),
  );
}

class RiveForgeApp extends StatelessWidget {
  const RiveForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiveForge',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const RiveForgePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}