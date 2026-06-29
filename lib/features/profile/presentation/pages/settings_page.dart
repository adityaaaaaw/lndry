import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _whatsappUpdates = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Watch active theme mode state from theme provider
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('App Settings', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH.w,
            vertical: AppSpacing.pagePaddingV.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Preferences', style: AppTypography.titleMedium),
              const Gap(12),

              // Theme Selector card
              AppCard.outlined(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('System Default Theme', style: AppTypography.bodyMedium),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setTheme(val);
                          AppSnackBar.showSuccess(context, 'Theme mode updated to System.');
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: Text('Light Mode Theme', style: AppTypography.bodyMedium),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setTheme(val);
                          AppSnackBar.showSuccess(context, 'Theme mode updated to Light.');
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark Mode Theme', style: AppTypography.bodyMedium),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setTheme(val);
                          AppSnackBar.showSuccess(context, 'Theme mode updated to Dark.');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Gap(24),

              Text('Alerts & Updates', style: AppTypography.titleMedium),
              const Gap(12),

              // Notification Settings
              AppCard.outlined(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text('Push Notifications', style: AppTypography.bodyMedium),
                      subtitle: Text('Receive alerts on status and pickups', style: AppTypography.caption),
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: Text('WhatsApp Updates', style: AppTypography.bodyMedium),
                      subtitle: Text('Get direct order tracking on WhatsApp', style: AppTypography.caption),
                      value: _whatsappUpdates,
                      onChanged: (val) => setState(() => _whatsappUpdates = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
