import '../../domain/entities/course.dart';

abstract class CourseRepository {
  List<Course> getEnglishCourses();
  List<Course> getGermanCourses();
}
