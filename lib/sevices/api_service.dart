import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'https://lingova-production.up.railway.app';

  final Dio dio = Dio();

  Future<List<dynamic>> getCourses() async {
    try {
      final response = await dio.get(
        '$baseUrl/api/courses',
      );

      return response.data['courses'];
    } catch (e) {
      print(e);
      return [];
    }
  }
}