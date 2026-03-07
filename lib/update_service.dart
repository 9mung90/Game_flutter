import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:forspeech/api_config.dart';
import 'package:forspeech/app_version_info.dart';

class UpdateService {
  static Future<AppVersionInfo?> fetchVersionInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/app/version'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AppVersionInfo.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}