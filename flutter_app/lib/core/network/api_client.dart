import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient instance = ApiClient();

  final Dio dio;
  String? _authToken;

  ApiClient({String? baseUrl, String? initialToken})
      : _authToken = initialToken,
        dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.defaultApiBaseUrl,
          connectTimeout: AppConfig.apiTimeout,
          receiveTimeout: AppConfig.apiTimeout,
          sendTimeout: AppConfig.apiTimeout,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        )) {
    _setupInterceptors();
  }

  String get baseUrl => dio.options.baseUrl;

  void setBaseUrl(String url) {
    dio.options.baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Retry logic on connection timeout or 503
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              (error.response != null && error.response!.statusCode == 503)) {
            final requestOptions = error.requestOptions;
            final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;
            if (retryCount < AppConfig.apiMaxRetries) {
              requestOptions.extra['retry_count'] = retryCount + 1;
              try {
                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              } catch (_) {
                // fall through
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
