import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/repositories.dart';

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
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      // Fix: use updateAuthenticatedUser (not completeProfile).
      // completeProfile is only for the onboarding flow and triggers
      // AuthNeedsLocationPermission, which would kick authenticated users
      // back through the onboarding funnel.
      await ref.read(authProvider.notifier).updateAuthenticatedUser(
            name: name,
            email: email,
          );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Profile updated successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) {
        if (mounted) setState(() => _isUploadingAvatar = false);
        return;
      }
      final avatarUrl =
          await ref.read(customerRepositoryProvider).uploadAvatar(image.path);
      if (avatarUrl.isEmpty) {
        throw Exception('Avatar upload did not return a URL.');
      }
      await ref
          .read(authProvider.notifier)
          .updateAuthenticatedAvatar(avatarUrl);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Profile photo updated.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
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
          onPressed: () => context.pop(),
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
                      // Avatar with camera button (functional tap area)
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56.r,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage:
                                  (ref.watch(currentUserProvider)?.avatarUrl !=
                                              null &&
                                          ref
                                              .watch(currentUserProvider)!
                                              .avatarUrl!
                                              .isNotEmpty)
                                      ? NetworkImage(ref
                                          .watch(currentUserProvider)!
                                          .avatarUrl!)
                                      : null,
                              child:
                                  (ref.watch(currentUserProvider)?.avatarUrl ==
                                              null ||
                                          ref
                                              .watch(currentUserProvider)!
                                              .avatarUrl!
                                              .isEmpty)
                                      ? Icon(
                                          AppIcons.profile,
                                          size: 48.r,
                                          color: AppColors.primary,
                                        )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingAvatar
                                    ? null
                                    : _pickAndUploadAvatar,
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isUploadingAvatar
                                      ? SizedBox(
                                          width: 16.r,
                                          height: 16.r,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : Icon(
                                          AppIcons.camera,
                                          color: AppColors.white,
                                          size: 16.r,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(40),

                      AppTextField(
                        label: 'Full Name',
                        hint: 'Enter your name',
                        controller: _nameController,
                        prefixIcon: const Icon(AppIcons.profile),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const Gap(20),

                      AppTextField(
                        label: 'Email Address',
                        hint: 'Enter your email (optional)',
                        controller: _emailController,
                        prefixIcon: const Icon(AppIcons.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Gap(48),

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
