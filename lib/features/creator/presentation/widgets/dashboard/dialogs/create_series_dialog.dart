import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';

class CreateSeriesDialog extends ConsumerStatefulWidget {
  const CreateSeriesDialog({super.key});

  @override
  ConsumerState<CreateSeriesDialog> createState() => _CreateSeriesDialogState();
}

class _CreateSeriesDialogState extends ConsumerState<CreateSeriesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _synopsisController = TextEditingController();
  String _selectedLanguage = 'en';
  String _selectedPriceType = 'free';
  final List<String> _selectedCategories = [];
  double? _priceAmount;
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'bn', 'name': 'Bengali'},
  ];

  final List<String> _categories = [
    'Education', 'Entertainment', 'Technology', 'Business', 'Health',
    'Fitness', 'Cooking', 'Travel', 'Music', 'Sports', 'Comedy',
    'Drama', 'Action', 'Romance', 'Thriller', 'Documentary',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Series'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Series Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _synopsisController,
                decoration: const InputDecoration(
                  labelText: 'Synopsis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a synopsis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                items: _languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriceType,
                decoration: const InputDecoration(
                  labelText: 'Pricing',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Free')),
                  DropdownMenuItem(value: 'subscription', child: Text('Subscription')),
                  DropdownMenuItem(value: 'one_time', child: Text('One Time Purchase')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriceType = value!;
                    if (value == 'free') {
                      _priceAmount = null;
                    }
                  });
                },
              ),
              if (_selectedPriceType != 'free') ...[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedPriceType != 'free' && (value == null || value.isEmpty)) {
                      return 'Please enter a price';
                    }
                    if (value != null && value.isNotEmpty) {
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _priceAmount = double.tryParse(value);
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text('Categories (select up to 3):'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected && _selectedCategories.length < 3) {
                          _selectedCategories.add(category);
                        } else if (!selected) {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSeries,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createSeries() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateSeriesRequest(
        title: _titleController.text.trim(),
        synopsis: _synopsisController.text.trim(),
        language: _selectedLanguage,
        categoryTags: _selectedCategories,
        priceType: _selectedPriceType,
        priceAmount: _priceAmount,
      );

      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).createSeries(
        title: request.title,
        synopsis: request.synopsis,
        language: request.language,
        categoryTags: request.categoryTags,
        priceType: request.priceType,
        priceAmount: request.priceAmount,
        thumbnailUrl: request.thumbnailUrl,
        accessToken: accessToken,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Series created successfully!')),
        );
        // Refresh the dashboard
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating series: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
