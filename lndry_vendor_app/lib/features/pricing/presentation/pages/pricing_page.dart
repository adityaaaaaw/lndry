import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/services_provider.dart';
import '../../../../repositories/repositories.dart';
import '../../../../models/models.dart';

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({super.key});

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  String? _selectedServiceId;
  Map<String, dynamic>? _serviceDetails;
  bool _isLoadingDetails = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  String _rateUnit = 'piece';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceDetails(String serviceId) async {
    setState(() => _isLoadingDetails = true);
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final details = await repo.getServiceDetails(serviceId);
      setState(() {
        _serviceDetails = details;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rates: $e')),
      );
    }
  }

  void _showAddRateForm() {
    if (_selectedServiceId == null) return;
    _nameController.clear();
    _rateController.clear();
    _rateUnit = 'piece';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Garment Price Rate'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Garment Name',
                        hintText: 'e.g. Saree, Silk Shirt, Bedsheet',
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Rate (₹)',
                              hintText: 'e.g. 45.00',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _rateUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: const [
                              DropdownMenuItem(value: 'piece', child: Text('Piece')),
                              DropdownMenuItem(value: 'kg', child: Text('Kg')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => _rateUnit = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveGarmentRate(setDialogState),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isSaving
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                        )
                      : const Text('Add Rate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveGarmentRate(StateSetter setDialogState) async {
    if (_formKey.currentState!.validate()) {
      setDialogState(() => _isSaving = true);
      try {
        final rate = double.parse(_rateController.text);
        final repo = ref.read(vendorRepositoryProvider);

        await repo.addGarmentRate(
          _selectedServiceId!,
          garmentTypeName: _nameController.text.trim(),
          rate: rate,
          rateUnit: _rateUnit,
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate added successfully')));
        await _fetchServiceDetails(_selectedServiceId!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setDialogState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteRate(String garmentRateId) async {
    try {
      final repo = ref.read(vendorRepositoryProvider);
      await repo.deleteGarmentRate(_selectedServiceId!, garmentRateId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate deleted')));
      await _fetchServiceDetails(_selectedServiceId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete rate: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/profile');
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.white : AppColors.textBlack),
            onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          ),
        title: Text(
          'Garment Pricing Rates',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: const Text('Please create a laundry service offering first to configure custom pricing rates.'),
              ),
            );
          }

          // Set default selected service if not set
          if (_selectedServiceId == null && services.isNotEmpty) {
            _selectedServiceId = services.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchServiceDetails(_selectedServiceId!);
            });
          }

          final selectedService = services.firstWhere((s) => s.id == _selectedServiceId);

          return Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Dropdown Selector
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedServiceId,
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.white,
                      items: services.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${s.name} (${s.category.label})',
                            style: TextStyle(
                              color: isDark ? AppColors.white : AppColors.textBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedServiceId = val);
                          _fetchServiceDetails(val);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Garment Rates List
                Expanded(
                  child: _isLoadingDetails
                      ? const Center(child: CircularProgressIndicator())
                      : _serviceDetails == null
                          ? const Center(child: Text('Select a service to display pricing rules.'))
                          : _buildGarmentRatesList(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading services: $err')),
      ),
      floatingActionButton: _selectedServiceId != null
          ? FloatingActionButton.extended(
              onPressed: _showAddRateForm,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Garment Rate'),
            )
          : null,
      ),
    );
  }

  Widget _buildGarmentRatesList() {
    final list = _serviceDetails?['garments'] as List<dynamic>? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on_outlined, size: 48.r, color: AppColors.textSecondary.withOpacity(0.3)),
              SizedBox(height: 12.h),
              const Text('No garment pricing rates configured for this service yet.'),
              SizedBox(height: 4.h),
              const Text('Tap add to define rate rules for different garments (Shirt, Jeans, etc.)'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, idx) {
        final rate = list[idx] as Map<String, dynamic>;
        final garmentName = rate['garment_name'] as String? ?? 'Unknown';
        final ratePaise = (rate['rate_paise'] is num ? (rate['rate_paise'] as num).toDouble() : double.tryParse(rate['rate_paise']?.toString() ?? '')) ?? 0.0;
        final unit = rate['unit'] as String? ?? 'piece';
        final garmentTypeId = rate['garment_rate_id'] as String? ?? '';

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
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.checkroom_rounded, color: AppColors.primary),
            ),
            title: Text(
              garmentName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textBlack,
              ),
            ),
            subtitle: Text('Unit billing: per $unit'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${(ratePaise / 100).toStringAsFixed(2)}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _deleteRate(garmentTypeId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
