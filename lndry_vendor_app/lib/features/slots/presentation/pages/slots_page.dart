import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/slots_provider.dart';
import '../../../../repositories/repositories.dart';
import '../../../../models/models.dart';

class SlotsPage extends ConsumerStatefulWidget {
  const SlotsPage({super.key});

  @override
  ConsumerState<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends ConsumerState<SlotsPage> {
  final _capacityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _slotFormKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _maxOrdersController = TextEditingController();
  int _selectedDay = 1; // 1 = Monday
  bool _isUpdatingCapacity = false;
  bool _isSavingSlot = false;

  final List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void dispose() {
    _capacityController.dispose();
    _startController.dispose();
    _endController.dispose();
    _maxOrdersController.dispose();
    super.dispose();
  }

  Future<void> _updateCapacity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingCapacity = true);
      try {
        final limit = int.parse(_capacityController.text);
        final repo = ref.read(vendorRepositoryProvider);
        await repo.updateCapacityDailyLimit(limit);
        ref.invalidate(dailyCapacityProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily capacity limit updated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update capacity: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isUpdatingCapacity = false);
        }
      }
    }
  }

  void _showAddSlotSheet() {
    _startController.clear();
    _endController.clear();
    _maxOrdersController.text = '5';
    _selectedDay = 1; // Monday

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
                key: _slotFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Pickup Time Slot',
                      style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),

                    // Day of Week
                    DropdownButtonFormField<int>(
                      value: _selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      items: List.generate(7, (idx) {
                        return DropdownMenuItem(
                          value: idx,
                          child: Text(_daysOfWeek[idx]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _selectedDay = val);
                        }
                      },
                    ),
                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              hintText: 'e.g. 09:00 AM',
                              prefixIcon: Icon(Icons.alarm_rounded),
                            ),
                            onTap: () => _selectTime(context, _startController),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            controller: _endController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              hintText: 'e.g. 12:00 PM',
                              prefixIcon: Icon(Icons.alarm_on_rounded),
                            ),
                            onTap: () => _selectTime(context, _endController),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    TextFormField(
                      controller: _maxOrdersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Orders Limit',
                        hintText: 'e.g. 5',
                        prefixIcon: Icon(Icons.filter_9_plus_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    ElevatedButton(
                      onPressed: _isSavingSlot ? null : () => _saveSlot(setSheetState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: _isSavingSlot
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : const Text('Save Slot'),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (mounted) {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        controller.text = '$hh:$mm:00';
      }
    }
  }

  Future<void> _saveSlot(StateSetter setSheetState) async {
    if (_slotFormKey.currentState!.validate()) {
      setSheetState(() => _isSavingSlot = true);
      try {
        final maxOrders = int.parse(_maxOrdersController.text);
        await ref.read(slotsListProvider.notifier).addSlot(
          dayOfWeek: _selectedDay,
          startTime: _startController.text,
          endTime: _endController.text,
          maxOrders: maxOrders,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup slot added')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setSheetState(() => _isSavingSlot = false);
      }
    }
  }

  Future<void> _toggleSlot(PickupSlotModel slot, bool isActive) async {
    try {
      await ref.read(slotsListProvider.notifier).toggleSlot(slot.id, isActive);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await ref.read(slotsListProvider.notifier).removeSlot(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capacityAsync = ref.watch(dailyCapacityProvider);
    final slotsAsync = ref.watch(slotsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.white : AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Working Hours & Slots',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyCapacityProvider);
          ref.invalidate(slotsListProvider);
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Daily limit capacity setup card
              Text('Daily Capacity Limit', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                ),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: capacityAsync.when(
                          data: (cap) {
                            final maxOrders = cap['max_orders_per_day'] ?? cap['maxOrdersPerDay'] ?? 20;
                            if (_capacityController.text.isEmpty) {
                              _capacityController.text = maxOrders.toString();
                            }
                            return TextFormField(
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Orders per Day',
                                hintText: 'e.g. 20',
                                prefixIcon: Icon(Icons.dashboard_customize_rounded),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Error loading capacity limit: $err'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton(
                        onPressed: _isUpdatingCapacity ? null : _updateCapacity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        ),
                        child: _isUpdatingCapacity
                            ? SizedBox(
                                width: 16.r,
                                height: 16.r,
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                              )
                            : const Text('Update'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Pickup slots list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Slots Schedule', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    onPressed: _showAddSlotSheet,
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              slotsAsync.when(
                data: (slots) {
                  if (slots.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(32.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: const Center(
                        child: Text('No custom slots configured. Tap "+" to add working hours.'),
                      ),
                    );
                  }

                  // Sort slots by day then start time
                  slots.sort((a, b) {
                    final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
                    if (dayCompare != 0) return dayCompare;
                    return a.startTime.compareTo(b.startTime);
                  });

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: slots.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final slot = slots[index];
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
                          title: Row(
                            children: [
                              Text(
                                _daysOfWeek[slot.dayOfWeek],
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
                                  'Max ${slot.maxOrders} orders',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('${slot.startTime.substring(0, 5)} - ${slot.endTime.substring(0, 5)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: slot.isActive,
                                onChanged: (val) => _toggleSlot(slot, val),
                                activeColor: AppColors.success,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                onPressed: () => _deleteSlot(slot.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading slots: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
