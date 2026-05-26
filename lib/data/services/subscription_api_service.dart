import '../../core/api_config.dart';
import '../../domain/entities/course.dart';
import '../models/auth_user.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class SubscriptionApiService {
  Future<void> createRequest({
    required AuthUser user,
    required Course course,
  }) async {
    final response =
        await postJson(Uri.parse('${ApiConfig.baseUrl}/api/subscriptions'), {
          'studentId': user.id,
          'courseTitle': course.title,
          'courseLanguage': course.language,
          'courseLevel': course.level,
          'coursePrice': course.price,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw AuthApiException('تعذر إرسال طلب الاشتراك.');
  }
}
