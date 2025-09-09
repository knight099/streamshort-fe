import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streamshort/features/auth/presentation/screens/login_screen.dart';
import 'package:streamshort/features/content/presentation/screens/episode_player_screen.dart';
import 'package:streamshort/features/content/presentation/screens/home_screen.dart';
import 'package:streamshort/features/content/presentation/screens/series_detail_screen.dart';
import 'package:streamshort/features/creator/presentation/screens/creator_onboarding_screen.dart';
import 'package:streamshort/features/creator/presentation/screens/series_management_screen.dart';
import 'package:streamshort/features/profile/presentation/screens/profile_screen.dart';
import 'package:streamshort/features/subscription/presentation/screens/subscription_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/series/:id',
        name: 'series-detail',
        builder: (context, state) {
          final seriesId = state.pathParameters['id'] ?? '';
          return SeriesDetailScreen(seriesId: seriesId);
        },
      ),
      GoRoute(
        path: '/episode/:id',
        name: 'episode-player',
        builder: (context, state) {
          final episodeId = state.pathParameters['id'] ?? '';
          final seriesId = state.pathParameters['seriesId'] ?? '';
          return EpisodePlayerScreen(
            episodeId: episodeId,
            seriesId: seriesId,
          );
        },
      ),
      
      // Creator Routes
      GoRoute(
        path: '/creator/onboarding',
        name: 'creator-onboarding',
        builder: (context, state) => const CreatorOnboardingScreen(),
      ),
      GoRoute(
        path: '/creator/series',
        name: 'series-management',
        builder: (context, state) => const SeriesManagementScreen(),
      ),
      
      // Profile & Settings
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Subscription & Payments
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
