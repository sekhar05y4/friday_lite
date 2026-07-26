import '../interfaces/repositories/i_todo_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class TodoRepository implements ITodoRepository {
  TodoRepository._();

  static final TodoRepository instance = TodoRepository._();

  @override
  Future<List<Map<String, dynamic>>> getTodoItems() async {
    try {
      final db = await DatabaseService.instance.database;
      return await db.query('todo_items', orderBy: 'is_done ASC, created_at DESC');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'TodoRepository getTodoItems error: $e');
      return [];
    }
  }

  @override
  Future<int> addTodoItem(String task) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('todo_items', {
        'task': task,
        'is_done': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      FridayLogger.log(LogCategory.assistant, 'TodoRepository: added task #$id "$task"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'TodoRepository addTodoItem error: $e');
      return -1;
    }
  }

  @override
  Future<bool> toggleTodoDone(int id, bool isDone) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.update(
        'todo_items',
        {'is_done': isDone ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'TodoRepository toggleTodoDone error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteTodoItem(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('todo_items', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'TodoRepository deleteTodoItem error: $e');
      return false;
    }
  }
}
