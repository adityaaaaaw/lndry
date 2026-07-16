import '../../models/models.dart';
import '../../shared/repositories/base_repository.dart';

abstract interface class VendorRepository {
  Future<SendOtpResult> sendOtp(String phone);
  
  Future<VerifyOtpVendorResult> verifyOtp({
    required String phone,
    required String otp,
    String? challengeId,
    Map<String, dynamic>? device,
  });
  
  Future<TokenPair> refreshTokens();
  
  Future<void> logout();
  
  // -- Profile operations
  Future<VendorModel> getProfile();
  
  Future<VendorModel> updateProfile({
    required String name,
    required String email,
    String? description,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  });

  Future<VendorModel> toggleStoreOpen(bool isOpen);
  
  // -- Catalogue services
  Future<List<ServiceModel>> getMyServices();
  
  Future<ServiceModel> addService(ServiceModel service);
  
  Future<ServiceModel> updateService(ServiceModel service);
  
  Future<void> toggleServiceAvailability(String serviceId, bool isAvailable);

  Future<void> deleteService(String serviceId);

  Future<Map<String, dynamic>> getServiceDetails(String serviceId);

  Future<void> addGarmentRate(
    String serviceId, {
    String? garmentTypeId,
    String? garmentTypeName,
    required double rate,
    String? rateUnit,
  });

  Future<void> deleteGarmentRate(String serviceId, String garmentTypeId);
  
  // -- Orders operations
  Future<OrderModel> getOrder(String orderId);

  Future<PaginatedResponse<OrderModel>> getIncomingOrders({
    PaginationParams params,
    String? status,
  });
  
  Future<OrderModel> acceptOrder(String orderId);
  
  Future<OrderModel> rejectOrder(String orderId, {String? reason});
  
  Future<OrderModel> markOrderReady(String orderId);

  Future<OrderModel> updateProcessingStage(String orderId, String stage);

  Future<OrderModel> reconcileOrder(
    String orderId, {
    List<Map<String, dynamic>>? confirmedLines,
    double? confirmedWeightKg,
    String? adjustmentReason,
  });

  Future<Map<String, dynamic>> getDashboardStats();
  
  // -- Device tokens
  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
  });
  
  Future<void> unregisterDevice(String deviceId);

  // -- Employee staff management
  Future<List<EmployeeModel>> getEmployees();

  Future<EmployeeModel> createEmployee({
    required String name,
    required String email,
    required String role,
    String? phone,
    List<String>? permissions,
  });

  Future<EmployeeModel> updateEmployee(
    String id, {
    required String role,
    required List<String> permissions,
    required bool isActive,
  });

  Future<void> deleteEmployee(String id);

  Future<void> resetEmployeePassword(String id, String newPassword);

  // -- Capacity & Slots management
  Future<Map<String, dynamic>> getCapacity();

  Future<void> updateCapacityDailyLimit(int maxOrdersPerDay);

  Future<List<PickupSlotModel>> getPickupSlots();

  Future<PickupSlotModel> createPickupSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? maxOrders,
  });

  Future<PickupSlotModel> updatePickupSlot(
    String id, {
    int? maxOrders,
    bool? isActive,
  });

  Future<void> deletePickupSlot(String id);

  // -- Analytics
  /// Returns computed analytics summary for the given period ('week' or 'month').
  Future<Map<String, dynamic>> getAnalyticsSummary({String period = 'week'});

  // -- Working Hours
  Future<Map<int, Map<String, dynamic>>> getWorkingHours();
  Future<void> updateWorkingHours(int dayOfWeek, {required bool isOpen, required String openTime, required String closeTime});

  // -- Support Tickets
  Future<Map<String, dynamic>> createSupportTicket({
    required String title,
    required String description,
    required String category,
  });
  Future<List<Map<String, dynamic>>> getSupportTickets();
}

class SendOtpResult {
  const SendOtpResult({
    required this.challengeId,
    required this.expiresIn,
    this.devOtp,
  });

  final String challengeId;
  final int expiresIn;
  final String? devOtp;
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class VerifyOtpVendorResult {
  const VerifyOtpVendorResult({
    required this.accessToken,
    required this.refreshToken,
    required this.vendor,
    this.userPhone,
  });

  final String accessToken;
  final String refreshToken;
  final VendorModel vendor;
  final String? userPhone;
}
