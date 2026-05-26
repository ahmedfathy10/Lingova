import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_api_datasource.dart';
import '../datasources/book_local_datasource.dart';

class BookRepositoryImpl implements BookRepository {
  final BookApiDataSource apiDataSource;
  final BookLocalDataSource localDataSource;

  BookRepositoryImpl(this.apiDataSource, this.localDataSource);

  @override
  Future<List<Book>> getBooks() async {
    try {
      return await apiDataSource.getBooks();
    } catch (e) {
      return await localDataSource.getBooks();
    }
  }

  @override
  Future<Book?> getBookById(String id) async {
    try {
      return await apiDataSource.getBookById(id);
    } catch (e) {
      return await localDataSource.getBookById(id);
    }
  }
}
