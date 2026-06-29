import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSaveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        
        // Simulating profile update
        await ref.read(authProvider.notifier).completeProfile(
              name: name,
              email: email,
            );
            
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackBar.showSuccess(context, 'Profile updated successfully.');
          context.go(AppRoutes.profile);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackBar.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Saving changes...')
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h * 1.5,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sibling profile mockup avatar selector
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56.r,
                              backgroundColor: AppColors.primaryContainer,
                              child: Icon(
                                AppIcons.profile,
                                size: 48.r,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  AppIcons.camera,
                                  color: AppColors.white,
                                  size: 16.r,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(40),

                      // Input Name details
                      AppTextField(
                        label: 'Full Name',
                        hint: 'Enter your name',
                        controller: _nameController,
                        prefixIcon: const Icon(AppIcons.profile),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const Gap(20),

                      // Input Email details
                      AppTextField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        prefixIcon: const Icon(AppIcons.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Gap(48),

                      // Save changes button
                      AppButton(
                        label: 'Save Changes',
                        onPressed: _onSaveChanges,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
