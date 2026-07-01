import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/app_constant.dart';

class ApiClient {
  static void Function()? onUnauthorized;

  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConstant.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }
}
