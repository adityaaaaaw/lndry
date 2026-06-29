import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// LNDRY Reusable OTP Input Field
///
/// Features auto-focus traversal and support for standard validation.
class AppOtpInput extends StatefulWidget {
  const AppOtpInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.length = 6,
    this.errorText,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final int length;
  final String? errorText;
  final bool enabled;

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<FocusNode> _listenerFocusNodes;
  late List<String> _code;

  @override
  void initState() {
    super.initState();
    _code = List.filled(widget.length, '');
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
    _listenerFocusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    for (final fn in _listenerFocusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _onKeyPress(int index, String value) {
    if (value.length > 1) {
      // Handle paste or multi-char input
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < widget.length && i < digits.length; i++) {
        _code[i] = digits[i];
        _controllers[i].text = digits[i];
      }
      final finalCode = _code.join('');
      widget.onChanged(finalCode);
      if (finalCode.length == widget.length) {
        widget.onCompleted(finalCode);
      }
      FocusScope.of(context).unfocus();
      return;
    }

    _code[index] = value;
    final finalCode = _code.join('');
    widget.onChanged(finalCode);

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        widget.onCompleted(finalCode);
      }
    }
  }

  void _onBackspace(int index) {
    if (_code[index].isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _code[index - 1] = '';
      widget.onChanged(_code.join(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.length,
            (index) => SizedBox(
              width: 48.w,
              height: 56.h,
              child: KeyboardListener(
                focusNode: _listenerFocusNodes[index], // Persistent focus node for capturing backspace
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    _onBackspace(index);
                  }
                },
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: widget.enabled
                        ? theme.colorScheme.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  maxLength: 1,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    fillColor: widget.enabled
                        ? AppColors.surfaceContainer
                        : AppColors.surfaceVariant,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input.r),
                      borderSide: BorderSide(
                        color: widget.errorText != null
                            ? AppColors.error
                            : AppColors.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input.r),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) => _onKeyPress(index, val),
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const Gap(8),
          Text(
            widget.errorText!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
