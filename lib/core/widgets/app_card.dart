import '../design/design_system.dart';

/// LNDRY Reusable Card
///
/// Usage:
/// ```dart
/// AppCard(child: Text('Hello'))
/// AppCard.elevated(child: ServiceTile())
/// AppCard.glass(child: SomeStat())
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.elevation = 0,
    this.shadowColor,
    this.onTap,
    this.onLongPress,
    this.clipBehavior = Clip.antiAlias,
    _CardVariant variant = _CardVariant.flat,
  }) : _variant = variant;

  const AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) : this(
          key: key,
          child: child,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          onTap: onTap,
          elevation: AppElevation.md,
          variant: _CardVariant.elevated,
        );

  const AppCard.glass({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) : this(
          key: key,
          child: child,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          onTap: onTap,
          variant: _CardVariant.glass,
        );

  const AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) : this(
          key: key,
          child: child,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          borderColor: borderColor,
          backgroundColor: backgroundColor,
          onTap: onTap,
          variant: _CardVariant.outlined,
        );

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final Color? shadowColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Clip clipBehavior;
  final _CardVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius ?? AppRadius.card.r);
    final effectivePadding = padding ?? EdgeInsets.all(16.r);
    final effectiveMargin = margin ?? EdgeInsets.zero;

    Widget card = switch (_variant) {
      _CardVariant.flat => _buildFlat(isDark, radius, effectivePadding),
      _CardVariant.elevated => _buildElevated(isDark, radius, effectivePadding),
      _CardVariant.glass => _buildGlass(isDark, radius, effectivePadding),
      _CardVariant.outlined => _buildOutlined(isDark, radius, effectivePadding),
    };

    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: card,
        ),
      );
    }

    return Padding(padding: effectiveMargin, child: card);
  }

  Widget _buildFlat(bool isDark, BorderRadius radius, EdgeInsetsGeometry p) {
    return Container(
      padding: p,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurfaceContainer : AppColors.surface),
        borderRadius: radius,
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  Widget _buildElevated(bool isDark, BorderRadius radius, EdgeInsetsGeometry p) {
    return Container(
      padding: p,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurfaceContainer : AppColors.surface),
        borderRadius: radius,
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : AppElevation.cardShadow,
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  Widget _buildGlass(bool isDark, BorderRadius radius, EdgeInsetsGeometry p) {
    return Container(
      padding: p,
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassDark : AppColors.glassWhite,
        borderRadius: radius,
        border: Border.all(color: AppColors.glassStroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  Widget _buildOutlined(bool isDark, BorderRadius radius, EdgeInsetsGeometry p) {
    return Container(
      padding: p,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurfaceContainer : AppColors.surface),
        borderRadius: radius,
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.darkOutline : AppColors.outline),
          width: borderWidth,
        ),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

enum _CardVariant { flat, elevated, glass, outlined }

// ── Shimmer Skeleton Card ─────────────────────────────────────────────────────

/// A shimmer placeholder card used while content loads.
class AppSkeletonCard extends StatefulWidget {
  const AppSkeletonCard({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  final double? height;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<AppSkeletonCard> createState() => _AppSkeletonCardState();
}

class _AppSkeletonCardState extends State<AppSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          height: widget.height ?? 80.h,
          width: widget.width ?? double.infinity,
          margin: widget.margin ?? EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? AppRadius.card.r),
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
    );
  }
}

// ── Info Row helper ────────────────────────────────────────────────────────────

/// A key-value row inside a card.
class AppCardInfoRow extends StatelessWidget {
  const AppCardInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.icon,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16.r, color: AppColors.onSurfaceVariant),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: labelStyle ??
                AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: valueStyle ?? AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}
