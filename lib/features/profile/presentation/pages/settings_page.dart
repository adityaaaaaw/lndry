import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../repositories/repositories.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../config/env.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  NotificationPreferences _notificationPrefs = const NotificationPreferences();
  bool _prefsLoaded = false;
  bool _isSavingPrefs = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final authState = ref.read(authProvider);
    final signedIn = authState is AuthAuthenticated || Env.demoMode;

    if (!signedIn) {
      try {
        final storage = ref.read(storageServiceProvider);
        final orderUpdates = storage.getBool('guest_pref_order_updates') ?? true;
        final promotions = storage.getBool('guest_pref_promotions') ?? false;
        final newProducts = storage.getBool('guest_pref_new_products') ?? false;
        final deliveryUpdates = storage.getBool('guest_pref_delivery_updates') ?? true;
        final priceDrops = storage.getBool('guest_pref_price_drops') ?? false;

        if (mounted) {
          setState(() {
            _notificationPrefs = NotificationPreferences(
              orderUpdates: orderUpdates,
              promotions: promotions,
              newProducts: newProducts,
              deliveryUpdates: deliveryUpdates,
              priceDrops: priceDrops,
            );
            _prefsLoaded = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _prefsLoaded = true);
      }
      return;
    }

    try {
      final prefs = await ref
          .read(customerRepositoryProvider)
          .getNotificationPreferences();
      if (mounted) {
        setState(() {
          _notificationPrefs = prefs;
          _prefsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _prefsLoaded = true);
    }
  }

  Future<void> _updateNotificationPrefs({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryUpdates,
    bool? priceDrops,
  }) async {
    final authState = ref.read(authProvider);
    final signedIn = authState is AuthAuthenticated || Env.demoMode;

    setState(() => _isSavingPrefs = true);
    try {
      if (!signedIn) {
        final storage = ref.read(storageServiceProvider);
        final updated = NotificationPreferences(
          orderUpdates: orderUpdates ?? _notificationPrefs.orderUpdates,
          promotions: promotions ?? _notificationPrefs.promotions,
          newProducts: newProducts ?? _notificationPrefs.newProducts,
          deliveryUpdates: deliveryUpdates ?? _notificationPrefs.deliveryUpdates,
          priceDrops: priceDrops ?? _notificationPrefs.priceDrops,
        );

        if (orderUpdates != null) {
          await storage.saveBool('guest_pref_order_updates', value: orderUpdates);
        }
        if (promotions != null) {
          await storage.saveBool('guest_pref_promotions', value: promotions);
        }
        if (newProducts != null) {
          await storage.saveBool('guest_pref_new_products', value: newProducts);
        }
        if (deliveryUpdates != null) {
          await storage.saveBool('guest_pref_delivery_updates', value: deliveryUpdates);
        }
        if (priceDrops != null) {
          await storage.saveBool('guest_pref_price_drops', value: priceDrops);
        }

        if (mounted) setState(() => _notificationPrefs = updated);
        return;
      }

      final updated = await ref
          .read(customerRepositoryProvider)
          .updateNotificationPreferences(
            orderUpdates: orderUpdates,
            promotions: promotions,
            newProducts: newProducts,
            deliveryUpdates: deliveryUpdates,
            priceDrops: priceDrops,
          );
      if (mounted) setState(() => _notificationPrefs = updated);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSavingPrefs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.titleLarge),
        centerTitle: true,
        // Use context.pop() — settings is pushed onto the nav stack.
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: !_prefsLoaded
            ? const AppLoadingPage()
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Theme Preferences ────────────────────────────────────
                    Text('Theme', style: AppTypography.titleMedium),
                    Gap(AppSpacing.cardGap.h),
                    AppCard.outlined(
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card.r),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text('System Default',
                                  style: AppTypography.bodyMedium),
                              value: ThemeMode.system,
                              groupValue: themeMode,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setTheme(val);
                                }
                              },
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            RadioListTile<ThemeMode>(
                              title: Text('Light Mode',
                                  style: AppTypography.bodyMedium),
                              value: ThemeMode.light,
                              groupValue: themeMode,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setTheme(val);
                                }
                              },
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            RadioListTile<ThemeMode>(
                              title: Text('Dark Mode',
                                  style: AppTypography.bodyMedium),
                              value: ThemeMode.dark,
                              groupValue: themeMode,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setTheme(val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h * 1.5),

                    // ── Notifications ────────────────────────────────────────
                    Text('Notifications', style: AppTypography.titleMedium),
                    Gap(AppSpacing.cardGap.h),
                    AppCard.outlined(
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card.r),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              title: Text('Order Updates',
                                  style: AppTypography.bodyMedium),
                              subtitle: Text(
                                'Pickup, status and delivery alerts',
                                style: AppTypography.caption,
                              ),
                              value: _notificationPrefs.orderUpdates,
                              activeColor: AppColors.primary,
                              onChanged: _isSavingPrefs
                                  ? null
                                  : (value) => _updateNotificationPrefs(
                                        orderUpdates: value,
                                      ),
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            SwitchListTile.adaptive(
                              title: Text('Promotions',
                                  style: AppTypography.bodyMedium),
                              subtitle: Text(
                                'Offers and campaign updates',
                                style: AppTypography.caption,
                              ),
                              value: _notificationPrefs.promotions,
                              activeColor: AppColors.primary,
                              onChanged: _isSavingPrefs
                                  ? null
                                  : (value) => _updateNotificationPrefs(
                                        promotions: value,
                                      ),
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            SwitchListTile.adaptive(
                              title: Text('New Products',
                                  style: AppTypography.bodyMedium),
                              value: _notificationPrefs.newProducts,
                              activeColor: AppColors.primary,
                              onChanged: _isSavingPrefs
                                  ? null
                                  : (value) => _updateNotificationPrefs(
                                        newProducts: value,
                                      ),
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            SwitchListTile.adaptive(
                              title: Text('Delivery Updates',
                                  style: AppTypography.bodyMedium),
                              value: _notificationPrefs.deliveryUpdates,
                              activeColor: AppColors.primary,
                              onChanged: _isSavingPrefs
                                  ? null
                                  : (value) => _updateNotificationPrefs(
                                        deliveryUpdates: value,
                                      ),
                            ),
                            Divider(height: 1, color: AppColors.outline),
                            SwitchListTile.adaptive(
                              title: Text('Price Drops',
                                  style: AppTypography.bodyMedium),
                              value: _notificationPrefs.priceDrops,
                              activeColor: AppColors.primary,
                              onChanged: _isSavingPrefs
                                  ? null
                                  : (value) => _updateNotificationPrefs(
                                        priceDrops: value,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(AppSpacing.sectionGap.h * 1.5),

                    // ── App Version ──────────────────────────────────────────
                    Center(
                      child: Text(
                        'LNDRY v1.0.0',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Gap(AppSpacing.md.h),
                  ],
                ),
              ),
      ),
    );
  }
}
