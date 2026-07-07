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

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  Future<void> _updateCapacity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingCapacity = true);
      try {
        final limit = int.parse(_capacityController.text);
        final repo = ref.read(vendorRepositoryProvider);
        await repo.updateCapacityDailyLimit(limit);
        ref.invalidate(dailyCapacityProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily capacity limit updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update capacity: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdatingCapacity = false);
        }
      }
    }
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

  void _showAddOrEditSlotSheet({PickupSlotModel? existingSlot}) {
    final isEdit = existingSlot != null;
    if (isEdit) {
      _startController.text = existingSlot.startTime;
      _endController.text = existingSlot.endTime;
      _maxOrdersController.text = existingSlot.maxOrders.toString();
      _selectedDay = existingSlot.dayOfWeek;
    } else {
      _startController.clear();
      _endController.clear();
      _maxOrdersController.text = '5';
      _selectedDay = 1; // Monday
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
                key: _slotFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEdit ? 'Edit Pickup Time Slot' : 'Add Pickup Time Slot',
                      style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),

                    // Day of Week Selection
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
                              hintText: 'e.g. 09:00',
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
                              hintText: 'e.g. 12:00',
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
                      onPressed: _isSavingSlot ? null : () => _saveSlot(setSheetState, existingSlot),
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
                          : Text(isEdit ? 'Update Slot' : 'Save Slot'),
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

  Future<void> _saveSlot(StateSetter setSheetState, PickupSlotModel? existingSlot) async {
    if (_slotFormKey.currentState!.validate()) {
      setSheetState(() => _isSavingSlot = true);
      try {
        final startMin = _timeToMinutes(_startController.text);
        final endMin = _timeToMinutes(_endController.text);

        // 1. Validate Closing time is after opening time
        if (endMin <= startMin) {
          throw 'Closing time must be after opening time.';
        }

        // 2. Validate Slot stays inside working hours
        final workingHours = ref.read(workingHoursProvider).value;
        if (workingHours != null) {
          final dayHours = workingHours[_selectedDay];
          if (dayHours != null) {
            final dayOpen = dayHours['isOpen'] as bool? ?? false;
            if (!dayOpen) {
              throw 'The selected day is closed under Working Hours.';
            }
            final openLimit = _timeToMinutes(dayHours['openTime'] as String? ?? '08:00');
            final closeLimit = _timeToMinutes(dayHours['closeTime'] as String? ?? '20:00');
            if (startMin < openLimit || endMin > closeLimit) {
              throw 'Slot times must be within operational working hours (${dayHours['openTime']} to ${dayHours['closeTime']}).';
            }
          }
        }

        // 3. Validate No overlapping slots for same day
        final allSlots = ref.read(slotsListProvider).value ?? [];
        for (final s in allSlots) {
          if (existingSlot != null && s.id == existingSlot.id) continue;
          if (s.dayOfWeek == _selectedDay && s.isActive) {
            final sMin = _timeToMinutes(s.startTime);
            final eMin = _timeToMinutes(s.endTime);
            if (startMin < eMin && endMin > sMin) {
              throw 'This slot overlaps with an existing slot: ${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)} on ${_daysOfWeek[_selectedDay]}.';
            }
          }
        }

        final maxOrders = int.parse(_maxOrdersController.text);
        final repo = ref.read(vendorRepositoryProvider);

        if (existingSlot != null) {
          // Editing existing slot:
          // We have to recreate the slot locally in repo or call update.
          // Wait, updatePickupSlot takes id and updates active or capacity, but we can also recreate it.
          // Let's call updatePickupSlot inside notifier or delete and create.
          // Wait, our notifier.updateCapacity can do capacity, let's call that or rewrite a general update slot!
          await repo.deletePickupSlot(existingSlot.id);
        }

        await ref.read(slotsListProvider.notifier).addSlot(
          dayOfWeek: _selectedDay,
          startTime: _startController.text,
          endTime: _endController.text,
          maxOrders: maxOrders,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(existingSlot != null ? 'Slot updated successfully' : 'Pickup slot added')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      } finally {
        setSheetState(() => _isSavingSlot = false);
      }
    }
  }

  Future<void> _toggleSlot(PickupSlotModel slot, bool isActive) async {
    try {
      await ref.read(slotsListProvider.notifier).toggleSlot(slot.id, isActive);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await ref.read(slotsListProvider.notifier).removeSlot(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _selectWorkingHoursTime(BuildContext context, int day, bool isOpenTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      final timeStr = '$hh:$mm';
      
      final current = ref.read(workingHoursProvider).value?[day];
      if (current != null) {
        final openVal = isOpenTime ? timeStr : (current['openTime'] as String? ?? '08:00');
        final closeVal = isOpenTime ? (current['closeTime'] as String? ?? '20:00') : timeStr;
        final isOpen = current['isOpen'] as bool? ?? false;
        
        if (_timeToMinutes(closeVal) <= _timeToMinutes(openVal)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Closing time must be after opening time.'), backgroundColor: AppColors.error),
          );
          return;
        }

        await ref.read(workingHoursProvider.notifier).updateHours(
          day,
          isOpen: isOpen,
          openTime: openVal,
          closeTime: closeVal,
        );
      }
    }
  }

  Future<void> _toggleWorkingDay(int day, bool val) async {
    final current = ref.read(workingHoursProvider).value?[day];
    if (current != null) {
      await ref.read(workingHoursProvider.notifier).updateHours(
        day,
        isOpen: val,
        openTime: current['openTime'] as String? ?? '08:00',
        closeTime: current['closeTime'] as String? ?? '20:00',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final capacityAsync = ref.watch(dailyCapacityProvider);
    final slotsAsync = ref.watch(slotsListProvider);
    final workingHoursAsync = ref.watch(workingHoursProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(AppRoutes.dashboard);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.white : AppColors.textBlack),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.dashboard),
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
          ref.invalidate(workingHoursProvider);
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Working Hours Configuration Section (Issue 1 & 10) ──────────
              Text('Operational Working Hours', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
                ),
                child: workingHoursAsync.when(
                  data: (hoursMap) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.1)),
                    itemBuilder: (ctx, idx) {
                      final dayData = hoursMap[idx] ?? {'isOpen': true, 'openTime': '08:00', 'closeTime': '20:00'};
                      final isOpen = dayData['isOpen'] as bool? ?? false;
                      final openTime = dayData['openTime'] as String? ?? '08:00';
                      final closeTime = dayData['closeTime'] as String? ?? '20:00';

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 90.w,
                              child: Text(_daysOfWeek[idx], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            Switch(
                              value: isOpen,
                              onChanged: (val) => _toggleWorkingDay(idx, val),
                              activeColor: AppColors.success,
                            ),
                            if (isOpen) ...[
                              InkWell(
                                onTap: () => _selectWorkingHoursTime(context, idx, true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(openTime, style: AppTypography.bodySmall),
                                ),
                              ),
                              Text('to', style: AppTypography.bodySmall),
                              InkWell(
                                onTap: () => _selectWorkingHoursTime(context, idx, false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(closeTime, style: AppTypography.bodySmall),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: Center(
                                  child: Text('Closed', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
              SizedBox(height: 24.h),

              // ── Daily capacity limit settings card ──────────────────────────
              Text('Daily Capacity Limit', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
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
                          error: (err, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Error loading: $err', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                              TextButton(
                                onPressed: () => ref.invalidate(dailyCapacityProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton(
                        onPressed: _isUpdatingCapacity ? null : _updateCapacity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 48),
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

              // ── Pickup Slots Schedule List ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Slots Schedule', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    onPressed: () => _showAddOrEditSlotSheet(),
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
                          side: BorderSide(color: AppColors.outline.withValues(alpha: isDark ? 0.05 : 0.2)),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _daysOfWeek[slot.dayOfWeek],
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.white : AppColors.textBlack,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _showAddOrEditSlotSheet(existingSlot: slot),
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
                error: (err, _) => Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Text('Error: $err'),
                      TextButton(
                        onPressed: () => ref.invalidate(slotsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
