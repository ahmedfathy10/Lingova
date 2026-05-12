import '../../domain/entities/book.dart';

class BookLocalDataSource {
  Future<List<Book>> getBooks() async => const [];

  Future<Book?> getBookById(String id) async => null;
}