import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackRepository {
  FeedbackRepository({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<void> reportWrongTimes({
    required String mosqueId,
    String? date,
    String? lane,
  }) async {
    final uri = Uri.parse('${_baseUrl}api/report');
    await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mosqueId': mosqueId,
        if (date != null) 'date': date,
        if (lane != null) 'lane': lane,
      }),
    );
  }

  Future<PhotoSubmissionResult> submitPhoto({
    required String mosqueId,
    required String imageBase64,
    required String mediaType,
  }) async {
    final uri = Uri.parse('${_baseUrl}api/submit_photo');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mosqueId': mosqueId,
        'imageBase64': imageBase64,
        'mediaType': mediaType,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return PhotoSubmissionResult(
        success: true,
        status: body['status'] as String? ?? 'accepted',
        message: body['message'] as String?,
        days: body['days'] as int?,
      );
    }

    return PhotoSubmissionResult(
      success: false,
      status: 'error',
      message: body['error'] as String? ?? 'Unknown error (${response.statusCode})',
    );
  }
}

class PhotoSubmissionResult {
  const PhotoSubmissionResult({
    required this.success,
    required this.status,
    this.message,
    this.days,
  });

  final bool success;
  final String status;
  final String? message;
  final int? days;
}
