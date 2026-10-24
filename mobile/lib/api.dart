import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const receiptRequestTimeout = Duration(seconds: 150);

class FinanceApi {
  FinanceApi(this.client, {this.token, this.onUnauthorized});
  final http.Client client;
  final String? token;
  final void Function()? onUnauthorized;

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  void check(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) return;
    if (response.statusCode == 401) onUnauthorized?.call();
    String message = 'The server could not complete this request.';
    try {
      message =
          (jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>)['error']
              as String? ??
          message;
    } catch (_) {}
    throw ApiFailure(response.statusCode, message);
  }

  Future<dynamic> get(String path) async {
    final response = await client
        .get(Uri.parse('$apiBase$path'), headers: headers)
        .timeout(const Duration(seconds: 10));
    check(response, 200);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data, {
    int expectedStatus = 201,
  }) async {
    final response = await client
        .post(
          Uri.parse('$apiBase$path'),
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 10));
    check(response, expectedStatus);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> parseReceipt(Uint8List photo) async {
    final response = await client
        .post(
          Uri.parse('$apiBase/receipts/parse'),
          headers: {...headers, 'Content-Type': 'image/jpeg'},
          body: photo,
        )
        .timeout(receiptRequestTimeout);
    check(response, 200);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class ApiFailure implements Exception {
  ApiFailure(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}
