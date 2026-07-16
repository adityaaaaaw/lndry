class PickupSlotModel {
  const PickupSlotModel({
    required this.id,
    required this.vendorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.maxOrders,
    this.isActive = true,
  });

  final String id;
  final String vendorId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int maxOrders;
  final bool isActive;

  factory PickupSlotModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    return PickupSlotModel(
      id: json['id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
      dayOfWeek: toInt(json['day_of_week'] ?? json['dayOfWeek'], 0),
      startTime: json['start_time'] as String? ?? json['startTime'] as String? ?? '',
      endTime: json['end_time'] as String? ?? json['endTime'] as String? ?? '',
      maxOrders: toInt(json['max_orders'] ?? json['maxOrders'], 5),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'max_orders': maxOrders,
      'is_active': isActive,
    };
  }
}
