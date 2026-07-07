import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
  });

  final String id;
  final String name;
  int quantity;
  final int minThreshold;
  final String unit;
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final List<InventoryItem> _items = [
    InventoryItem(id: '1', name: 'Liquid Detergent', quantity: 24, minThreshold: 5, unit: 'Liters'),
    InventoryItem(id: '2', name: 'Fabric Softener', quantity: 15, minThreshold: 4, unit: 'Liters'),
    InventoryItem(id: '3', name: 'Premium Bleach', quantity: 3, minThreshold: 5, unit: 'Liters'),
    InventoryItem(id: '4', name: 'Metal Steam Hangers', quantity: 120, minThreshold: 30, unit: 'Pieces'),
    InventoryItem(id: '5', name: 'Plastic Packing Bags', quantity: 450, minThreshold: 100, unit: 'Pieces'),
    InventoryItem(id: '6', name: 'Starch Spray', quantity: 2, minThreshold: 3, unit: 'Cans'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _thresholdController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    _nameController.clear();
    _qtyController.clear();
    _thresholdController.clear();
    _unitController.text = 'Pieces';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Supply Item'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Collar Scrub'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Initial Qty'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextFormField(
                          controller: _thresholdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Min Limit'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit', hintText: 'e.g. Liters, Bags, Cans'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _items.add(InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          quantity: int.parse(_qtyController.text),
          minThreshold: int.parse(_thresholdController.text),
          unit: _unitController.text.trim(),
        ));
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added to inventory')));
    }
  }

  void _adjustQty(int index, int change) {
    setState(() {
      final item = _items[index];
      final newQty = item.quantity + change;
      if (newQty >= 0) {
        item.quantity = newQty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lowStockItems = _items.where((i) => i.quantity <= i.minThreshold).toList();

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
          'Operational Supplies',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Low Stock Alerts summary Banner
          if (lowStockItems.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.all(16.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Stock Warning',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${lowStockItems.length} supplies are running low. Please order soon.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: _items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, idx) {
                final item = _items[idx];
                final isLowStock = item.quantity <= item.minThreshold;
                final statusColor = isLowStock
                    ? (item.quantity == 0 ? AppColors.error : AppColors.warning)
                    : AppColors.success;

                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: AppColors.outline.withOpacity(isDark ? 0.05 : 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.white : AppColors.textBlack,
                                    ),
                                  ),
                                  if (isLowStock) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Text(
                                        item.quantity == 0 ? 'OUT' : 'LOW',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${item.quantity} / ${item.minThreshold} ${item.unit} (Min limit)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Increment/Decrement Counters
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: () => _adjustQty(idx, -1),
                            ),
                            Container(
                              constraints: BoxConstraints(minWidth: 32.w),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.white : AppColors.textBlack,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                              onPressed: () => _adjustQty(idx, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
