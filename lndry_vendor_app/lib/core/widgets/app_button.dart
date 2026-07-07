import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/tokens/radius.dart';

/// LNDRY Primary / Secondary / Outlined / Text Button
///
/// Converts to StatefulWidget to implement premium press scaling (to 0.98).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
    _ButtonVariant variant = _ButtonVariant.primary,
  }) : _variant = variant;

  const AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double? height,
  }) : this(
          key: key,
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          isDisabled: isDisabled,
          width: width,
          height: height,
          variant: _ButtonVariant.secondary,
        );

  const AppButton.outlined({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double? height,
    Color? foregroundColor,
  }) : this(
          key: key,
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          isDisabled: isDisabled,
          width: width,
          height: height,
          variant: _ButtonVariant.outlined,
          foregroundColor: foregroundColor,
        );

  const AppButton.text({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    bool isDisabled = false,
  }) : this(
          key: key,
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          isDisabled: isDisabled,
          variant: _ButtonVariant.text,
        );

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final _ButtonVariant _variant;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = (widget.isLoading || widget.isDisabled) ? null : widget.onPressed;

    return MouseRegion(
      cursor: effectiveCallback != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) {
          if (effectiveCallback != null) {
            _controller.forward();
          }
        },
        onTapUp: (_) {
          if (effectiveCallback != null) {
            _controller.reverse();
          }
        },
        onTapCancel: () {
          if (effectiveCallback != null) {
            _controller.reverse();
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 52.h,
            child: switch (widget._variant) {
              _ButtonVariant.primary => _buildElevated(effectiveCallback),
              _ButtonVariant.secondary => _buildSecondary(effectiveCallback),
              _ButtonVariant.outlined => _buildOutlined(effectiveCallback),
              _ButtonVariant.text => _buildText(effectiveCallback),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildElevated(VoidCallback? cb) {
    return ElevatedButton(
      onPressed: cb,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isDisabled
            ? AppColors.outline
            : (widget.backgroundColor ?? AppColors.primary),
        foregroundColor: widget.foregroundColor ?? AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppRadius.button.r),
        ),
        padding: widget.padding,
        elevation: 0,
      ),
      child: _child(widget.foregroundColor ?? AppColors.onPrimary),
    );
  }

  Widget _buildSecondary(VoidCallback? cb) {
    return ElevatedButton(
      onPressed: cb,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? AppColors.primaryContainer,
        foregroundColor: widget.foregroundColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppRadius.button.r),
        ),
        padding: widget.padding,
        elevation: 0,
      ),
      child: _child(widget.foregroundColor ?? AppColors.primary),
    );
  }

  Widget _buildOutlined(VoidCallback? cb) {
    final color = widget.foregroundColor ?? AppColors.primary;
    return OutlinedButton(
      onPressed: cb,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: widget.isDisabled ? AppColors.outline : color,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppRadius.button.r),
        ),
        padding: widget.padding,
      ),
      child: _child(color),
    );
  }

  Widget _buildText(VoidCallback? cb) {
    return TextButton(
      onPressed: cb,
      style: TextButton.styleFrom(
        foregroundColor: widget.foregroundColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? AppRadius.chip.r),
        ),
        padding: widget.padding,
      ),
      child: _child(widget.foregroundColor ?? AppColors.primary),
    );
  }

  Widget _child(Color fgColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    }

    final text = Text(
      widget.label,
      style: (widget.textStyle ?? AppTypography.buttonText).copyWith(color: fgColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          SizedBox(width: 8.w),
          Flexible(child: text),
        ],
      );
    }

    return text;
  }
}

enum _ButtonVariant { primary, secondary, outlined, text }
