import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/orders_provider.dart';
import '../../../../models/models.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  final _reasonController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Map<String, int> _confirmedQuantities = {};
  bool _isReconciling = false;
  bool _autoOpenedReconcile = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeQuantities(OrderModel order) {
    if (_confirmedQuantities.isEmpty) {
      for (final item in order.items) {
        _confirmedQuantities[item.serviceId] = item.quantity;
      }
    }
  }

  Future<void> _submitReconciliation(OrderModel order) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isReconciling = true);
      try {
        final lines = _confirmedQuantities.entries.map((e) => {
          'garment_type_id': e.key,
          'confirmed_quantity': e.value,
        }).toList();

        final weight = double.tryParse(_weightController.text);
        final notes = _notesController.text.trim();

        await ref.read(ordersListProvider.notifier).reconcile(
          order.id,
          confirmedLines: lines,
          confirmedWeightKg: weight,
          adjustmentReason: notes.isNotEmpty ? notes : 'Receipt reconciliation',
        );

        ref.invalidate(orderDetailsProvider(order.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order successfully reconciled')),
        );
        Navigator.pop(context); // Close sheet
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reconciliation failed: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isReconciling = false);
        }
      }
    }
  }

  void _showReconcileSheet(OrderModel order) {
    _initializeQuantities(order);
    _weightController.text = '';
    _notesController.text = '';

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
                        'Reconcile Order items',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Verify counts and weight of the garments received from customer',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 20.h),

                      // Item List adjusting
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, idx) {
                          final item = order.items[idx];
                          final count = _confirmedQuantities[item.serviceId] ?? item.quantity;
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.serviceName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Est: ${item.quantity}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    onPressed: count > 0
                                        ? () => setSheetState(() => _confirmedQuantities[item.serviceId] = count - 1)
                                        : null,
                                  ),
                                  Text('$count', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                    onPressed: () => setSheetState(() => _confirmedQuantities[item.serviceId] = count + 1),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 20.h),

                      // Weight Input
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Actual Weight (kg) - Optional',
                          hintText: 'e.g. 3.4',
                          prefixIcon: Icon(Icons.scale_rounded),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Adjustment notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Adjustment Note / Reason',
                          hintText: 'e.g. 1 shirt added, dirty collar notes',
                          prefixIcon: Icon(Icons.note_alt_rounded),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      ElevatedButton(
                        onPressed: _isReconciling ? null : () => _submitReconciliation(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: _isReconciling
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                              )
                            : const Text('Reconcile & Update Total'),
                      ),
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

  Future<void> _updateStage(String id, String stage) async {
    try {
      await ref.read(ordersListProvider.notifier).updateStage(id, stage);
      ref.invalidate(orderDetailsProvider(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stage updated to $stage')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptOrder(String id) async {
    try {
      await ref.read(ordersListProvider.notifier).acceptOrder(id);
      ref.invalidate(orderDetailsProvider(id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRejectDialog(String id) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Order'),
          content: TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              hintText: 'e.g. Shop capacity exceeded today',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = _reasonController.text.trim();
                Navigator.pop(context);
                try {
                  await ref.read(ordersListProvider.notifier).rejectOrder(id, reason: reason);
                  ref.invalidate(orderDetailsProvider(id));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected')));
                  context.pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Confirm Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailsProvider(widget.orderId));
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
          'Order Details',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          final statusColor = _getStatusColor(order.status);
          
          if (!_autoOpenedReconcile) {
            final uri = GoRouterState.of(context).uri;
            if (uri.fragment == 'reconcile' || uri.queryParameters['reconcile'] == 'true') {
              _autoOpenedReconcile = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showReconcileSheet(order);
              });
            }
          }
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Header
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                                      style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatDateTime(order.createdAt),
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    order.status.label.toUpperCase(),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Stepper / Timeline summary
                      Text('Lifecycle Stepper', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      _buildTimeline(order.status),
                      SizedBox(height: 24.h),

                      // Customer Info
                      Text('Customer details', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: AppColors.primaryContainer,
                                  child: const Icon(Icons.person, color: AppColors.primary),
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getCustomerDetails(order.customerId)['name']!, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 2.h),
                                    Text(_getCustomerDetails(order.customerId)['phone']!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                    SizedBox(height: 2.h),
                                    Text(_getCustomerDetails(order.customerId)['address']!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
                                      SizedBox(height: 6.h),
                                      Text('Note: ${order.customerNotes}', style: AppTypography.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Garment Items List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Garment Items', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          if ([OrderStatus.receivedAtVendor, OrderStatus.processing].contains(order.status))
                            TextButton.icon(
                              onPressed: () => _showReconcileSheet(order),
                              icon: const Icon(Icons.scale_rounded, size: 16),
                              label: const Text('Reconcile count'),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: order.items.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, idx) {
                                final item = order.items[idx];
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.serviceName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                          Text('Quantity: ${item.quantity}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                      Text('₹${(item.totalPrice / 100).toStringAsFixed(2)}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Divider(thickness: 1.5),
                            SizedBox(height: 8.h),
                            _buildPriceSummaryRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
                            _buildPriceSummaryRow('GST / Taxes', '₹${order.gstAmount.toStringAsFixed(2)}'),
                            _buildPriceSummaryRow('Platform fee', '₹${order.platformFee.toStringAsFixed(2)}'),
                            const Divider(),
                            _buildPriceSummaryRow(
                              'Total Payable',
                              '₹${order.total.toStringAsFixed(2)}',
                              isBold: true,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action panel (sticky)
              _buildBottomActions(order),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading details: $err')),
      ),
    );
  }

  Widget _buildPriceSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: isBold ? FontWeight.bold : null)),
          Text(value, style: AppTypography.bodyLarge.copyWith(color: color, fontWeight: isBold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderStatus status) {
    final stages = ['WAITING', 'ACCEPTED', 'RECEIVED', 'PROCESSING', 'PACKED', 'DELIVERED'];
    final activeIndex = _getStageIndex(status);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stages.length, (index) {
          final isActive = index <= activeIndex;
          final isCurrent = index == activeIndex;
          return Column(
            children: [
              Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isActive
                          ? AppColors.primary.withOpacity(0.5)
                          : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 14.r,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                stages[index],
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : null,
                  color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 9.sp,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  int _getStageIndex(OrderStatus status) {
    if (status == OrderStatus.waitingForVendorConfirmation) return 0;
    if (status == OrderStatus.vendorAccepted || status == OrderStatus.pickupAssigned || status == OrderStatus.goingForPickup || status == OrderStatus.pickupOtpVerified || status == OrderStatus.pickedUp) return 1;
    if (status == OrderStatus.receivedAtVendor) return 2;
    if (status == OrderStatus.processing) return 3;
    if (status == OrderStatus.packed) return 4;
    if (status == OrderStatus.delivered || status == OrderStatus.deliveryOtpVerified) return 5;
    return 0;
  }

  Widget _buildBottomActions(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (order.status == OrderStatus.waitingForVendorConfirmation) {
      return Container(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRejectDialog(order.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Reject Order'),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Accept Order'),
              ),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.receivedAtVendor) {
      return Container(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showReconcileSheet(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Reconcile items'),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStage(order.id, 'WASHING'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Start Processing'),
              ),
            ),
          ],
        ),
      );
    } else if (order.status == OrderStatus.processing) {
      return Container(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showStagePicker(order.id),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Update Stage'),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStage(order.id, 'PACKED'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Mark Packed & Ready'),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showStagePicker(String id) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Update Processing Stage', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.waves),
                title: const Text('Washing'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStage(id, 'WASHING');
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Drying'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStage(id, 'DRYING');
                },
              ),
              ListTile(
                leading: const Icon(Icons.iron_rounded),
                title: const Text('Ironing'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStage(id, 'IRONING');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.waitingForVendorConfirmation => AppColors.warning,
      OrderStatus.vendorAccepted ||
      OrderStatus.pickupAssigned ||
      OrderStatus.goingForPickup ||
      OrderStatus.pickupOtpVerified ||
      OrderStatus.pickedUp =>
        AppColors.primary,
      OrderStatus.receivedAtVendor => Color(0xFF8E2DE2),
      OrderStatus.processing => Color(0xFF4A00E0),
      OrderStatus.packed => AppColors.success,
      OrderStatus.delivered => Colors.green,
      OrderStatus.vendorRejected ||
      OrderStatus.autoRejected ||
      OrderStatus.customerCancelled ||
      OrderStatus.adminCancelled =>
        AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Map<String, String> _getCustomerDetails(String customerId) {
    final hash = customerId.hashCode;
    final firstNames = ['Ramesh', 'Suresh', 'Amit', 'Rajesh', 'Priya', 'Neha', 'Vijay', 'Vikram', 'Anjali', 'Karan', 'Deepak', 'Sanjay', 'Sunita', 'Geeta', 'Rahul', 'Arun'];
    final lastNames = ['Sharma', 'Verma', 'Gupta', 'Patel', 'Kumar', 'Singh', 'Reddy', 'Nair', 'Joshi', 'Mehta', 'Rao', 'Mishra', 'Choudhary', 'Yadav'];
    
    final name = '${firstNames[hash.abs() % firstNames.length]} ${lastNames[hash.abs() % lastNames.length]}';
    final phones = ['+91 98765 43210', '+91 98234 56789', '+91 99123 45678', '+91 91765 43219', '+91 88765 43211', '+91 77654 32109'];
    final phone = phones[hash.abs() % phones.length];
    
    final addresses = [
      'Flat 402, Sai Residency, Madhapur, Hyderabad',
      'Plot 12, Road No 4, Jubilee Hills, Hyderabad',
      'Villa 9, Green Meadows, Gachibowli, Hyderabad',
      'Flat 102, Block B, Rainbow Apartments, Kondapur, Hyderabad',
      'Door 4-3-12, Banjara Hills, Hyderabad',
      'Flat 503, Elegance Heights, Begumpet, Hyderabad'
    ];
    final address = addresses[hash.abs() % addresses.length];
    
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
