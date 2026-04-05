/// API Configuration
/// Centralized API endpoints and base URL configuration
class ApiConfig {
  // Base URL - Change this based on environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  
  static const String memberDashboard = '/members/dashboard';
  static const String memberMembership = '/members/membership';
  static const String memberBookings = '/members/bookings';
  static const String memberBookClass = '/members/book-class';
  static String memberCancelBooking(int bookingId) => '/members/bookings/$bookingId';
  static const String memberWorkouts = '/members/workouts';
  static const String memberProfile = '/members/profile';
  
  static const String adminUsers = '/admin/users';
  static String adminUser(int userId) => '/admin/users/$userId';
  static const String adminRevenue = '/admin/revenue';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminMemberships = '/admin/memberships';
  static const String adminEquipmentHealth = '/admin/equipment-health';
  
  static const String trainerClients = '/trainers/clients';
  static const String trainerPerformance = '/trainers/performance';
  static const String trainerSchedule = '/trainers/schedule';
  static const String trainerWorkoutPlans = '/trainers/workout-plans';
  static const String trainerNutritionPlans = '/trainers/nutrition-plans';
  
  static const String staffCheckin = '/staff/checkin';
  static const String staffCheckout = '/staff/checkout';
  static const String staffAttendanceToday = '/staff/attendance/today';
  static String staffLocker(int lockerId) => '/staff/lockers/$lockerId';
  static const String staffEquipment = '/staff/equipment';
  static String staffEquipmentUpdate(int equipmentId) => '/staff/equipment/$equipmentId';
  
  static const String classes = '/classes';
  static const String classSchedule = '/classes/schedule';
  static const String membershipTiers = '/membership-tiers';
  static const String trainers = '/trainers';
  
  static const String purchaseMembership = '/payments/purchase-membership';
  static const String paymentHistory = '/payments/history';
  
  
  /// Get full URL for an endpoint
  static String url(String endpoint) => '$baseUrl$endpoint';
  
  /// Get URL with query parameters
  static String urlWithParams(String endpoint, Map<String, dynamic> params) {
    final uri = Uri.parse('$baseUrl$endpoint');
    final newUri = uri.replace(queryParameters: params.map(
      (key, value) => MapEntry(key, value.toString()),
    ));
    return newUri.toString();
  }
}