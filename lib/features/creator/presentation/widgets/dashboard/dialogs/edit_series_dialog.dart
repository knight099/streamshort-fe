import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';

class EditSeriesDialog extends ConsumerStatefulWidget {
  final CreatorSeries series;

  const EditSeriesDialog({
    super.key,
    required this.series,
  });

  @override
  ConsumerState<EditSeriesDialog> createState() => _EditSeriesDialogState();
}

class _EditSeriesDialogState extends ConsumerState<EditSeriesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _synopsisController;
  late String _selectedLanguage;
  late String _selectedPriceType;
  late double? _priceAmount;
  late final List<String> _selectedCategories;
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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.series.title);
    _synopsisController = TextEditingController(text: widget.series.synopsis);
    _selectedLanguage = widget.series.language;
    _selectedPriceType = widget.series.priceType;
    _priceAmount = widget.series.priceAmount;
    _selectedCategories = List.from(widget.series.categoryTags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  Future<void> _updateSeries() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).updateSeries(
        seriesId: widget.series.id,
        title: _titleController.text.trim(),
        synopsis: _synopsisController.text.trim(),
        language: _selectedLanguage,
        categoryTags: _selectedCategories,
        priceType: _selectedPriceType,
        priceAmount: _priceAmount,
        accessToken: accessToken,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Series updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating series: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Series'),
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
                  initialValue: _priceAmount?.toString() ?? '',
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
          onPressed: _isLoading ? null : _updateSeries,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Series'),
        ),
      ],
    );
  }
}
