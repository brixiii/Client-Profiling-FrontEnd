import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/availed_service.dart';
import '../models/csr_guide_content.dart';
import '../models/csr_guide_section.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../../features/product_model/models/product_model.dart';
import '../../features/serial_number/models/serial_number_model.dart';
import '../../features/service_type/models/service_type_model.dart';
import '../../features/spare_parts/models/spare_part_model.dart';
import '../models/reseller.dart';
import '../models/reseller_product.dart';
import '../models/shop.dart';
import '../models/shop_product.dart';
import '../models/user.dart';
import 'api_exception.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'paginated_response.dart';
import 'token_storage.dart';

class BackendApi {
  BackendApi({ApiService? apiService, TokenStorage? tokenStorage})
      : _api = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiService _api;
  final TokenStorage _tokenStorage;

  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _api.post(
      '/login',
      requiresAuth: false,
      body: {
        'login': identifier,
        'password': password,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid login response.');
    }

    final token = (result['token'] ?? result['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException(
          statusCode: 500, message: 'Login token was not returned.');
    }

    await _tokenStorage.saveToken(token);

    final userJson = result['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['user'])
        : result['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(result['data'])
            : <String, dynamic>{};

    return User.fromJson(userJson);
  }

  Future<User> profile() async {
    final result = await _api.get('/profile');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid profile response.');
    }

    // /profile wraps the user in a 'user' key; fall back to 'data' or root.
    final data = result['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['user'])
        : result['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(result['data'])
            : Map<String, dynamic>.from(result);

    debugPrint('[profile()] data keys: ${data.keys.toList()}');
    debugPrint('[profile()] data[profile_photo_url]: ${data["profile_photo_url"]}');
    return User.fromJson(data);
  }

  Future<User> updateProfile({
    required String address,
    required String phone,
    required String email,
  }) async {
    final result = await _api.put('/profile', body: {
      'address': address,
      'phonenum': phone,
      'email': email,
    });
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid profile update response.');
    }
    final data = result['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['user'])
        : result['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(result['data'])
            : Map<String, dynamic>.from(result);
    return User.fromJson(data);
  }

  /// Uploads a profile photo via multipart/form-data (mobile — uses file path).
  /// Returns the new absolute [profile_photo_url] on success.
  Future<String?> uploadProfilePhoto(String filePath) async {
    final token = await _tokenStorage.getToken();
    final uri = Uri.parse('${ApiConfig.baseApiUrl}/profile/photo');
    debugPrint('[uploadProfilePhoto] file: $filePath');
    debugPrint('[uploadProfilePhoto] POST $uri');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${token ?? ''}'
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('profile_photo', filePath));
    return _sendPhotoRequest(request);
  }

  /// Uploads a profile photo via multipart/form-data (web — uses raw bytes).
  /// Returns the new absolute [profile_photo_url] on success.
  Future<String?> uploadProfilePhotoBytes(
      List<int> bytes, String filename) async {
    final token = await _tokenStorage.getToken();
    final uri = Uri.parse('${ApiConfig.baseApiUrl}/profile/photo');
    debugPrint('[uploadProfilePhoto] web bytes upload, filename: $filename');
    debugPrint('[uploadProfilePhoto] POST $uri');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${token ?? ''}'
      ..headers['Accept'] = 'application/json'
      ..files.add(http.MultipartFile.fromBytes(
        'profile_photo',
        bytes,
        filename: filename,
      ));
    return _sendPhotoRequest(request);
  }

  Future<String?> _sendPhotoRequest(http.MultipartRequest request) async {
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    debugPrint('[uploadProfilePhoto] status: ${response.statusCode}');
    debugPrint('[uploadProfilePhoto] body: ${response.body}');
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final url = decoded['profile_photo_url']?.toString() ?? '';
      return url.isNotEmpty ? url : null;
    }
    throw ApiException.fromResponse(
        statusCode: response.statusCode, decodedBody: decoded);
  }

  /// Returns aggregate counts from the backend cache-optimised summary endpoint.
  Future<Map<String, int>> getDashboardSummary() async {
    final result = await _api.get('/dashboard/summary');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid dashboard summary response.');
    }
    return {
      'total_clients': (result['total_clients'] as num?)?.toInt() ?? 0,
      'total_sold_products': (result['total_sold_products'] as num?)?.toInt() ?? 0,
      'total_services': (result['total_services'] as num?)?.toInt() ?? 0,
      'total_shops': (result['total_shops'] as num?)?.toInt() ?? 0,
    };
  }

  /// GET /dashboard/sold-products-monthly?year=YYYY
  /// Returns a list of 12 integers (Jan–Dec monthly sold product counts).
  Future<List<int>> getSoldProductsMonthly({int? year}) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    final result = await _api.get('/dashboard/sold-products-monthly', query: query);
    if (result is List) {
      return result.map<int>((e) => (e as num).toInt()).toList();
    }
    if (result is Map<String, dynamic> && result['data'] is List) {
      return (result['data'] as List)
          .map<int>((e) => (e as num).toInt())
          .toList();
    }
    throw ApiException(statusCode: 500, message: 'Invalid sold-products-monthly response.');
  }

