import 'dart:convert';
import 'package:flutter/services.dart';

class JsonLoader {
  static Future<List<dynamic>> loadJsonData(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      throw Exception('Failed to load JSON data from $assetPath: $e');
    }
  }
}
