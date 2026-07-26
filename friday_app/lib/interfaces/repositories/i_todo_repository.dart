abstract class ITodoRepository {
  Future<List<Map<String, dynamic>>> getTodoItems();
  Future<int> addTodoItem(String task);
  Future<bool> toggleTodoDone(int id, bool isDone);
  Future<bool> deleteTodoItem(int id);
}