  /// GET /dashboard/services-breakdown
  /// Returns a map of service category → count.
  /// Example: { "Repair": 42, "Maintenance": 18, ... }
  Future<Map<String, int>> getServicesBreakdown() async {
    final result = await _api.get('/dashboard/services-breakdown');
    if (result is Map<String, dynamic>) {
      return result.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    if (result is Map<String, dynamic> && result['data'] is Map) {
      return (result['data'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    throw ApiException(statusCode: 500, message: 'Invalid services-breakdown response.');
  }

  /// GET /dashboard/top-products?limit=5
  /// Returns a list of maps: [{ "name": "...", "count": 42 }, ...]
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final result = await _api.get('/dashboard/top-products', query: {'limit': limit});
    List<dynamic> list;
    if (result is List) {
      list = result;
    } else if (result is Map<String, dynamic> && result['data'] is List) {
      list = result['data'] as List;
    } else {
      throw ApiException(statusCode: 500, message: 'Invalid top-products response.');
    }
    return list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      // SUM() can return a String in some DB drivers – normalise to int
      final raw = m['count'];
      if (raw is String) m['count'] = int.tryParse(raw) ?? 0;
      return m;
    }).toList();
  }

  /// GET /dashboard/client-growth-monthly?year=YYYY
  /// Returns a list of 12 integers (Jan–Dec new-client counts).
  Future<List<int>> getClientGrowthMonthly({int? year}) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    final result = await _api.get('/dashboard/client-growth-monthly', query: query);
    if (result is List) {
      return result.map<int>((e) => (e as num).toInt()).toList();
    }
    if (result is Map<String, dynamic> && result['data'] is List) {
      return (result['data'] as List)
          .map<int>((e) => (e as num).toInt())
          .toList();
    }
    throw ApiException(statusCode: 500, message: 'Invalid client-growth-monthly response.');
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  /// Sends a 6-digit OTP to [email] via POST /api/forgot-password.
  /// Always succeeds (200) for any valid email format — backend is intentionally
  /// ambiguous for security.  Throws [ApiException] on 422 / network errors.
  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/forgot-password',
      requiresAuth: false,
      body: {'email': email},
    );
  }

  /// Verifies that [token] is a valid OTP for [email] without resetting the
  /// password. Calls POST /api/reset-password with intentionally empty
  /// passwords so the backend responds with either a token error (wrong/expired
  /// OTP → rethrows [ApiException]) or a password-validation error (token is
  /// good → returns normally so the caller can proceed).
  Future<void> verifyOtpToken({
    required String email,
    required String token,
  }) async {
    try {
      await _api.post(
        '/reset-password',
        requiresAuth: false,
        body: {
          'email': email,
          'token': token,
          'password': '',
          'password_confirmation': '',
        },
      );
      // 200 with empty password → token accepted (edge case); treat as valid.
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      final isTokenError = msg.contains('invalid') ||
          msg.contains('expired') ||
          e.fieldErrors.containsKey('token');
      if (isTokenError) rethrow; // bad token → surface the error
      // Password-validation errors (required, min length, etc.) mean the token
      // itself is fine — swallow and return normally.
    }
  }

  /// Resets the password via POST /api/reset-password.
  /// [token] is the 6-digit OTP the user received in email.
  /// Throws [ApiException] with the backend's message on failure (e.g.
  /// "Invalid code", "Expired code", or Laravel validation errors).
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.post(
      '/reset-password',
      requiresAuth: false,
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<PaginatedResponse<User>> getUsers({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/users', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });

    return _parsePage<User>(result, User.fromJson);
  }

  Future<User> getUserById(int id) async {
    final result = await _api.get('/users/$id');
    final map = _unwrapSingle(result);
    return User.fromJson(map);
  }

  Future<PaginatedResponse<Map<String, dynamic>>> getClients({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/clients', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });

    return _parsePage<Map<String, dynamic>>(
      result,
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> getClientById(int id) async {
    final result = await _api.get('/clients/$id');
    return _unwrapSingle(result);
  }

  Future<Map<String, dynamic>> createClient(
      Map<String, dynamic> payload) async {
    final result = await _api.post('/clients', body: payload);
    return _unwrapSingle(result);
  }

  Future<Map<String, dynamic>> updateClient({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/clients/$id', body: payload);
    return _unwrapSingle(result);
  }

  Future<void> deleteClient(int id) async {
    await _api.delete('/clients/$id');
  }

  Future<User> createUser(Map<String, dynamic> payload) async {
    final result = await _api.post('/users', body: payload);
    final map = _unwrapSingle(result);
    return User.fromJson(map);
  }

  Future<User> updateUser({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/users/$id', body: payload);
    final map = _unwrapSingle(result);
    return User.fromJson(map);
  }

  Future<void> deleteUser(int id) async {
    await _api.delete('/users/$id');
  }

  Future<PaginatedResponse<Employee>> getEmployees({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/employees', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });

    return _parsePage<Employee>(result, Employee.fromJson);
  }

  Future<Employee> createEmployee(Map<String, dynamic> payload) async {
    final result = await _api.post('/employees', body: payload);
    final map = _unwrapSingle(result);
    return Employee.fromJson(map);
  }

  Future<Employee> updateEmployee({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/employees/$id', body: payload);
    final map = _unwrapSingle(result);
    return Employee.fromJson(map);
  }

  Future<void> deleteEmployee(int id) async {
    await _api.delete('/employees/$id');
  }

  Future<PaginatedResponse<Shop>> getShops({
    required int page,
    required int perPage,
    String? q,
    int? clientId,
  }) async {
    final result = await _api.get('/shops', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
      'client_id': clientId,
    });

    return _parsePage<Shop>(result, Shop.fromJson);
  }

  Future<Shop> getShopById(int id) async {
    final result = await _api.get('/shops/$id');
    final map = _unwrapSingle(result);
    return Shop.fromJson(map);
  }

  Future<Shop> updateShop({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/shops/$id', body: payload);
    final map = _unwrapSingle(result);
    return Shop.fromJson(map);
  }

  Future<Shop> createShop(Map<String, dynamic> payload) async {
    final result = await _api.post('/shops', body: payload);
    final map = _unwrapSingle(result);
    return Shop.fromJson(map);
  }

  Future<void> deleteShop(int id) async {
    await _api.delete('/shops/$id');
  }

  /// Calls POST /geocode-address and returns the parsed data map.
  /// Throws [ApiException] on failure or when the backend returns
  /// `{ "success": false }`.
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final result = await _api.post(
      '/geocode-address',
      body: {'address': address},
    );

    if (result is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Invalid geocode response.');
    }

    if (result['success'] != true) {
      final msg = (result['message'] ?? 'Unable to geocode the provided address.')
          .toString();
      throw ApiException(statusCode: 422, message: msg);
    }

    final data = result['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Missing geocode data.');
    }

    return Map<String, dynamic>.from(data);
  }

  /// Calls POST /reverse-geocode and returns the parsed data map.
  /// Throws [ApiException] on failure or when the backend returns
  /// `{ "success": false }`.
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _api.post(
      '/reverse-geocode',
      body: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    if (result is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Invalid reverse geocode response.');
    }

    if (result['success'] != true) {
      final msg = (result['message'] ??
              'Unable to reverse geocode the provided coordinates.')
          .toString();
      throw ApiException(statusCode: 422, message: msg);
    }

    final data = result['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Missing reverse geocode data.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<PaginatedResponse<Product>> getProducts({
    required int page,
    required int perPage,
    String? q,
    int? clientId,
  }) async {
    final result = await _api.get('/products', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
      'client_id': clientId,
    });

    return _parsePage<Product>(result, Product.fromJson);
  }

  Future<PaginatedResponse<Map<String, dynamic>>> getApplianceModels({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/appliance-models', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });

    return _parsePage<Map<String, dynamic>>(
      result,
      (json) => json,
    );
  }

  Future<Product> getProductById(int id) async {
    final result = await _api.get('/products/$id');
    final map = _unwrapSingle(result);
    return Product.fromJson(map);
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final result = await _api.post('/products', body: payload);
    final map = _unwrapSingle(result);
    return Product.fromJson(map);
  }

  Future<PaginatedResponse<ShopProduct>> getShopProducts({
    required int page,
    required int perPage,
    int? shopId,
    int? clientId,
    String? q,
  }) async {
    final result = await _api.get('/shop-products', query: {
      'page': page,
      'per_page': perPage,
      'shop_id': shopId,
      'client_id': clientId,
      'q': q,
    });

    return _parsePage<ShopProduct>(result, ShopProduct.fromJson);
  }

  Future<ShopProduct> getShopProductById(int id) async {
    final result = await _api.get('/shop-products/$id');
    final map = _unwrapSingle(result);
    return ShopProduct.fromJson(map);
  }

  Future<ShopProduct> createShopProduct(Map<String, dynamic> payload) async {
    final result = await _api.post('/shop-products', body: payload);
    final map = _unwrapSingle(result);
    return ShopProduct.fromJson(map);
  }

  Future<Product> updateProduct({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/products/$id', body: payload);
    final map = _unwrapSingle(result);
    return Product.fromJson(map);
  }

  Future<void> deleteProduct(int id) async {
    await _api.delete('/products/$id');
  }

  Future<PaginatedResponse<AvailedService>> getAvailedServices({
    required int page,
    required int perPage,
    String? q,
    int? clientId,
    int? shopId,
  }) async {
    final result = await _api.get('/availed-services', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
      'client_id': clientId,
      'shop_id': shopId,
    });

    return _parsePage<AvailedService>(result, AvailedService.fromJson);
  }

  Future<AvailedService> createAvailedService(
      Map<String, dynamic> payload) async {
    final result = await _api.post('/availed-services', body: payload);
    final map = _unwrapSingle(result);
    return AvailedService.fromJson(map);
  }

  /// Creates an availed service with the full contract payload.
  /// Uses multipart/form-data when a file is attached, JSON otherwise.
  /// Arrays are encoded as `field[0]`, `field[1]` … for Laravel compatibility.
  Future<AvailedService> createAvailedServiceFull({
    required String serviceOrderReportNo,
    required String serviceTypeId,
    required String serviceDate,
    String? notes,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    required List<int> serialNumberIds,
    required List<Map<String, int>> spareParts,
    required List<int> technicianIds,
    required int clientId,
    int? shopId,
  }) async {
    final hasFile = (fileBytes != null && fileBytes.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);

    if (hasFile) {
      final token = await _tokenStorage.getToken();
      final uri = Uri.parse('${ApiConfig.baseApiUrl}/availed-services');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${token ?? ''}'
        ..headers['Accept'] = 'application/json';

      request.fields['service_order_report_no'] = serviceOrderReportNo;
      request.fields['service_type_id'] = serviceTypeId;
      request.fields['service_date'] = serviceDate;
      request.fields['client_id'] = clientId.toString();
      if (shopId != null) request.fields['shop_id'] = shopId.toString();
      if (notes != null && notes.isNotEmpty) request.fields['notes'] = notes;

      for (var i = 0; i < serialNumberIds.length; i++) {
        request.fields['serial_number_ids[$i]'] =
            serialNumberIds[i].toString();
      }
      for (var i = 0; i < spareParts.length; i++) {
        request.fields['spare_parts[$i][spare_part_id]'] =
            spareParts[i]['spare_part_id'].toString();
        request.fields['spare_parts[$i][quantity]'] =
            spareParts[i]['quantity'].toString();
      }
      for (var i = 0; i < technicianIds.length; i++) {
        request.fields['technician_ids[$i]'] = technicianIds[i].toString();
      }

      // Prefer bytes (always safe cross-platform).
      // Fall back to path only on native platforms where path is available.
      if (fileBytes != null && fileBytes.isNotEmpty && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        ));
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath('attachment', filePath));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>;
        return AvailedService.fromJson(map);
      }
      throw ApiException.fromResponse(
          statusCode: response.statusCode, decodedBody: decoded);
    }

    // No file — JSON submission
    final payload = <String, dynamic>{
      'service_order_report_no': serviceOrderReportNo,
      'service_type_id': serviceTypeId,
      'service_date': serviceDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'client_id': clientId,
      if (shopId != null) 'shop_id': shopId,
      'serial_number_ids': serialNumberIds,
      'spare_parts': spareParts,
      'technician_ids': technicianIds,
    };
    final result = await _api.post('/availed-services', body: payload);
    return AvailedService.fromJson(_unwrapSingle(result));
  }

  Future<AvailedService> getAvailedServiceById(int id) async {
    final result = await _api.get('/availed-services/$id');
    final map = _unwrapSingle(result);
    return AvailedService.fromJson(map);
  }

  Future<AvailedService> updateAvailedService({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/availed-services/$id', body: payload);
    final map = _unwrapSingle(result);
    return AvailedService.fromJson(map);
  }

  Future<void> deleteAvailedService(int id) async {
    await _api.delete('/availed-services/$id');
  }

  // ── Service Types ────────────────────────────────────────────────
  Future<PaginatedResponse<ServiceTypeModel>> getServiceTypes({
    required int page,
    required int perPage,
  }) async {
    final result = await _api.get('/service-types', query: {
      'page': page,
      'per_page': perPage,
    });
    return _parsePage<ServiceTypeModel>(result, ServiceTypeModel.fromJson);
  }

  Future<ServiceTypeModel> getServiceTypeById(int id) async {
    final result = await _api.get('/service-types/$id');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid service type response.');
    }
    final data = result['data'] ?? result;
    return ServiceTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ServiceTypeModel> createServiceType({required String setypename}) async {
    final result = await _api.post('/service-types', body: {'setypename': setypename});
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid service type response.');
    }
    final data = result['data'] ?? result;
    return ServiceTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ServiceTypeModel> updateServiceType(int id, {required String setypename}) async {
    final result = await _api.put('/service-types/$id', body: {'setypename': setypename});
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid service type response.');
    }
    final data = result['data'] ?? result;
    return ServiceTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteServiceType(int id) async {
    await _api.delete('/service-types/$id');
  }

  // ── Spare Parts ──────────────────────────────────────────────────────────
  Future<PaginatedResponse<SparePartModel>> getSpareParts({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/spare-parts', query: {
      'page': page,
      'per_page': perPage,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return _parsePage<SparePartModel>(result, SparePartModel.fromJson);
  }

  /// Fetches all spare parts across all pages and returns the merged list.
  /// Deduplicates strictly by id (first occurrence wins) before returning.
  Future<List<SparePartModel>> fetchAllSpareParts() async {
    const perPage = 100;
    final first = await getSpareParts(page: 1, perPage: perPage);
    final all = List<SparePartModel>.from(first.data);
    for (int p = 2; p <= first.lastPage; p++) {
      final page = await getSpareParts(page: p, perPage: perPage);
      all.addAll(page.data);
    }
    // Deduplicate by id, preserving first-occurrence order.
    final seen = <int>{};
    return all.where((m) => seen.add(m.id)).toList();
  }

  Future<SparePartModel> getSparePartById(int id) async {
    final result = await _api.get('/spare-parts/$id');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid spare part response.');
    }
    final data = result['data'] ?? result;
    return SparePartModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SparePartModel> createSparePart(Map<String, dynamic> payload) async {
    final result = await _api.post('/spare-parts', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid spare part response.');
    }
    final data = result['data'] ?? result;
    return SparePartModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SparePartModel> updateSparePart(int id, Map<String, dynamic> payload) async {
    final result = await _api.put('/spare-parts/$id', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid spare part response.');
    }
    final data = result['data'] ?? result;
    return SparePartModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSparePart(int id) async {
    await _api.delete('/spare-parts/$id');
  }

  // ── Serial Numbers ───────────────────────────────────────────────────────
  Future<PaginatedResponse<SerialNumberModel>> getSerialNumbers({
    required int page,
    required int perPage,
    String? q,
    int? clientId,
    int? shopProductId,
  }) async {
    final result = await _api.get('/serial-numbers', query: {
      'page': page,
      'per_page': perPage,
      if (q != null && q.isNotEmpty) 'q': q,
      if (clientId != null) 'client_id': clientId,
      if (shopProductId != null) 'shop_product_id': shopProductId,
    });
    return _parsePage<SerialNumberModel>(result, SerialNumberModel.fromJson);
  }

  Future<SerialNumberModel> getSerialNumberById(int id) async {
    final result = await _api.get('/serial-numbers/$id');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid serial number response.');
    }
    final data = result['data'] ?? result;
    return SerialNumberModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SerialNumberModel> createSerialNumber(Map<String, dynamic> payload) async {
    final result = await _api.post('/serial-numbers', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid serial number response.');
    }
    final data = result['data'] ?? result;
    return SerialNumberModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SerialNumberModel> updateSerialNumber(int id, Map<String, dynamic> payload) async {
    final result = await _api.put('/serial-numbers/$id', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid serial number response.');
    }
    final data = result['data'] ?? result;
    return SerialNumberModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSerialNumber(int id) async {
    await _api.delete('/serial-numbers/$id');
  }

  // ── Resellers ───────────────────────────────────────────────────────
  Future<PaginatedResponse<Reseller>> getResellers({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/resellers', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });
    return _parsePage<Reseller>(result, Reseller.fromJson);
  }

  Future<Reseller> getResellerById(int id) async {
    final result = await _api.get('/resellers/$id');
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid reseller response.');
    }
    return Reseller.fromJson(result);
  }

  Future<Reseller> createReseller(Map<String, dynamic> payload) async {
    final result = await _api.post('/resellers', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid create reseller response.');
    }
    return Reseller.fromJson(result);
  }

  Future<Reseller> updateReseller({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/resellers/$id', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid update reseller response.');
    }
    return Reseller.fromJson(result);
  }

  Future<void> deleteReseller(int id) async {
    await _api.delete('/resellers/$id');
  }

  Future<PaginatedResponse<Map<String, dynamic>>> getResellerProducts({
    required int page,
    required int perPage,
    String? q,
  }) async {
    final result = await _api.get('/reseller-products', query: {
      'page': page,
      'per_page': perPage,
      'q': q,
    });
    return _parsePage<Map<String, dynamic>>(result, (json) => json);
  }

  Future<ResellerProduct> createResellerProduct(Map<String, dynamic> payload) async {
    final result = await _api.post('/reseller-products', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid create reseller product response.');
    }
    final data = result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'])
        : result;
    return ResellerProduct.fromJson(data);
  }

  Future<ResellerProduct> updateResellerProduct({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/reseller-products/$id', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid update reseller product response.');
    }
    final data = result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'])
        : result;
    return ResellerProduct.fromJson(data);
  }

  Future<void> deleteResellerProduct(int id) async {
    await _api.delete('/reseller-products/$id');
  }

  Future<void> createResellerProductSerial({
    required int resellerProductId,
    required String serialNumber,
    required String supplierType,
  }) async {
    await _api.post('/reseller-product-serials', body: {
      'reseller_product_id': resellerProductId,
      'serialnumber': serialNumber,
      'supplier_type': supplierType,
    });
  }

  // ── Calendar Events ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEvents({
    int? month,
    int? year,
    String? status,
    String? clientName,
  }) async {
    final result = await _api.get('/events', query: {
      'month': month,
      'year': year,
      'status': status,
      'client_name': clientName,
    });
    if (result is! Map<String, dynamic>) return [];
    final raw = result['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createEvent(
      Map<String, dynamic> payload) async {
    final result = await _api.post('/events', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Invalid create event response.');
    }
    return result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'])
        : result;
  }

  Future<Map<String, dynamic>> updateEvent({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/events/$id', body: payload);
    if (result is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Invalid update event response.');
    }
    return result['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(result['data'])
        : result;
  }

  Future<void> deleteEvent(int id) async {
    await _api.delete('/events/$id');
  }

  Future<PaginatedResponse<Map<String, dynamic>>> getCalendarEmployees({
    required int page,
    required int perPage,
  }) async {
    final result = await _api.get('/employees', query: {
      'page': page,
      'per_page': perPage,
    });
    return _parsePage<Map<String, dynamic>>(result, (json) => json);
  }

  PaginatedResponse<T> _parsePage<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (raw is! Map<String, dynamic>) {
      throw ApiException(
          statusCode: 500, message: 'Invalid paginated response.');
    }

    return PaginatedResponse<T>.fromJson(raw, parser);
  }

  Map<String, dynamic> _unwrapSingle(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw ApiException(statusCode: 500, message: 'Invalid server response.');
    }

    if (raw['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw['data']);
    }

    return raw;
  }

  // ── Product Models ───────────────────────────────────────────────────────

  Future<PaginatedResponse<ProductModel>> getProductModels({
    required int page,
    required int perPage,
  }) async {
    final result = await _api.get('/product-models', query: {
      'page': page,
      'per_page': perPage,
    });
    return _parsePage<ProductModel>(result, ProductModel.fromJson);
  }

  Future<ProductModel> getProductModelById(int id) async {
    final result = await _api.get('/product-models/$id');
    return ProductModel.fromJson(_unwrapSingle(result));
  }

  Future<ProductModel> createProductModel({
    required String applianceType,
    required String modelname,
    required String modelCode,
    String status = 'Latest',
  }) async {
    final result = await _api.post('/product-models', body: {
      'appliance_type': applianceType,
      'modelname': modelname,
      'model_code': modelCode,
      'status': status,
    });
    return ProductModel.fromJson(_unwrapSingle(result));
  }

  Future<ProductModel> updateProductModel({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/product-models/$id', body: payload);
    return ProductModel.fromJson(_unwrapSingle(result));
  }

  Future<void> deleteProductModel(int id) async {
    await _api.delete('/product-models/$id');
  }

  // ── CSR Guide ─────────────────────────────────────────────────────────────

  Future<List<CsrGuideSection>> getCsrGuideSections() async {
    final result = await _api.get(
      '/csr-guide-sections',
      query: {'per_page': '200'},
    );
    // Handle plain array response (non-paginated)
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(CsrGuideSection.fromJson)
          .toList();
    }
    // Handle standard paginated response
    final page = _parsePage<CsrGuideSection>(result, CsrGuideSection.fromJson);
    return page.data;
  }

  Future<CsrGuideSection> createCsrGuideSection({
    required String title,
    required int order,
    int? parentId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'order': order,
      if (parentId != null) 'parent_id': parentId,
    };
    final result = await _api.post('/csr-guide-sections', body: body);
    return CsrGuideSection.fromJson(_unwrapSingle(result));
  }

  Future<CsrGuideSection> updateCsrGuideSection({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _api.put('/csr-guide-sections/$id', body: payload);
    return CsrGuideSection.fromJson(_unwrapSingle(result));
  }

  Future<void> deleteCsrGuideSection(int id) async {
    await _api.delete('/csr-guide-sections/$id');
  }

  Future<List<CsrGuideContent>> getContentsForSection(int sectionId) async {
    final result = await _api.get(
      '/csr-guide-contents',
      query: {'section_id': sectionId.toString(), 'per_page': '200'},
    );
    List<CsrGuideContent> all;
    if (result is List) {
      all = result
          .whereType<Map<String, dynamic>>()
          .map(CsrGuideContent.fromJson)
          .toList();
    } else {
      final page = _parsePage<CsrGuideContent>(result, CsrGuideContent.fromJson);
      all = page.data;
    }
    // Client-side guard: filter to only this section's rows in case the
    // backend does not implement ?section_id= filtering.
    return all.where((c) => c.sectionId == sectionId).toList();
  }

  Future<void> createCsrGuideContent({
    required int sectionId,
    required String content,
  }) async {
    await _api.post('/csr-guide-contents', body: {
      'section_id': sectionId,
      'content': content,
    });
  }

  Future<void> updateCsrGuideContent({
    required int id,
    required String content,
  }) async {
    await _api.put('/csr-guide-contents/$id', body: {'content': content});
  }

  Future<void> deleteCsrGuideContent(int id) async {
    await _api.delete('/csr-guide-contents/$id');
  }
}
