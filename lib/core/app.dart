import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'theme.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/content/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';

class StreamshortApp extends ConsumerWidget {
  const StreamshortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authNotifierProvider);
    
    // Initialize auth restoration on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).restoreAuth();
    });
    
    return MaterialApp(
      title: 'Streamshort',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authState is AuthAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}