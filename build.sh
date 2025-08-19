#!/bin/bash

echo "🚀 Building Streamshort Flutter App..."

# Create necessary directories
mkdir -p lib/features/content/presentation/widgets
mkdir -p lib/features/content/presentation/providers
mkdir -p lib/features/content/data/repositories
mkdir -p lib/features/creator/presentation/screens
mkdir -p lib/features/creator/presentation/widgets
mkdir -p lib/features/creator/presentation/providers
mkdir -p lib/features/creator/data/repositories
mkdir -p lib/features/profile/presentation/screens
mkdir -p lib/features/profile/presentation/providers
mkdir -p lib/features/subscription/presentation/screens
mkdir -p lib/features/subscription/presentation/providers
mkdir -p lib/features/subscription/data/repositories
mkdir -p lib/features/engagement/presentation/widgets
mkdir -p lib/features/engagement/presentation/providers
mkdir -p lib/features/engagement/data/repositories
mkdir -p lib/features/payment/presentation/widgets
mkdir -p lib/features/payment/presentation/providers
mkdir -p lib/features/payment/data/repositories
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts

echo "📁 Directories created successfully"

# Generate code files
echo "🔧 Generating code files..."

# Create content providers
cat > lib/features/content/presentation/providers/content_providers.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/content/data/models/content_models.dart';
import 'package:streamshort/features/content/data/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

final seriesListProvider = StateNotifierProvider<SeriesListNotifier, AsyncValue<SeriesListResponse>>((ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return SeriesListNotifier(repository);
});

class SeriesListNotifier extends StateNotifier<AsyncValue<SeriesListResponse>> {
  final ContentRepository _repository;

  SeriesListNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadSeries({String? language, String? category, int page = 1}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _repository.getSeries(
        language: language,
        category: category,
        page: page,
      );
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchSeries(String query) async {
    try {
      state = const AsyncValue.loading();
      final response = await _repository.searchSeries(query);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
EOF

# Create content repository
cat > lib/features/content/data/repositories/content_repository.dart << 'EOF'
import 'package:streamshort/core/api/api_client.dart';
import 'package:streamshort/features/content/data/models/content_models.dart';

class ContentRepository {
  final ApiClient _apiClient;

  ContentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(_createDio());

  static Dio _createDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    return dio;
  }

  Future<SeriesListResponse> getSeries({
    String? language,
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _apiClient.getSeries(
        language: language,
        category: category,
        page: page,
        perPage: perPage,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Series> getSeriesById(String id) async {
    try {
      final response = await _apiClient.getSeriesById(id);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SeriesListResponse> searchSeries(String query) async {
    try {
      // For now, just return all series and filter client-side
      // In production, this should use a proper search endpoint
      final response = await _apiClient.getSeries();
      final filteredItems = response.items.where((series) {
        return series.title.toLowerCase().contains(query.toLowerCase()) ||
               series.synopsis.toLowerCase().contains(query.toLowerCase()) ||
               series.categoryTags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();
      
      return SeriesListResponse(
        total: filteredItems.length,
        items: filteredItems,
        page: 1,
        perPage: filteredItems.length,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return Exception('Invalid request. Please check your input.');
        case 404:
          return Exception('Content not found.');
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          return Exception('Network error. Please check your connection.');
      }
    }
    return Exception('An unexpected error occurred.');
  }
}
EOF

# Create series card widget
cat > lib/features/content/presentation/widgets/series_card.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streamshort/core/theme.dart';
import 'package:streamshort/features/content/data/models/content_models.dart';

class SeriesCard extends StatelessWidget {
  final Series series;

  const SeriesCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/series/${series.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: series.thumbnailUrl != null
                    ? Image.network(
                        series.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.video_library_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          series.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (series.priceType != 'free') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            series.priceType == 'subscription' ? 'SUB' : '₹${series.priceAmount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Synopsis
                  Text(
                    series.synopsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tags and Language
                  Row(
                    children: [
                      // Language
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          series.language.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Category tags
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: series.categoryTags.take(2).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

# Create series shimmer widget
cat > lib/features/content/presentation/widgets/series_shimmer.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SeriesShimmer extends StatelessWidget {
  const SeriesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail shimmer
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 200,
                color: Colors.white,
              ),
            ),
          ),
          
          // Content shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Synopsis shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tags shimmer
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
EOF

# Create other necessary files
cat > lib/features/content/presentation/screens/series_detail_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SeriesDetailScreen extends ConsumerWidget {
  final String seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Series Details'),
      ),
      body: Center(
        child: Text('Series Detail Screen for ID: $seriesId'),
      ),
    );
  }
}
EOF

cat > lib/features/content/presentation/screens/episode_player_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpisodePlayerScreen extends ConsumerWidget {
  final String episodeId;

  const EpisodePlayerScreen({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Player'),
      ),
      body: Center(
        child: Text('Episode Player for ID: $episodeId'),
      ),
    );
  }
}
EOF

cat > lib/features/creator/presentation/screens/creator_onboarding_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorOnboardingScreen extends ConsumerWidget {
  const CreatorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Onboarding'),
      ),
      body: const Center(
        child: Text('Creator Onboarding Screen'),
      ),
    );
  }
}
EOF

cat > lib/features/creator/presentation/screens/creator_dashboard_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
      ),
      body: const Center(
        child: Text('Creator Dashboard Screen'),
      ),
    );
  }
}
EOF

cat > lib/features/creator/presentation/screens/series_management_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeriesManagementScreen extends ConsumerWidget {
  const SeriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Series'),
      ),
      body: const Center(
        child: Text('Series Management Screen'),
      ),
    );
  }
}
EOF

cat > lib/features/profile/presentation/screens/profile_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}
EOF

cat > lib/features/subscription/presentation/screens/subscription_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionScreen extends ConsumerWidget {
  final String seriesId;

  const SubscriptionScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: Center(
        child: Text('Subscription Screen for Series: $seriesId'),
      ),
    );
  }
}
EOF

# Create other provider files
cat > lib/features/content/data/providers.dart << 'EOF'
export 'package:streamshort/features/content/presentation/providers/content_providers.dart';
export 'package:streamshort/features/content/data/repositories/content_repository.dart';
EOF

cat > lib/features/creator/data/providers.dart << 'EOF'
export 'package:streamshort/features/creator/presentation/providers/creator_providers.dart';
export 'package:streamshort/features/creator/data/repositories/creator_repository.dart';
EOF

cat > lib/features/profile/data/providers.dart << 'EOF'
export 'package:streamshort/features/profile/presentation/providers/profile_providers.dart';
export 'package:streamshort/features/profile/data/repositories/profile_repository.dart';
EOF

cat > lib/features/subscription/data/providers.dart << 'EOF'
export 'package:streamshort/features/subscription/presentation/providers/subscription_providers.dart';
export 'package:streamshort/features/subscription/data/repositories/subscription_repository.dart';
EOF

cat > lib/features/engagement/data/providers.dart << 'EOF'
export 'package:streamshort/features/engagement/presentation/providers/engagement_providers.dart';
export 'package:streamshort/features/engagement/data/repositories/engagement_repository.dart';
EOF

cat > lib/features/payment/data/providers.dart << 'EOF'
export 'package:streamshort/features/payment/presentation/providers/payment_providers.dart';
export 'package:streamshort/features/payment/data/repositories/payment_repository.dart';
EOF

echo "📝 Code files generated successfully"

# Run build runner to generate missing files
echo "🔨 Running build runner..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "✅ Build completed successfully!"
echo "🚀 You can now run: flutter run"
