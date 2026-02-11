import 'package:app_logging/app_logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ApiLoggingInterceptor interceptor;

  setUp(() {
    interceptor = ApiLoggingInterceptor();
  });

  group('ApiLoggingInterceptor', () {
    group('logRequest', () {
      test('logs basic GET request', () {
        expect(
          () => interceptor.logRequest(
            method: 'GET',
            url: 'https://api.example.com/data',
          ),
          returnsNormally,
        );
      });

      test('logs request with headers', () {
        expect(
          () => interceptor.logRequest(
            method: 'POST',
            url: 'https://api.example.com/data',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer token',
            },
          ),
          returnsNormally,
        );
      });

      test('logs request with body', () {
        expect(
          () => interceptor.logRequest(
            method: 'POST',
            url: 'https://api.example.com/data',
            body: {
              'key': 'value',
              'nested': {'a': 1},
            },
          ),
          returnsNormally,
        );
      });

      test('logs request with tag', () {
        expect(
          () => interceptor.logRequest(
            method: 'GET',
            url: 'https://api.example.com/data',
            tag: 'user-fetch',
          ),
          returnsNormally,
        );
      });

      test('logs request with all parameters', () {
        expect(
          () => interceptor.logRequest(
            method: 'PUT',
            url: 'https://api.example.com/users/1',
            headers: {'Content-Type': 'application/json'},
            body: {'name': 'test'},
            tag: 'user-update',
          ),
          returnsNormally,
        );
      });
    });

    group('logResponse', () {
      test('logs 200 success response', () {
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/data',
            statusCode: 200,
          ),
          returnsNormally,
        );
      });

      test('logs 201 created response', () {
        expect(
          () => interceptor.logResponse(
            method: 'POST',
            url: 'https://api.example.com/data',
            statusCode: 201,
            body: {'id': 1},
          ),
          returnsNormally,
        );
      });

      test('logs 301 redirect response', () {
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/old',
            statusCode: 301,
          ),
          returnsNormally,
        );
      });

      test('logs 400 client error response', () {
        expect(
          () => interceptor.logResponse(
            method: 'POST',
            url: 'https://api.example.com/data',
            statusCode: 400,
            body: {'error': 'Bad Request'},
          ),
          returnsNormally,
        );
      });

      test('logs 500 server error response', () {
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/data',
            statusCode: 500,
          ),
          returnsNormally,
        );
      });

      test('logs response with response time', () {
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/data',
            statusCode: 200,
            responseTimeMs: 150,
          ),
          returnsNormally,
        );
      });

      test('logs response with tag and headers', () {
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/data',
            statusCode: 200,
            tag: 'data-fetch',
            headers: {'X-Request-Id': '123'},
          ),
          returnsNormally,
        );
      });
    });

    group('logError', () {
      test('logs basic error', () {
        expect(
          () => interceptor.logError(
            method: 'GET',
            url: 'https://api.example.com/data',
            error: Exception('Network error'),
          ),
          returnsNormally,
        );
      });

      test('logs error with stack trace', () {
        expect(
          () => interceptor.logError(
            method: 'POST',
            url: 'https://api.example.com/data',
            error: 'Timeout',
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
      });

      test('logs error with request body and tag', () {
        expect(
          () => interceptor.logError(
            method: 'PUT',
            url: 'https://api.example.com/users/1',
            error: 'Connection refused',
            requestBody: {'name': 'test'},
            tag: 'user-update',
          ),
          returnsNormally,
        );
      });
    });

    group('logPerformance', () {
      test('logs normal performance (< 1000ms)', () {
        expect(
          () => interceptor.logPerformance(
            method: 'GET',
            url: 'https://api.example.com/data',
            durationMs: 200,
          ),
          returnsNormally,
        );
      });

      test('logs slow performance (1000-5000ms)', () {
        expect(
          () => interceptor.logPerformance(
            method: 'GET',
            url: 'https://api.example.com/data',
            durationMs: 3000,
          ),
          returnsNormally,
        );
      });

      test('logs very slow performance (> 5000ms)', () {
        expect(
          () => interceptor.logPerformance(
            method: 'GET',
            url: 'https://api.example.com/data',
            durationMs: 8000,
          ),
          returnsNormally,
        );
      });

      test('logs performance with tag', () {
        expect(
          () => interceptor.logPerformance(
            method: 'POST',
            url: 'https://api.example.com/data',
            durationMs: 500,
            tag: 'batch-upload',
          ),
          returnsNormally,
        );
      });
    });

    group('logConnectivity', () {
      test('logs connected state', () {
        expect(
          () => interceptor.logConnectivity(isConnected: true),
          returnsNormally,
        );
      });

      test('logs connected with network type', () {
        expect(
          () => interceptor.logConnectivity(
            isConnected: true,
            networkType: 'WiFi',
          ),
          returnsNormally,
        );
      });

      test('logs disconnected state', () {
        expect(
          () => interceptor.logConnectivity(isConnected: false),
          returnsNormally,
        );
      });
    });

    group('logRateLimit', () {
      test('logs rate limiting', () {
        expect(
          () => interceptor.logRateLimit(
            method: 'GET',
            url: 'https://api.example.com/data',
            retryAfter: 30,
          ),
          returnsNormally,
        );
      });
    });

    group('logAuth', () {
      test('logs successful auth', () {
        expect(
          () => interceptor.logAuth(action: 'login', success: true),
          returnsNormally,
        );
      });

      test('logs successful auth with userId', () {
        expect(
          () => interceptor.logAuth(
            action: 'login',
            success: true,
            userId: 'user123',
          ),
          returnsNormally,
        );
      });

      test('logs failed auth', () {
        expect(
          () => interceptor.logAuth(action: 'login', success: false),
          returnsNormally,
        );
      });

      test('logs failed auth with error', () {
        expect(
          () => interceptor.logAuth(
            action: 'login',
            success: false,
            error: 'Invalid credentials',
          ),
          returnsNormally,
        );
      });
    });

    group('logValidation', () {
      test('logs validation errors', () {
        expect(
          () => interceptor.logValidation(
            endpoint: '/users',
            data: {'email': 'invalid'},
            errors: ['Email format invalid', 'Name required'],
          ),
          returnsNormally,
        );
      });
    });

    group('body truncation', () {
      test('handles large request body by truncating', () {
        final largeBody = <String, dynamic>{'data': 'x' * 2000};
        expect(
          () => interceptor.logRequest(
            method: 'POST',
            url: 'https://api.example.com/data',
            body: largeBody,
          ),
          returnsNormally,
        );
      });

      test('handles large response body by truncating', () {
        final largeBody = <String, dynamic>{'data': 'y' * 2000};
        expect(
          () => interceptor.logResponse(
            method: 'GET',
            url: 'https://api.example.com/data',
            statusCode: 200,
            body: largeBody,
          ),
          returnsNormally,
        );
      });

      test('handles large error request body by truncating', () {
        final largeBody = <String, dynamic>{'data': 'z' * 2000};
        expect(
          () => interceptor.logError(
            method: 'POST',
            url: 'https://api.example.com/data',
            error: 'error',
            requestBody: largeBody,
          ),
          returnsNormally,
        );
      });
    });
  });
}
