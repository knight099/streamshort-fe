import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamshort/core/theme.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String selectedCountryCode = '+91'; // Default to India

  final List<Map<String, String>> countryCodes = [
    {'code': '+91', 'country': 'IN', 'name': 'India'},
    {'code': '+1', 'country': 'US', 'name': 'United States'},
    {'code': '+44', 'country': 'GB', 'name': 'United Kingdom'},
    {'code': '+61', 'country': 'AU', 'name': 'Australia'},
    {'code': '+86', 'country': 'CN', 'name': 'China'},
    {'code': '+81', 'country': 'JP', 'name': 'Japan'},
    {'code': '+49', 'country': 'DE', 'name': 'Germany'},
    {'code': '+33', 'country': 'FR', 'name': 'France'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country Code Dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCountryCode,
                  items: countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${country['code']} ${country['country']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: widget.enabled
                      ? (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCountryCode = newValue;
                            });
                          }
                        }
                      : null,
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  errorText: widget.errorText,
                  counterText: '',
                ),
                onChanged: (value) {
                  // Format phone number as user types
                  if (value.length > 0) {
                    final formatted = _formatPhoneNumber(value);
                    if (formatted != value) {
                      widget.controller.text = formatted;
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: formatted.length),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Full number: $selectedCountryCode ${widget.controller.text}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatPhoneNumber(String input) {
    // Remove all non-digits
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format based on length
    if (digits.length <= 3) {
      return digits;
    } else if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    } else {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
  }

  String get fullPhoneNumber => '$selectedCountryCode ${widget.controller.text}';
}
