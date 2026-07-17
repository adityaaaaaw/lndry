import fs from 'fs';

const file = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/lib/features/profile/presentation/pages/settings_page.dart';
let content = fs.readFileSync(file, 'utf8');

// 1. Add imports
content = content.replace(
  `import '../../../../repositories/repositories.dart';`,
  `import '../../../../repositories/repositories.dart';\nimport '../../../../providers/auth_provider.dart';\nimport '../../../../core/services/storage_service.dart';\nimport '../../../../config/env.dart';`
);

// 2. Replace _loadPrefs
content = content.replace(
  `  Future<void> _loadPrefs() async {
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
  }`,
  `  Future<void> _loadPrefs() async {
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
  }`
);

// 3. Replace _updateNotificationPrefs
content = content.replace(
  `  Future<void> _updateNotificationPrefs({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryUpdates,
    bool? priceDrops,
  }) async {
    setState(() => _isSavingPrefs = true);
    try {
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
  }`,
  `  Future<void> _updateNotificationPrefs({
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
  }`
);

fs.writeFileSync(file, content, 'utf8');
console.log('Successfully re-applied guest Settings preferences!');
