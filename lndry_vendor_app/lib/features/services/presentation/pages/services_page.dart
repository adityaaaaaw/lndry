import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/services_provider.dart';
import '../../../../models/models.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();
  ServiceCategory _selectedCategory = ServiceCategory.wash;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showServiceForm({ServiceModel? existing}) {
    if (existing != null) {
      _nameController.text = existing.name;
      _descController.text = existing.description;
      _priceController.text = existing.pricePerPiece?.toString() ?? '';
      _weightController.text = existing.minWeightKg.toString();
      _selectedCategory = existing.category;
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _weightController.text = '1.0';
      _selectedCategory = ServiceCategory.wash;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 24.h,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existing != null ? 'Edit Service' : 'Add Service Offer',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16.h),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Service Name',
                          hintText: 'e.g. Premium Ironing',
                          prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                      ),
                      SizedBox(height: 12.h),

                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g. Wrinkle-free steam press and steam hanger',
                          prefixIcon: Icon(Icons.description_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
                      ),
                      SizedBox(height: 12.h),

                      // Category Dropdown
                      DropdownButtonFormField<ServiceCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.layers_rounded),
                        ),
                        items: ServiceCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price per Piece (₹)',
                                hintText: 'e.g. 15.00',
                                prefixIcon: Icon(Icons.currency_rupee_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Price is required';
                                if (double.tryParse(value) == null) return 'Invalid amount';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Min Weight (kg)',
                                hintText: 'e.g. 1.0',
                                prefixIcon: Icon(Icons.scale_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (double.tryParse(value) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveService(existing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                              )
                            : Text(existing != null ? 'Update Service' : 'Create Service'),
                      ),
                      if (existing != null) ...[
                        SizedBox(height: 12.h),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : () => _deleteService(existing.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete Service'),
                        ),
                      ],
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveService(ServiceModel? existing) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final price = double.parse(_priceController.text);
        final minWeight = double.parse(_weightController.text);

        final service = ServiceModel(
          id: existing?.id ?? '',
          vendorId: existing?.vendorId ?? '',
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory,
          pricePerPiece: price,
          minWeightKg: minWeight,
          isAvailable: existing?.isAvailable ?? true,
        );

        if (existing != null) {
          await ref.read(servicesListProvider.notifier).updateService(service);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service updated')));
        } else {
          await ref.read(servicesListProvider.notifier).addService(service);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service created')));
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: const Text('Are you sure you want to delete this service offering? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(servicesListProvider.notifier).deleteService(id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service deleted')));
        Navigator.pop(context); // Close bottom sheet
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _toggleAvailability(ServiceModel service, bool val) async {
    try {
      await ref.read(servicesListProvider.notifier).toggleAvailability(service.id, val);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        title: Text(
          'Service Management',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_rupee_rounded),
            tooltip: 'Garment Pricing Rates',
            onPressed: () => context.push(AppRoutes.pricing),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(servicesListProvider.notifier).fetchServices(),
        color: AppColors.primary,
        child: servicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64.r, color: AppColors.textSecondary.withOpacity(0.3)),
                      SizedBox(height: 16.h),
                      Text(
                        'No Services Found',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Create your first laundry offering by tapping the button below.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: services.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, idx) {
                final service = services[idx];
                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: AppColors.outline.withOpacity(isDark ? 0.05 : 0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    title: Row(
                      children: [
                        Text(
                          service.name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.textBlack,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            service.category.label,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          service.description,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Price: ₹${service.pricePerPiece?.toStringAsFixed(2) ?? "0.00"} • Min Weight: ${service.minWeightKg}kg',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: service.isAvailable,
                      onChanged: (val) => _toggleAvailability(service, val),
                      activeColor: AppColors.success,
                    ),
                    onTap: () => _showServiceForm(existing: service),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Failed to load services: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
