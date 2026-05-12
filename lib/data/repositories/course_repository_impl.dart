import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource localDataSource;

  CourseRepositoryImpl(this.localDataSource);

  @override
  List<Course> getEnglishCourses() {
    return localDataSource.getEnglishCourses();
  }

  @override
  List<Course> getGermanCourses() {
    return localDataSource.getGermanCourses();
  }
}
