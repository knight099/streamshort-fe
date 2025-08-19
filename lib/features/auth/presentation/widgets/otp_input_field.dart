import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final int length;
  final String? errorText;

  const OtpInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.length = 6,
    this.errorText,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otpValues;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
    _otpValues = List.generate(widget.length, (index) => '');

    // Listen to changes in individual controllers
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        _updateOtpValue();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateOtpValue() {
    final otp = _controllers.map((c) => c.text).join();
    widget.controller.text = otp;
    
    // Update internal values
    for (int i = 0; i < widget.length; i++) {
      _otpValues[i] = _controllers[i].text;
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.length,
            (index) => _buildOtpField(index),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _focusNodes[index].hasFocus
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) => _onOtpChanged(value, index),
        onTap: () {
          // Select all text when tapped
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }
}
