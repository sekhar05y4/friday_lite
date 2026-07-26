import '../interfaces/repositories/i_notes_repository.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing SQLite persistence for personal notes.
class NotesRepository implements INotesRepository {
  NotesRepository._();

  static final NotesRepository instance = NotesRepository._();

  @override
  Future<List<Note>> getRecentNotes({int limit = 20}) async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'notes',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows.map((r) => Note.fromMap(r)).toList();
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'NotesRepository getRecentNotes error: $e');
      return [];
    }
  }

  @override
  Future<int> createNote(String title, String body) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('notes', {
        'title': title,
        'body': body,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      FridayLogger.log(LogCategory.assistant, 'NotesRepository: created note #$id "$title"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'NotesRepository createNote error: $e');
      return -1;
    }
  }

  @override
  Future<bool> deleteNote(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'NotesRepository deleteNote error: $e');
      return false;
    }
  }
}
