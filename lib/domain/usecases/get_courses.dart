import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetCourses {
  final CourseRepository repository;

  GetCourses(this.repository);

  List<Course> getEnglishCourses() {
    return repository.getEnglishCourses();
  }

  List<Course> getGermanCourses() {
    return repository.getGermanCourses();
  }
}
