import 'package:flutter/material.dart';
import '../../../data/models/creator_models.dart';
import '../../../utils/date_formatter.dart';
import 'edit_profile_dialog.dart';

class ProfileTab extends StatelessWidget {
  final bool isLoading;
  final CreatorProfile? creatorProfile;
  final VoidCallback onRefresh;
  final VoidCallback onOnboarding;

  const ProfileTab({
    super.key,
    required this.isLoading,
    required this.creatorProfile,
    required this.onRefresh,
    required this.onOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (creatorProfile == null) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildDebugInfo(context),
          _buildProfileHeader(context),
          const SizedBox(height: 24),
          _buildProfileStats(context),
          const SizedBox(height: 24),
          _buildProfileActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Creator Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh Profile',
        ),
      ],
    );
  }

  Widget _buildDebugInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Text(
            'Profile Tab Active - Creator: ${creatorProfile?.displayName ?? "Loading..."}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    creatorProfile!.displayName.isNotEmpty 
                        ? creatorProfile!.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              creatorProfile!.displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditProfileDialog(context),
                            tooltip: 'Edit Profile',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildKycStatusChip(context),
                      if (creatorProfile!.rating != null)
                        _buildRatingRow(context),
                    ],
                  ),
                ),
              ],
            ),
            if (creatorProfile!.bio != null && creatorProfile!.bio!.isNotEmpty)
              _buildBioSection(context),
            const SizedBox(height: 16),
            _buildDateInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKycStatusChip(BuildContext context) {
    return Chip(
      label: Text(creatorProfile!.kycStatus),
      backgroundColor: creatorProfile!.isVerified
          ? Colors.green.shade100
          : creatorProfile!.isPending
              ? Colors.orange.shade100
              : Colors.red.shade100,
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          creatorProfile!.rating!.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Bio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(creatorProfile!.bio!),
      ],
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member Since',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                formatDate(creatorProfile!.createdAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (creatorProfile!.updatedAt != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  formatDate(creatorProfile!.updatedAt!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProfileStats(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'KYC Status',
                    creatorProfile!.kycStatus.toUpperCase(),
                    creatorProfile!.isVerified ? Icons.verified : Icons.pending,
                    creatorProfile!.isVerified ? Colors.green : Colors.orange,
                  ),
                ),
                if (creatorProfile!.rating != null)
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Rating',
                      creatorProfile!.rating!.toStringAsFixed(1),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Edit Profile',
              Icons.edit,
              () => _showEditProfileDialog(context),
            ),
            if (!creatorProfile!.isVerified)
              _buildActionButton(
                context,
                'Complete KYC',
                Icons.verified_user,
                () => _showKYCCompletionDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Creator Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete creator onboarding to get started',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onOnboarding,
              icon: const Icon(Icons.add),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditCreatorProfileDialog(
        creatorProfile: creatorProfile!,
        onProfileUpdated: (updatedProfile) {
          // TODO: Handle profile update
        },
      ),
    );
  }

  void _showKYCCompletionDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KYC completion coming soon!')),
    );
  }
}
