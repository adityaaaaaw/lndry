import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Loaded from StorageService in initState.
  bool _pushNotifications = true;
  bool _whatsappUpdates = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _pushNotifications =
          storage.getBool(AppConstants.keyPushNotifications) ?? true;
      _whatsappUpdates =
          storage.getBool(AppConstants.keyWhatsappUpdates) ?? false;
      _prefsLoaded = true;
    });
  }

  Future<void> _setPushNotifications(bool value) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBool(AppConstants.keyPushNotifications, value: value);
    setState(() => _pushNotifications = value);
  }

  Future<void> _setWhatsappUpdates(bool value) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBool(AppConstants.keyWhatsappUpdates, value: value);
    setState(() => _whatsappUpdates = value);
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
                    const Gap(12),
                    AppCard.outlined(
                      padding: EdgeInsets.zero,
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
                          const Divider(height: 1),
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
                          const Divider(height: 1),
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
                    const Gap(28),

                    // ── Notifications ────────────────────────────────────────
                    Text('Notifications', style: AppTypography.titleMedium),
                    const Gap(12),
                    AppCard.outlined(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            title: Text('Push Notifications',
                                style: AppTypography.bodyMedium),
                            subtitle: Text(
                              'Order updates, pickups and delivery alerts',
                              style: AppTypography.caption,
                            ),
                            value: _pushNotifications,
                            activeColor: AppColors.primary,
                            onChanged: _setPushNotifications,
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: Text('WhatsApp Updates',
                                style: AppTypography.bodyMedium),
                            subtitle: Text(
                              'Get order tracking messages on WhatsApp',
                              style: AppTypography.caption,
                            ),
                            value: _whatsappUpdates,
                            activeColor: AppColors.primary,
                            onChanged: _setWhatsappUpdates,
                          ),
                        ],
                      ),
                    ),
                    const Gap(28),

                    // ── App Version ──────────────────────────────────────────
                    Center(
                      child: Text(
                        'LNDRY v1.0.0',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Gap(16),
                  ],
                ),
              ),
      ),
    );
  }
}
