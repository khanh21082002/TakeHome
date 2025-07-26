import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> solveMath(dynamic fileOrImage) async {
    // Placeholder: implement file upload
    final response = await http.post(Uri.parse('$baseUrl/solve'));
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    return json.decode(response.body)['history'];
  }
} 