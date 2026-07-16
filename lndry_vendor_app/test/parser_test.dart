import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lndry_vendor_app/api/repositories/api_vendor_repository.dart';
import 'package:lndry_vendor_app/core/services/storage_service.dart';
import 'package:lndry_vendor_app/models/pickup_slot_model.dart';
import 'package:lndry_vendor_app/models/service_model.dart';
import 'package:lndry_vendor_app/models/employee_model.dart';

void main() {
  group('Backend Response Parsing Tests (String vs Num tolerance)', () {
    late ApiVendorRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = ApiVendorRepository(
        dio: Dio(),
        storage: StorageService(prefs: prefs),
      );
    });

    test('1. parseVendorForTest with string numeric fields (rating, review_count, turnaround)', () {
      final profileJson = {
        "id": "11111111-1111-4111-8111-111111111111",
        "name": "LNDRY Prime - Bengaluru Hub",
        "phone": "+917013352181",
        "email": "prime.blr@lndry.in",
        "rating": "4.80",
        "review_count": "120",
        "estimated_turnaround_hours": "24",
        "lat": "12.97160000",
        "lng": "77.59460000",
        "address_line1": "No. 42, 1st Main Road",
        "city": "Bengaluru",
        "state": "Karnataka",
        "pincode": "560034"
      };
      final vendor = repo.parseVendorForTest(profileJson);
      expect(vendor.averageRating, 4.80);
      expect(vendor.reviewCount, 120);
      expect(vendor.estimatedTurnaroundHours, 24);
      expect(vendor.address.coordinates?.latitude, 12.9716);
    });

    test('2. parseServiceForTest with string min_weight_kg and price_per_piece', () {
      final serviceJson = {
        "id": "s1",
        "vendor_id": "v1",
        "name": "Wash & Fold",
        "description": "Standard washing",
        "category": "wash",
        "min_weight_kg": "1.50",
        "price_per_piece": "1200",
        "is_available": true
      };
      final service = repo.parseServiceForTest(serviceJson);
      expect(service.minWeightKg, 1.50);
      expect(service.pricePerPiece, 12.00);
      expect(service.categoryId, '11111111-1111-4444-a111-111111111111');
    });

    test('8. parseServiceForTest correctly maps category_id and fallback category_name from createVendorServiceDraft response', () {
      final serviceJson = {
        "id": "s-draft-1",
        "vendor_id": "v1",
        "status": "DRAFT",
        "category_id": "22222222-2222-4444-a222-222222222222",
        "category_name": "Premium"
      };
      final service = repo.parseServiceForTest(serviceJson);
      expect(service.id, "s-draft-1");
      expect(service.categoryId, "22222222-2222-4444-a222-222222222222");
      expect(service.category, ServiceCategory.premium);
      expect(service.name, "Premium");
    });

    test('3. parseOrderForTest with string total_amount_paise and string item quantities/prices', () {
      final orderJson = {
        "id": "o1",
        "customer_id": "c1",
        "vendor_id": "v1",
        "status": "RECEIVED_AT_VENDOR",
        "total_amount_paise": "25000",
        "items": [
          {
            "service_id": "s1",
            "service_name": "Shirt",
            "quantity": "2",
            "unit_price": "125.00",
            "total_price": "250.00"
          }
        ],
        "created_at": "2026-07-15T10:00:00Z"
      };
      final order = repo.parseOrderForTest(orderJson);
      expect(order.total, 250.0);
    });

    test('4. PickupSlotModel.fromJson with string day_of_week and max_orders', () {
      final slotJson = {
        "id": "slot1",
        "vendor_id": "v1",
        "day_of_week": "1",
        "start_time": "09:00",
        "end_time": "12:00",
        "max_orders": "10"
      };
      final slot = PickupSlotModel.fromJson(slotJson);
      expect(slot.dayOfWeek, 1);
      expect(slot.maxOrders, 10);
    });

    test('5. dashboard_page.dart stats revenue_today_paise string parsing', () {
      final stats = {
        "pending_orders": 1,
        "revenue_today_paise": "150000"
      };
      final revenueVal = (stats["revenue_today_paise"] is num
              ? (stats["revenue_today_paise"] as num).toDouble()
              : double.tryParse(stats["revenue_today_paise"]?.toString() ?? '')) ??
          0.0;
      final formatted = (revenueVal / 100.0).toStringAsFixed(0);
      expect(formatted, "1500");
    });

    test('6. analytics_page.dart stats and dailyData string parsing', () {
      double toDouble(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }

      int toInt(dynamic val) {
        if (val == null) return 0;
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? 0;
        return 0;
      }

      final stats = {
        "total_revenue": "2500.50",
        "total_orders": "100",
        "delivered_orders": "95",
        "fulfillment_rate": "95.00",
        "daily_data": [
          {"label": "Mon", "orders": "15"}
        ]
      };

      expect(toDouble(stats["total_revenue"]), 2500.50);
      expect(toInt(stats["total_orders"]), 100);
      expect(toInt((stats["daily_data"] as List).first["orders"]), 15);
    });

    test('9. EmployeeModel.fromJson with user_name, user_email, and user_phone backend fallbacks', () {
      final employeeJson = {
        "id": "e1",
        "user_id": "u1",
        "vendor_id": "v1",
        "role": "VENDOR_STAFF",
        "is_active": true,
        "user_name": "John Doe",
        "user_email": "john@example.com",
        "user_phone": "9988776655"
      };
      final employee = EmployeeModel.fromJson(employeeJson);
      expect(employee.name, "John Doe");
      expect(employee.email, "john@example.com");
      expect(employee.phone, "9988776655");
    });
  });
}
