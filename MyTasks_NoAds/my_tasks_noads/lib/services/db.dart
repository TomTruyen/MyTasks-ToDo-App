import 'package:sqflite/sqflite.dart';

Future<Database> setupDatabase() async {
  try {
    String databasePath = await getDatabasesPath();
    String path = databasePath + 'simple_todo.db';

    // NOTE: Boolean is not available, so 0 = False, 1 = True
    Database db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE todos (id INTEGER PRIMARY KEY, title TEXT, completed INTEGER)',
        [],
      );
    });

    return db;
  } catch (e) {
    print("Setup Error: $e");
    return null;
  }
}

Future<List> getTodos(Database db) async {
  try {
    List<Map> todos = await db.rawQuery('SELECT * FROM todos');

    return todos;
  } catch (e) {
    print("Get Todos Error: $e");
    return null;
  }
}

Future addTodo(Database db, Map args) async {
  try {
    await db.rawInsert(
      'INSERT INTO todos (title, completed) VALUES (?, ?)',
      [args['title'], args['completed']],
    );

    return true;
  } catch (e) {
    print("Add Todo Error $e");
    return null;
  }
}

Future editTodo(Database db, Map args) async {
  try {
    await db.rawUpdate(
      'UPDATE todos SET title = ?, completed = ? WHERE id = ?',
      [args['title'], args['completed'], args['id']],
    );

    return true;
  } catch (e) {
    print("Edit Todo Error $e");
    return null;
  }
}

Future deleteTodo(Database db, Map args) async {
  try {
    await db.rawDelete(
      'DELETE FROM todos WHERE id = ?',
      [args['id']],
    );

    return true;
  } catch (e) {
    print("Delete Todo Error: $e");
    return null;
  }
}

Future toggleComplete(Database db, Map args) async {
  try {
    await db.rawUpdate(
      'UPDATE todos SET completed = ? WHERE id = ?',
      [args['completed'], args['id']],
    );

    return true;
  } catch (e) {
    print("Complete Todo Error: $e");
    return null;
  }
}
