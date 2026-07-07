import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// LNDRY Reusable Skeleton shapes (line, circular, rectangular)
///
/// Features animated pulse transitions.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton.line({
    super.key,
    required this.width,
    this.height,
    this.borderRadius,
    this.margin,
  })  : _shape = _SkeletonShape.line,
        size = null;

  const AppSkeleton.circle({
    super.key,
    required this.size,
    this.margin,
  })  : _shape = _SkeletonShape.circle,
        width = null,
        height = null,
        borderRadius = null;

  const AppSkeleton.rectangular({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  })  : _shape = _SkeletonShape.rectangular,
        size = null;

  final double? width;
  final double? height;
  final double? size;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final _SkeletonShape _shape;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.standard),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final margin = widget.margin ?? EdgeInsets.zero;

    return Padding(
      padding: margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget._shape == _SkeletonShape.circle
                ? widget.size?.r
                : widget.width?.w ?? double.infinity,
            height: widget._shape == _SkeletonShape.circle
                ? widget.size?.r
                : widget.height?.h ?? 16.h,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              shape: widget._shape == _SkeletonShape.circle
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: widget._shape == _SkeletonShape.circle
                  ? null
                  : BorderRadius.circular(
                      widget.borderRadius ??
                          (widget._shape == _SkeletonShape.line
                              ? AppRadius.xs
                              : AppRadius.image).r,
                    ),
              gradient: LinearGradient(
                colors: [
                  AppColors.shimmerBase,
                  AppColors.shimmerHighlight,
                  AppColors.shimmerBase,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + _animation.value * 2, 0),
                end: Alignment(1.0 + _animation.value * 2, 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SkeletonShape { line, circle, rectangular }
