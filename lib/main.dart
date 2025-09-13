import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app.dart';
import 'core/config/environment.dart';

void main() {
  // Set environment - change this to switch between APIs
  EnvironmentConfig.setEnvironment(Environment.development);
  
  runApp(
    const ProviderScope(
      child: StreamshortApp(),
    ),
  );
}