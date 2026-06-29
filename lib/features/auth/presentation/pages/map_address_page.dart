import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../models/models.dart';
import '../../../../providers/auth_provider.dart';

class MapAddressPage extends ConsumerStatefulWidget {
  const MapAddressPage({super.key});

  @override
  ConsumerState<MapAddressPage> createState() => _MapAddressPageState();
}

class _MapAddressPageState extends ConsumerState<MapAddressPage> {
  final _addressLineController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _selectedCity = 'Bengaluru';
  String _selectedState = 'Karnataka';
  AddressType _selectedType = AddressType.home;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default mock address coordinates
    _addressLineController.text = 'Flat 402, Pebble Creek Apartments';
    _pincodeController.text = '560103';
    _landmarkController.text = 'Near Outer Ring Road';
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onSaveAddress() async {
    final line1 = _addressLineController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (line1.isEmpty || pincode.isEmpty) {
      AppSnackBar.showError(context, 'Please complete the address details.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? 'usr_demo';

      final mockAddress = AddressModel(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        line1: line1,
        line2: _landmarkController.text.trim(),
        city: _selectedCity,
        state: _selectedState,
        pincode: pincode,
        type: _selectedType,
        isDefault: true,
        coordinates: const LatLng(
          latitude: 12.9716,
          longitude: 77.5946,
        ),
      );

      await ref.read(authProvider.notifier).completeAddressSelection(mockAddress);
      
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Address saved as default.');
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Select Delivery Location',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Mock container
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    color: isDark ? AppColors.darkSurfaceContainer : AppColors.outlineVariant,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.map,
                            size: 80.r,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                          const Gap(16),
                          Text(
                            'Google Maps Mock View',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Drag map to pin your precise location',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pin icon overlay
                  Positioned(
                    child: Icon(
                      AppIcons.location,
                      size: 40.r,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Form container
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePaddingH.w,
                vertical: AppSpacing.pagePaddingV.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.dialog.r),
                ),
                boxShadow: AppElevation.high,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Location Details',
                    style: AppTypography.titleMedium,
                  ),
                  const Gap(16),

                  // Address line input
                  AppTextField(
                    label: 'Flat / Building / House No.',
                    hint: 'Enter your flat/house details',
                    controller: _addressLineController,
                  ),
                  const Gap(12),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Pincode',
                          hint: '6 digits',
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: AppTextField(
                          label: 'Landmark',
                          hint: 'e.g., Near park',
                          controller: _landmarkController,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Address type selector
                  Text(
                    'Save Address As',
                    style: AppTypography.labelMedium,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _TypeButton(
                        label: 'Home',
                        icon: AppIcons.homeOutlined,
                        isSelected: _selectedType == AddressType.home,
                        onTap: () => setState(() => _selectedType = AddressType.home),
                      ),
                      const Gap(12),
                      _TypeButton(
                        label: 'Work',
                        icon: AppIcons.store,
                        isSelected: _selectedType == AddressType.work,
                        onTap: () => setState(() => _selectedType = AddressType.work),
                      ),
                      const Gap(12),
                      _TypeButton(
                        label: 'Other',
                        icon: AppIcons.locationOutlined,
                        isSelected: _selectedType == AddressType.other,
                        onTap: () => setState(() => _selectedType = AddressType.other),
                      ),
                    ],
                  ),
                  const Gap(24),

                  // Action CTA
                  AppButton(
                    label: 'Confirm Address',
                    isLoading: _isLoading,
                    onPressed: _onSaveAddress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppButton.outlined(
        label: label,
        icon: Icon(icon, size: 16.r, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        foregroundColor: isSelected ? AppColors.primary : AppColors.textSecondary,
        onPressed: onTap,
      ),
    );
  }
}
