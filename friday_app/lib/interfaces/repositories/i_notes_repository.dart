import '../../models/note.dart';

abstract class INotesRepository {
  Future<List<Note>> getRecentNotes({int limit = 20});
  Future<int> createNote(String title, String body);
  Future<bool> deleteNote(int id);
}
